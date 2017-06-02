//
//  WatchConnector.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 07/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "WatchConnector.h"
#import "House.h"
#import "Constants.h"
#import "HouseSyncer.h"

@implementation WatchConnector
/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedWatchConnector {
  static WatchConnector *sharedWatchConnector = nil;
  @synchronized(self) {
    if (sharedWatchConnector == nil) {
      sharedWatchConnector = [[self alloc] init];
    }
  }
  return sharedWatchConnector;
}

- (instancetype)init {
  if (self = [super init]) {
    // Enable session with iphone
    if ([WCSession isSupported]) {
      wcSession = [WCSession defaultSession];
      wcSession.delegate = self;
      [wcSession activateSession];
      NSLog(@"WCSession is supported");
    }
  }
  return self;
}


#pragma mark Watch Connection
/**
 Standard WatchKit delegate
 */
-(void)sessionWatchStateDidChange:(nonnull WCSession *)session {
  if(WCSession.isSupported){
    wcSession = WCSession.defaultSession;
    wcSession.delegate = self;
    [wcSession activateSession];
    if(wcSession.reachable){
      NSLog(@"session.reachable");
    }
    if(wcSession.paired){
      if(wcSession.isWatchAppInstalled){
        if(wcSession.watchDirectoryURL != nil){
          NSLog(@"session.allSupported");
        }
      }
    }
  }
}

-(void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(NSError *)error {
  NSLog(@"activationDidCompleteWithState: %@", error);
}

/**
 Uses given Dictionary to send and handle its reply and any errors.
 @param request message that is sent to the counterpart device - keyword, value.
 @return void
 */
-(void)packageAndSendMessage:(NSDictionary*)request {
  
  /*
   Before retrieving the default session object, call this method to verify that the current device supports watch connectivity.
   Session objects are always available on Apple Watch. They are also available on iPhones that support pairing with an Apple Watch.
   For all other devices, this method returns NO to indicate that you cannot use the classes and methods of this framework.
   */
  if(WCSession.isSupported) {
    wcSession = WCSession.defaultSession;
    wcSession.delegate = self;
    [wcSession activateSession];
    
    /*
     In your WatchKit extension, the value of this property is YES when a matching session is active
     on the user’s iPhone and the device is within range so that communication may occur. On iOS, the value
     is YES when the paired Apple Watch is in range and the associated Watch app is running in the FOREGROUND.
     In all other cases, the value is NO.
     The counterpart must be reachable in order for you to send messages using the sendMessage:replyHandler:errorHandler:
     and sendMessageData:replyHandler:errorHandler: methods. Sending messages to a counterpart that is not reachable results in an error.
     The session must be configured and activated before accessing this property.
     */
    if(wcSession.reachable) {
      /*
       Use this message to send a dictionary of data to the counterpart as soon as possible.
       Messages are queued serially and delivered in the order in which you sent them.
       Delivery of the messages happens asynchronously, so this method returns immediately.
       If you specify a reply handler block, your handler block is executed asynchronously on a background thread.
       The block is executed serially with respect to other incoming delegate messages.
       Calling this method from your WatchKit extension while it is active and running
       wakes up the corresponding iOS app in the background and makes it reachable.
       Calling this method from your iOS app does NOT wake up the corresponding WatchKit extension.
       If you call this method and the counterpart is unreachable
       (or becomes unreachable before the message is delivered), the errorHandler block is executed with
       an appropriate error. The errorHandler block may also be called if the message parameter
       contains non property list data types.
       */
      [wcSession sendMessage:request replyHandler: ^(NSDictionary<NSString *,id> * __nonnull replyMessage){
        // Go into main thread here
        dispatch_async(dispatch_get_main_queue(), ^{
          NSLog(@".....iPhone replyHandler called --- %@", replyMessage);
          NSDictionary* message = replyMessage;
          NSString* response = message[@"response"];
          if(response)
            NSLog(@"Sent Response to Watch: %@", response);
          else
            NSLog(@"No Response for watch");
        });
      }
                errorHandler:^(NSError * __nonnull error) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Error: %@",error.localizedDescription);
                  });
                }
       ];
      
      // Session is not reachable
    } else {
      NSLog(@"Session Not reachable");
    }
  } else {
    NSLog(@"Session Not Supported");
  }
}

-(void)checkSyncAndInformWatch {
  if ([[SyncManager sharedSyncManager] isSynced]) {
    [self sendSync];
  } else {
    [self performSelector:@selector(checkSyncAndInformWatch) withObject:nil afterDelay:2];
  }
}

/*
 This method is called in response to a message sent by the counterpart process
 using the sendMessage:replyHandler:errorHandler: method. This specific method is called
 when the counterpart specifies a valid reply handler, indicating that it wants a response.
 Use this method to process the message data and provide an appropriate reply.
 You must execute the reply block as part of your implementation.
 Use messages to communicate quickly with the counterpart process.
 Messages can be sent and received only while both processes are active and running.
 The delivery of multiple messages occurs serially, so your implementation of this method does not need to be reentrant.
 This method is called on a background thread of your app.
 */
- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler {
  NSLog(@"didReceiveMessage with replyHandler");
  if(message){
    NSString* command = [message objectForKey:KeyCommand];
    NSLog(@"message: %@", command);
    
    if ([command isEqualToString:SyncCommand]) {
      if ([[HouseSyncer sharedHouseSyncer] isSynced]){
        [self sendSync];
      } else {
        [[SyncManager sharedSyncManager] syncNow];
      }
    } else if ([command isEqualToString:ToggleCommand] || [command isEqualToString:IRToggleCommand]) {
      if ([[SyncManager sharedSyncManager] isConnected] == false) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
          
          [[SyncManager sharedSyncManager] connectToServer];
          
          
          // Leave some delay such that it could connect properly
          NSLog(@"Trying to toggle after a connection");
          
          NSTimer* t = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self  selector:@selector(handleTimer:) userInfo:message repeats:NO];
          
          [[NSRunLoop currentRunLoop] addTimer:t forMode:NSDefaultRunLoopMode];
          [[NSRunLoop currentRunLoop] run];
        });
      } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
          [self handleMessage:message];
        });
      }
    }
  }
}

- (void)handleTimer:(NSTimer*)theTimer {
  
  if ([[SyncManager sharedSyncManager] isConnected] == false) {
    [[NSRunLoop currentRunLoop] addTimer:theTimer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] run];
  } else {
    [self handleMessage:[theTimer userInfo]];
  }
}

- (void)handleMessage:(NSDictionary<NSString *, id> *)message {
  NSString* command = [message objectForKey:KeyCommand];
  // Get which device to toggle
  if ([message objectForKey:KeyDevice]) {
    Device* device = [[House sharedHouse] getDeviceNamed:[message objectForKey:KeyDevice]];
    if (device == nil) {
      NSLog(@"Error device not found");
      return;
    }
      
    if ([command isEqualToString:ToggleCommand]) {
      NSLog(@"Should toggle device: %@", device);
      // Try to get current light state in order to send correct command
      NSMutableDictionary *deviceInfo = [[NSMutableDictionary alloc] initWithDictionary:device.info];
      BOOL state = false;
      if ([deviceInfo objectForKey:SocketLightKeyState]) {
        state = [[deviceInfo objectForKey:SocketLightKeyState] boolValue];
      }
      NSLog(@"Current Light state: %i, need to toggle.", state);
      state = !state;
      // Store new state and toggle device
      [deviceInfo setObject:[NSNumber numberWithBool:state] forKey:SocketLightKeyState];
      NSLog(@"Stored %i", state);
      device.info = deviceInfo;
      [[HouseSyncer sharedHouseSyncer] sendAction:SwitchCommand withValue:state forDevice:device];
    } else if ([command isEqualToString:IRToggleCommand]) {
      NSString* info = [message objectForKey:KeyInfo];
      NSLog(@"Should toggle %@ of device: %@", info, device);
      [[HouseSyncer sharedHouseSyncer] sendAction:[NSString stringWithFormat:@"%@%@", IRToggleAction, info] withValue:0 forDevice:device];
    }
  } else if ([message objectForKey:KeyGroup]) {
    Group* group = nil;
    for (Group* theGroup in [[House sharedHouse] groupList]) {
      if ([theGroup.name isEqualToString:[message objectForKey:KeyGroup]]) group = theGroup;
    }
    if (group == nil) {
      NSLog(@"Error group not found");
      return;
    }
    if ([command isEqualToString:ToggleCommand]) {
      NSLog(@"Should toggle group: %@", group);
      [[HouseSyncer sharedHouseSyncer] sendGroup:group];
    }
  }
}

-(void)sendSync {
  NSLog(@"Start Syncing House to watch");
  House *house = [House sharedHouse];
  CGSize picSize = CGSizeMake(50, 50);
  
  // Construct all rooms
  NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] init];
  NSMutableArray *rooms = [[NSMutableArray alloc] init];
  for (Room *theRoom in [house roomList]) {
    
    NSMutableArray *devices = [[NSMutableArray alloc] init];
    for (Device *theDevice in theRoom.deviceList) {
      NSDictionary *singleDevice = @{ KeyName : theDevice.name,
                                      KeyType : [NSNumber numberWithInteger:theDevice.type]};
      [devices addObject:singleDevice];
    }
    
    NSDictionary *singleRoom = @{ KeyName : theRoom.name,
                                  KeyDevices : devices};
    [rooms addObject:singleRoom];
    
    // Send image here
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      // Generate the file path
      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
      NSString *documentsDirectory = [paths objectAtIndex:0];
      NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.room", theRoom.name]];
      
      // Save it into file system
      UIImage *image = [self convertImage:theRoom.image toSize:picSize];
      NSData* pictureData = UIImagePNGRepresentation(image);
      // Save it into file system
      [pictureData writeToFile:dataPath atomically:YES];
      NSURL *filePath = [[NSURL alloc] initFileURLWithPath:dataPath];
      
      [wcSession transferFile:filePath metadata:@{KeyName : theRoom.name, KeyType : KeyRoom}];
    });
  }
  
  // Construct all rooms
  NSMutableArray *groups = [[NSMutableArray alloc] init];
  for (Group *theGroup in house.groupList) {
    NSDictionary *singleGroup = @{ KeyName : theGroup.name};
    [groups addObject:singleGroup];
    
    // Send image here
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      // Generate the file path
      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
      NSString *documentsDirectory = [paths objectAtIndex:0];
      NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.group", theGroup.name]];
      
      // Save it into file system
      UIImage *image = [self convertImage:theGroup.image toSize:picSize];
      NSData* pictureData = UIImagePNGRepresentation(image);
      // Save it into file system
      [pictureData writeToFile:dataPath atomically:YES];
      NSURL *filePath = [[NSURL alloc] initFileURLWithPath:dataPath];
      
      [wcSession transferFile:filePath metadata:@{KeyName : theGroup.name, KeyType : KeyGroup}];
    });
  }
  
  
  [dataDict addEntriesFromDictionary:@{ KeyRooms: rooms, KeyGroups : groups}];
  
  NSLog(@"Data: %@", dataDict);
  
  NSDictionary* response = @{KeyCommand : SyncCommand, KeyData : dataDict} ;
  [self packageAndSendMessage:response];
  
  // Send devices at last
  for (Room *theRoom in house.roomList) {
    for (Device *theDevice in theRoom.deviceList) {
      // Send image here
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // Generate the file path
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.device", theDevice.name]];
        
        UIImage *image = [self convertImage:theDevice.image toSize:picSize];
        NSData* pictureData = UIImagePNGRepresentation(image);
        // Save it into file system
        [pictureData writeToFile:dataPath atomically:YES];
        NSURL *filePath = [[NSURL alloc] initFileURLWithPath:dataPath];
        
        
        [wcSession transferFile:filePath metadata:@{KeyName : theDevice.name, KeyType : KeyDevice}];
      });
    }
  }
  
  for (Room *theRoom in house.roomList) {
    for (Device *theDevice in theRoom.deviceList) {
      // Device infos should also be sent
      if (theDevice.type == ir) {
        // Get all commands
        NSDictionary *deviceInfo = theDevice.info;
        NSArray *irCommands;
        if ([deviceInfo objectForKey:KeyIRCommands]) {
          irCommands = [deviceInfo objectForKey:KeyIRCommands];
          int index = 0;
          // For every existing ir command
          for (NSDictionary* irCommand in irCommands) {
            NSString *name = [irCommand objectForKey:KeyName];
            UIImage *theImage = [irCommand objectForKey:KeyImage];
            
            // Send image here
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
              // Generate the file path
              NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
              NSString *documentsDirectory = [paths objectAtIndex:0];
              NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.deviceInfo", [NSString stringWithFormat:@"%@%@", theDevice.name, name]]];
              
              UIImage *image = [self convertImage:theImage toSize:picSize];
              NSData* pictureData = UIImagePNGRepresentation(image);
              // Save it into file system
              [pictureData writeToFile:dataPath atomically:YES];
              NSURL *filePath = [[NSURL alloc] initFileURLWithPath:dataPath];
              [wcSession transferFile:filePath metadata:@{KeyName : theDevice.name, KeyInfo : name, KeyType : KeyDeviceInfo, KeyIndex : [NSString stringWithFormat:@"%i", index]}];
            });
            index++;
          }
        } else {
          NSLog(@"No IR Commands decoded");
        }
      }
    }
  }
}


- (void)session:(nonnull WCSession *)session didReceiveApplicationContext:(nonnull NSDictionary<NSString *,id> *)applicationContext {
  NSLog(@"App Context iPhone: %@", applicationContext);
}



/*
 * Resizes a given Image, by a given width, the target aspect ratio will fit the source ones.
 */
- (UIImage *)convertImage:(UIImage *)image toSize:(CGSize)size {
  UIGraphicsBeginImageContext(size);
  [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
  UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return destImage;
}

@end
