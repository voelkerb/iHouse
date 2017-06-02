//
//  AmbilightServiceSearch.m
//  iHouse
//
//  Created by Benjamin Völker on 06.05.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "AmbilightService.h"


#define SERVICE_NAME @"_iPhoneSyncService._tcp."




@implementation AmbilightService
@synthesize currentColor, ambilight, fade, brightness;


/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedAmbilightService {
  static AmbilightService *sharedAmbilightService = nil;
  @synchronized(self) {
    if (sharedAmbilightService == nil) {
      sharedAmbilightService = [[self alloc] init];
    }
  }
  return sharedAmbilightService;
}

- (instancetype)init {
  if (self = [super init]) {
    addrAndPort = nil;
    browser = [[NSNetServiceBrowser alloc] init];
    services = [[NSMutableArray alloc] init];
    [browser setDelegate:self];
    [browser searchForServicesOfType:SERVICE_NAME inDomain:@""];
    NSLog(@"Search for service: %@", SERVICE_NAME);
    
    currentColor = [NSColor colorWithSRGBRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    
    ambilight = false;
    fade = false;
    brightness = 1.0;
    
    // Init tcp listeners
    tcpConnection = [[TCPClient alloc] init];
    
    
    __weak typeof(self) weakSelf = self;
    
    // Connection is established handling.
    tcpConnection.connectionOpenedBlock = ^(TCPClient* connection){
      NSLog(@"connected to ambilight server");
    };
    
    
    // Incoming massage handler.
    tcpConnection.messageReceivedBlock = ^(TCPClient* connection, NSString* message){
      //[weakSelf receivedCommand:message];
    };
    // Incoming data handler.
    tcpConnection.dataReceivedBlock = ^(TCPClient* connection, NSData* data){
      //[weakSelf receivedData:data];
    };
    // Incoming data handler.
    tcpConnection.dataReceivedProgressBlock = ^(TCPClient* connection, float progress){
      //if (DEBUG_SYNC) NSLog(@"Progress updated");
    };
    
    tcpConnection.connectionClosedBlock = ^(TCPClient* connection){
      NSLog(@"ambilight connection Closed");
    };
    
    
    tcpConnection.connectionOpenedBlock = ^(TCPClient* connection){
      NSLog(@"ambilight connection Opened");
    };

    
  }
  return self;
}

-(void)connectToServer:(NSString*)host withPort:(NSInteger)port {
  
  //int port = STANDARD_PORT;
  //NSString* host = settings.serverIP;
  NSLog(@"Connecting to ambilight TCP Server on host: %@ and port: %i.", host, (int)port);
  [tcpConnection setHostAndPort:host:(int)port];
  [tcpConnection connect];
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
    [self connectToServer:addrAndPort.address withPort:addrAndPort.port];
    //[[NSNotificationCenter defaultCenter] postNotificationName:StartAutoSync object:nil];
  }
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
  [services removeObject:aNetService];
}



#pragma mark Send over Bonjour

- (void)sendData {
  CGFloat red = [currentColor redComponent]*255.0f;
  CGFloat blue = [currentColor blueComponent]*255.0f;
  CGFloat green = [currentColor greenComponent]*255.0f;
  NSLog(@"Sending Color %f,%f,%f",red, green, blue);
  
  NSDictionary *dict = @{@"red" : [NSNumber numberWithInt:red] ,
                         @"green" : [NSNumber numberWithInt:green],
                         @"blue" : [NSNumber numberWithInt:blue],
                         @"capturing" : [NSNumber numberWithBool:ambilight],
                         @"brightness" : [NSNumber numberWithFloat:brightness],
                         @"fading" : [NSNumber numberWithBool:fade]};
  
  NSMutableData *data = [[NSMutableData alloc] init];
  NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
  [archiver encodeObject:dict forKey:@"livingHome"];
  [archiver finishEncoding];

  [tcpConnection performSelector:@selector(sendData:) withObject:data afterDelay:1];
  //[tcpConnection sendData:data];
  
  /*
  
  NSNetService *service = nil;
  if ([services count] > 0) {
    service = [services objectAtIndex:0];
  }
  NSData *appDataToSend = data;
  
  if(service) {
    NSOutputStream *outStream;
    [service getInputStream:nil outputStream:&outStream];
    [outStream open];
    long bytesToWrite = [outStream write:[appDataToSend bytes] maxLength: [appDataToSend length]];
    [outStream close];
    
    NSLog(@"Wrote %li bytes", bytesToWrite);
  }
  else NSLog(@"Select a Device");
  */
}



@end
