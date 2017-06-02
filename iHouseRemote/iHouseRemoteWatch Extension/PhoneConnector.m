//
//  PhoneConnector.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 07/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "PhoneConnector.h"

@implementation PhoneConnector

/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedPhoneConnector {
  static PhoneConnector *sharedPhoneConnector = nil;
  @synchronized(self) {
    if (sharedPhoneConnector == nil) {
      sharedPhoneConnector = [[self alloc] init];
    }
  }
  return sharedPhoneConnector;
}

- (instancetype)init {
  if (self = [super init]) {
    // Enable session with iphone
    if ([WCSession isSupported]) {
      WCSession *session = [WCSession defaultSession];
      session.delegate = self;
      [session activateSession];
      NSLog(@"WCSession is supported");
    }
  }
  return self;
}


- (void)sync {
  NSDictionary* message = @{KeyCommand:SyncCommand};
  [self packageAndSendMessage:message];
}

-(void)sendCommand:(NSString *)command forGroup:(Group *)group {
  [self packageAndSendMessage:@{KeyCommand : command, KeyGroup : group.name}];
}

-(void)sendCommand:(NSString *)command forDevice:(Device *)device {
  [self packageAndSendMessage:@{KeyCommand : command, KeyDevice : device.name}];
}

-(void)sendCommand:(NSString *)command forDevice:(Device *)device withInfo:(NSString *)info {
  [self packageAndSendMessage:@{KeyCommand : command, KeyDevice : device.name, KeyInfo : info}];
}


-(void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error {
  NSLog(@"activationDidCompleteWithState: %@", error);
}


/**
 Called when Phone uses sendMessge with Dictionary of values. Send back dictionary in replyHandler
 See phone counter-part for more help info
 */
- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler {
  if(message){
    NSString* command = [message objectForKey:KeyCommand];
    NSLog(@"command %@", command);
    if ([command isEqualToString:SyncCommand]) {
      NSDictionary* data = [message objectForKey:KeyData];
      NSLog(@"Data: %@", data);
      [self reconstructHouse:data];
    }
    //if (replyHandler != nil) replyHandler(response);
  }
}

-(void)reconstructHouse:(NSDictionary*) data {
  NSArray *rooms = [data objectForKey:KeyRooms];
  // Destroy the old house object
  [[House sharedHouse] destroy];
  House* house = [House sharedHouse];
  for (NSDictionary *room in rooms) {
    NSLog(@"Roomname: %@", [room objectForKey:KeyName]);
    Room *newRoom = [[Room alloc] init];
    if ([room objectForKey:KeyName]) newRoom.name = [room objectForKey:KeyName];
    for (NSDictionary *device in [room objectForKey:KeyDevices]) {
      Device *newDevice = [[Device alloc] init];
      if ([device objectForKey:KeyName]) newDevice.name = [device objectForKey:KeyName];
      if ([device objectForKey:KeyType]) newDevice.type = (DeviceType)([[device objectForKey:KeyType] integerValue]);
      NSLog(@"DeviceName: %@", newDevice.name );
      NSLog(@"DeviceType: %@", [newDevice DeviceTypeToString:newDevice.type]);
      [newRoom addDevice:newDevice];
    }
    [house addRoom:newRoom];
  }
  NSArray *groups = [data objectForKey:KeyGroups];
  for (NSDictionary *group in groups) {
    NSLog(@"GroupName: %@", [group objectForKey:KeyName]);
    Group *newGroup = [[Group alloc] init];
    if ([group objectForKey:KeyName]) newGroup.name = [group objectForKey:KeyName];
    [house addGroup:newGroup];
  }
  
  
  [[NSNotificationCenter defaultCenter] postNotificationName:NCSyncComplete object:nil];
  
}

/**
 Helper function - accept Dictionary of values to send them to its phone - using sendMessage - including reply from phone
 */
-(void)packageAndSendMessage:(NSDictionary*)request {
  if(WCSession.isSupported) {
    WCSession* session = WCSession.defaultSession;
    session.delegate = self;
    [session activateSession];
    
    if(session.reachable) {
      [session sendMessage:request
              replyHandler:
       ^(NSDictionary<NSString *,id> * __nonnull replyMessage) {
         dispatch_async(dispatch_get_main_queue(), ^{
           NSLog(@".....Watch replyHandler called --- %@",replyMessage);
           NSDictionary* message = replyMessage;
           NSString* response = message[@"response"];
           [[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeSuccess];
           if(response)
             NSLog(@"Response %@", response);
           else
             NSLog(@"NILL");
         });
       }
              errorHandler:^(NSError * __nonnull error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                  NSLog(@"error %@", error);
                });
              }
       ];
    } else {
      NSLog(@"Session Not reachable");
    }
  } else {
    NSLog(@"Session Not Supported");
  }
}

//Objective-C
-(void)session:(WCSession *)session didReceiveFile:(WCSessionFile *)file {
  NSData *imageData = [[NSData alloc] initWithContentsOfURL:file.fileURL];
  NSLog(@"Type: %@ Name: %@", [[file metadata] objectForKey:KeyType], [[file metadata] objectForKey:KeyName]);
  NSString *name = [[file metadata] objectForKey:KeyName];
  NSString *type = [[file metadata] objectForKey:KeyType];
  
  if ([type isEqualToString:KeyDevice]) {
    for (Room *room in [[House sharedHouse] roomList]) {
      for (Device *dev in [room deviceList]) {
        if ([dev.name isEqualToString:name]) {
          dev.image = [UIImage imageWithData:imageData];
          [[NSNotificationCenter defaultCenter] postNotificationName:NCNewDeviceImage object:nil];
        }
      }
    }
  } else if ([type isEqualToString:KeyRoom]) {
    for (Room *room in [[House sharedHouse] roomList]) {
      if ([room.name isEqualToString:name]) {
        room.image = [UIImage imageWithData:imageData];
        [[NSNotificationCenter defaultCenter] postNotificationName:NCNewRoomImage object:nil];
      }
    }
  } else if ([type isEqualToString:KeyGroup]) {
    for (Group *group in [[House sharedHouse] groupList]) {
      if ([group.name isEqualToString:name]) {
        group.image = [UIImage imageWithData:imageData];
        [[NSNotificationCenter defaultCenter] postNotificationName:NCNewGroupImage object:nil];
      }
    }
  } else if ([type isEqualToString:KeyDeviceInfo]) {
    for (Room *room in [[House sharedHouse] roomList]) {
      for (Device *dev in [room deviceList]) {
        if ([dev.name isEqualToString:name]) {
          NSLog(@"Info: %@", [[file metadata] objectForKey:KeyInfo]);
          UIImage *image = [UIImage imageWithData:imageData];
          NSString *commandName = [[file metadata] objectForKey:KeyInfo];
          if (dev.type == ir) {
            NSNumber *index = [NSNumber numberWithInteger:[[[file metadata] objectForKey:KeyIndex] integerValue]];
            NSDictionary* dict = @{KeyName: commandName, KeyImage: image, KeyIndex: index};
            // If infrared Key not
            if ([dev.info objectForKey:KeyIRCommands]) {
              [[dev.info objectForKey:KeyIRCommands] addObject:dict];
            } else {
              NSMutableArray *irCommands = [[NSMutableArray alloc] init];
              [irCommands addObject:dict];
              [dev.info addEntriesFromDictionary:@{KeyIRCommands: irCommands}];
              NSLog(@"Created IR Array: %@", [dev.info objectForKey:KeyIRCommands]);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:NCNewDeviceInfoImage object:nil];
          }
        }
      }
    }
  }
  
}


/**
 Standard WatchKit delegate
 */
-(void)sessionWatchStateDidChange:(nonnull WCSession *)session {
  if(WCSession.isSupported){
    WCSession* session = WCSession.defaultSession;
    session.delegate = self;
    [session activateSession];
    NSLog(@"session.supported");
  }
}
@end
