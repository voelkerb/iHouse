//
//  SyncManager.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 26/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "SyncManager.h"
#import "UIViewController+Utils.h"
#import "HouseSyncer.h"
#import "Constants.h"

#define DEBUG_SYNC 1
#define DEBUG_SERVER 1

//#define STANDARD_HOST @"192.168.0.13"
//#define STANDARD_HOST @"192.168.2.131"
#define STANDARD_HOST @"10.126.43.81"
#define STANDARD_PORT 2000

#define SERVICE_NAME @"_iHouseSyncService._tcp."

#define DISCOVER_COMMAND_RESPONSE @"iHouseRemote"
#define SYNC_COMMAND @"sync"
#define AUTOSYNC_COMMAND @"autoSync"

#define CONNECTION_ISSUE_MSG_1 @"Could not connect to the iHouse server application (host: "
#define CONNECTION_ISSUE_MSG_2 @").\nMake sure the application is up and running."
#define CONNECTION_ISSUE_TITLE @"Connection Problem"
#define CONNECTION_BROKE_ISSUE_TITLE @"Server Disconnected"
#define CONNECTION_BROKE_ISSUE_MSG @"The connection to the server was lost.\nTry to manually re-establish the connection."


@implementation SyncManager
@synthesize isConnected;
@synthesize progressValue;
@synthesize delegate;
@synthesize settings;


/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedSyncManager {
  static SyncManager *sharedSyncManager = nil;
  @synchronized(self) {
    if (sharedSyncManager == nil) {
      sharedSyncManager = [[self alloc] init];
    }
  }
  return sharedSyncManager;
}


- (instancetype)init {
  
  if (self = [super init]) {
    
    browser = [[NSNetServiceBrowser alloc] init];
    services = [[NSMutableArray alloc] init];
    [browser setDelegate:self];
    [browser searchForServicesOfType:SERVICE_NAME inDomain:@""];
    NSLog(@"Search for service: %@", SERVICE_NAME);
    
    
    isConnected = false;
    progressValue = 0.0f;
    
    // Init tcp listeners
    tcpConnection = [NetworkController sharedInstance];
    
    __weak typeof(self) weakSelf = self;
    
    // Connection is established handling.
    tcpConnection.connectionOpenedBlock = ^(NetworkController* connection){
      if (DEBUG_SYNC) NSLog(@"connected to server");
      isConnected = true;
    };
    
    
    // Incoming massage handler.
    tcpConnection.messageReceivedBlock = ^(NetworkController* connection, NSString* message){
      [weakSelf receivedCommand:message];
    };
    // Incoming data handler.
    tcpConnection.dataReceivedBlock = ^(NetworkController* connection, NSData* data){
      [weakSelf receivedData:data];
    };
    // Incoming data handler.
    tcpConnection.dataReceivedProgressBlock = ^(NetworkController* connection, float progress){
      //if (DEBUG_SYNC) NSLog(@"Progress updated");
      if (progress < 1.0f) {
        if (weakSelf.delegate) [weakSelf.delegate syncStatus:progress];
      }
    };
    
    tcpConnection.connectionClosedBlock = ^(NetworkController* connection){
      NSLog(@"Connection Closed");
      weakSelf.isConnected = false;
    };

    
    tcpConnection.connectionOpenedBlock = ^(NetworkController* connection){
      NSLog(@"Connection Opened");
      weakSelf.isConnected = true;
    };
    
    settings = [Settings sharedSettings];
    
  }
  
  return self;
}

-(void)disconnectFromServer {
  [self disableAlertSheets];
  [tcpConnection disconnect];
}

-(void)connectToServer{
  [tcpConnection connect];
  [tcpConnection sendMessage:DISCOVER_COMMAND_RESPONSE];
}

-(void)connectToServer:(NSString*)host withPort:(NSInteger)port {
  
  //int port = STANDARD_PORT;
  //NSString* host = settings.serverIP;
  if (DEBUG_SERVER) NSLog(@"Connecting to TCP Server on host: %@ and port: %i.", host, (int)port);
  [tcpConnection setHostAndPort:host:(int)port];
  [tcpConnection connect];
  [tcpConnection sendMessage:DISCOVER_COMMAND_RESPONSE];
}

-(void)syncNow {
  [self connectToServer:settings.serverIP withPort:STANDARD_PORT];
  // Need delay here, so that discover command and sync command is not mixed
  [self performSelector:@selector(sendSyncCommand) withObject:nil afterDelay:1];
  //[self sendSyncCommand];
  [[NSNotificationCenter defaultCenter] postNotificationName:StartAutoSync object:nil];
}

-(void)sendSyncCommand {
  if ([tcpConnection isOpen]) {
    if (DEBUG_SYNC) NSLog(@"Sending sync command");
    if (delegate) [delegate syncStatus:-1.0f];
    [tcpConnection sendMessage:SYNC_COMMAND];
    //connectProgress.hidden = false;
    //[self checkProgress];
  }
}

-(void)syncComplete {
  if (DEBUG_SYNC) NSLog(@"Sync completed, store in House object and inform delegate.");
  if (delegate) [delegate syncStatus:1.0f];
  // Store house object
  [[NSNotificationCenter defaultCenter] postNotificationName:SyncFinished object:nil];
}

-(void)sendCommand:(NSString *)command {
  if ([tcpConnection isOpen]) {
    if (DEBUG_SYNC) NSLog(@"Sending command: %@", command);
    [tcpConnection sendMessage:command];
    if (delegate) [delegate syncStatus:0.01f];
  }
}

- (void)receivedCommand:(NSString*)message {
  if (DEBUG_SYNC) NSLog(@"Command from Server: %@", message);
  if ([message containsString:@"?"]) {
    if (DEBUG_SYNC) NSLog(@"Discovery Command sent answer");
    if ([tcpConnection isOpen]) {
      [tcpConnection sendMessage:DISCOVER_COMMAND_RESPONSE ];
    }
  }
  if ([message containsString:AUTOSYNC_COMMAND]) {
    if (DEBUG_SYNC) NSLog(@"Autosync command");
    [self sendSyncCommand];
  }
}


- (void)receivedData:(NSData*)data {
  //if (DEBUG_TCP) NSLog(@"data from Server: %.2f kB", [data length]/1024.0f);
  if (DEBUG_SYNC) NSLog(@"data from Server: %li Bytes", [data length]);
  // Unarchive array
  NSMutableArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  //if (DEBUG_TCP) NSLog(@"data: %@", data);
  // If array contains information
  if (array) {
    NSNumber *number = [array firstObject];
    if (DEBUG_SYNC) NSLog(@"Data of format: %@", number);
    [array removeObjectAtIndex:0];
    
    // If value is 0, update all data in the house
    if ([number integerValue] == 0) {
      if (DEBUG_SYNC) NSLog(@"Unarchived data to object successfully");
      // Hand data over to houseSyncer
      [[HouseSyncer sharedHouseSyncer] handleSyncArray:array];
      // Get list of rooms and store devices
      NSMutableArray *theRoomList = [[NSMutableArray alloc] init];
      NSMutableArray *theDeviceList = [[NSMutableArray alloc] init];
      NSMutableArray *theGroupList = [[NSMutableArray alloc] init];
      NSMutableArray *theDeviceNameAndRoomList = [[NSMutableArray alloc] init];
      for (NSDictionary *theDeviceDict in array) {
        if ([theDeviceDict objectForKey:SyncKeyType]) {
          if ([[theDeviceDict objectForKey:SyncKeyType] integerValue] == SyncKeyRoomType) {
            [theRoomList addObject:theDeviceDict];
          } else if ([[theDeviceDict objectForKey:SyncKeyType] integerValue] == SyncKeyGroupType) {
            [theGroupList addObject:theDeviceDict];
          } else {
            [theDeviceList addObject:theDeviceDict];
            [theDeviceNameAndRoomList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                 [theDeviceDict objectForKey:SyncKeyRoom], SyncKeyRoom,
                                                 [theDeviceDict objectForKey:SyncKeyName], SyncKeyName,
                                                 nil]];
          }
        }
      }
      
      deviceList = [NSMutableArray arrayWithArray:theDeviceList];
      deviceNameAndRoomList = [NSArray arrayWithArray:theDeviceNameAndRoomList];
      roomList = [NSArray arrayWithArray:theRoomList];
      groupList = [NSArray arrayWithArray:theGroupList];
      
      
      if (DEBUG_SYNC) {
        NSLog(@"Devices: %@", deviceNameAndRoomList);
      }
      
    // if value is not 0, data contains only dict of one device
    } else {
      for (NSDictionary *deviceDict in array) {
        if (delegate) [delegate updateDeviceResponse:deviceDict];
      }
    }
    
    [self syncComplete];
  } else {
    if (DEBUG_SYNC) NSLog(@"Unarchived data to object failed");
  }
}



#pragma mark NSNetServiceBrowser delegates

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
  [services addObject:aNetService];
  aNetService.delegate = self;
  [aNetService resolveWithTimeout:10.0];
  NSLog(@"Found some Service");
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
  addrAndPort = sender.addressesAndPorts.firstObject;
  if (addrAndPort != nil) {
    NSLog(@"Found Service at Address: %@, Port: %i",addrAndPort.address, addrAndPort.port);

    // Leave standard port
    [self connectToServer:addrAndPort.address withPort:STANDARD_PORT];
    // Need delay here, so that discover command and sync command is not mixed
    //[self performSelector:@selector(sendSyncCommand) withObject:nil afterDelay:2];
    //[[NSNotificationCenter defaultCenter] postNotificationName:StartAutoSync object:nil];
  }
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
  [services removeObject:aNetService];
}


-(void)disableAlertSheets {
  // Connection is closed handling.
  tcpConnection.connectionClosedBlock = ^(NetworkController* connection){
    if (DEBUG_SYNC) NSLog(@"disconnected from server");
    isConnected = false;
  };
  // Connection is closed handling.
  tcpConnection.connectionFailedBlock = ^(NetworkController* connection){
    if (DEBUG_SYNC) NSLog(@"Connection failed");
    isConnected = false;
  };
}

-(void)enableAlertSheets {
  __weak typeof(self) weakSelf = self;
  
  // Connection is closed handling.
  tcpConnection.connectionClosedBlock = ^(NetworkController* connection){
    if (DEBUG_SYNC) NSLog(@"disconnected from server");
    [weakSelf connectionProblemAlertSheet:1];
    isConnected = false;
  };
  // Connection is closed handling.
  tcpConnection.connectionFailedBlock = ^(NetworkController* connection){
    if (DEBUG_SYNC) NSLog(@"Connection failed");
    [weakSelf connectionProblemAlertSheet:0];
    isConnected = false;
  };
}



#pragma mark AlertSheets

- (void)connectionProblemAlertSheet:(int)alertSheetType {
  switch (alertSheetType) {
    case 0: {
      NSString *msg = [NSString stringWithFormat:@"%@%@%@", CONNECTION_ISSUE_MSG_1, settings.serverIP, CONNECTION_ISSUE_MSG_2];
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:CONNECTION_ISSUE_TITLE
                                                                     message:msg
                                                              preferredStyle:UIAlertControllerStyleActionSheet];
      UIAlertAction *firstAction = [UIAlertAction actionWithTitle:@"Ok"
                                                            style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                              NSLog(@"You pressed button ok");
                                                            }];
      [alert addAction:firstAction];
      [[UIViewController currentViewController] presentViewController:alert animated:YES completion:nil];
      break;
    }
    case 1: {
      UIAlertController *alert = [UIAlertController alertControllerWithTitle:CONNECTION_BROKE_ISSUE_TITLE
                                                                     message:CONNECTION_BROKE_ISSUE_MSG
                                                              preferredStyle:UIAlertControllerStyleActionSheet];
      UIAlertAction *firstAction = [UIAlertAction actionWithTitle:@"Ok"
                                                            style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                              NSLog(@"You pressed button ok");
                                                            }];
      [alert addAction:firstAction];
      [[UIViewController currentViewController] presentViewController:alert animated:YES completion:nil];
      break;
    }
    default:
      break;
  }
}

@end
