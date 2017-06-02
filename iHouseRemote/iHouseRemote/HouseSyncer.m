//
//  HouseSyncer.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 04.02.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "HouseSyncer.h"

#define DEBUG_UPDATE_DEVICE 1

#define COMMAND_UPDATE_DEVICE @"up:"
#define COMMAND_ACTION_DEVICE @"action:"
#define COMMAND_ACTION_GROUP @"group:"
#define COMMAND_SEPERATOR @";/;"

@implementation HouseSyncer
@synthesize synced;


/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedHouseSyncer {
  static HouseSyncer *sharedHouseSyncer = nil;
  @synchronized(self) {
    if (sharedHouseSyncer == nil) {
      sharedHouseSyncer = [[self alloc] init];
    }
  }
  return sharedHouseSyncer;
}

/*
 * Init funciton
 */
- (id)init {
  if((self = [super init])) {
    syncManager = [SyncManager sharedSyncManager];
    house = [House sharedHouse];
    synced = false;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncFinished) name:SyncFinished object:nil];
  }
  return self;
}

-(void)syncFinished {
  NSLog(@"Sync finished, store object");
  [[House sharedHouse] store];
  synced = true;
}

-(BOOL)isSynced {
  if ([[[House sharedHouse] roomList] count] > 0 || synced) return true;
  return false;
}

-(void)handleSyncArray:(NSArray*)syncArray {
  // first we need to destroy everything
  [[House sharedHouse] destroy];
  // Get list of rooms and store devices
  for (NSDictionary *subDict in syncArray) {
    if ([subDict objectForKey:SyncKeyType]) {
      if ([[subDict objectForKey:SyncKeyType] integerValue] == SyncKeyRoomType) {
        // Build new Room
        Room* theRoom = [[Room alloc] init];
        theRoom.name = [subDict objectForKey:SyncKeyName];
        theRoom.image = [UIImage imageWithData:[subDict objectForKey:SyncKeyImage]];
        if (theRoom.name) {
          [house addRoom:theRoom];
        }
        NSLog(@"Room: %@, %@", theRoom.name, theRoom.image);
      } else if ([[subDict objectForKey:SyncKeyType] integerValue] == SyncKeyGroupType) {
        Group* theGroup = [[Group alloc] init];
        theGroup.name = [subDict objectForKey:SyncKeyName];
        theGroup.image = [UIImage imageWithData:[subDict objectForKey:SyncKeyImage]];
        if (theGroup.name) {
          [house addGroup:theGroup];
        }
        NSLog(@"Group: %@, %@", theGroup.name, theGroup.image);
      } else {
        Device* theDevice = [[Device alloc] init];
        theDevice.name = [subDict objectForKey:SyncKeyName];
        theDevice.image = [UIImage imageWithData:[subDict objectForKey:SyncKeyImage]];
        theDevice.type = [[subDict objectForKey:SyncKeyType] integerValue];
        NSDictionary *deviceInfo = [subDict objectForKey:SyncKeyInfo];
        // If this is ir commands, reconstruct the images properly from data an store it in array
        // which contains dictionary with name and image
        if (theDevice.type == ir && [deviceInfo objectForKey:IRKeyCommands]) {
          NSArray *irCommands = [deviceInfo objectForKey:IRKeyCommands];
          NSMutableArray *newIRCommands = [[NSMutableArray alloc] init];
          for (NSDictionary* irCommand in irCommands) {
            NSString *name = [irCommand objectForKey:SyncKeyName];
            UIImage *image = [UIImage imageWithData:[irCommand objectForKey:SyncKeyImage]];
            [newIRCommands addObject:@{KeyName: name, KeyImage:image}];
          }
          [theDevice.info addEntriesFromDictionary:@{KeyIRCommands: newIRCommands}];
        } else {
          theDevice.info = [subDict objectForKey:SyncKeyInfo];
        }
        
        NSString* roomName = [subDict objectForKey:SyncKeyRoom];
        
        for (Room *room in [house roomList]) {
          if ([room.name isEqualToString:roomName]) {
            NSLog(@"Added Device: %@ of type: %@ to room: %@", theDevice.name, [theDevice deviceTypeToString], roomName);
            NSLog(@"DeviceInfo: %@", theDevice.info);
            [room addDevice:theDevice];
          }
        }
        
        
        NSLog(@"Device: %@, %@", theDevice.name, theDevice.image);
      }
    }
  }
}



- (void)updateDevice:(Device *)device {
  if (DEBUG_UPDATE_DEVICE) NSLog(@"Update device: %@", device.name);
  syncManager.delegate = self;
  NSString *command = [NSString stringWithFormat:@"%@%@", COMMAND_UPDATE_DEVICE, device.name];
  [syncManager sendCommand:command];
}


-(void)syncStatus:(float)progress{}

-(void)commandResponse:(NSString *)response {
  if (DEBUG_UPDATE_DEVICE) NSLog(@"Got Update: %@", response);
  
}

-(void)updateDeviceResponse:(NSDictionary *)deviceDict {
  //if (DEBUG_UPDATE_DEVICE) NSLog(@"Got Update: %@", deviceDict);
  NSMutableDictionary *dict;
  int index = -1;
  
  if ([deviceDict objectForKey:SyncKeyName]) {
    // Store new devices here
    NSString *deviceName = [deviceDict objectForKey:SyncKeyName];
    /*for (NSDictionary *theDeviceDict in deviceList) {
      if ([theDeviceDict objectForKey:SyncKeyName]) {
        if ([[theDeviceDict objectForKey:SyncKeyName] isEqualToString:deviceName]) {
          if (DEBUG_UPDATE_DEVICE) NSLog(@"For device: %@", [theDeviceDict objectForKey:SyncKeyName]);
          dict = [[NSMutableDictionary alloc] initWithDictionary:theDeviceDict];
          
          [dict addEntriesFromDictionary:deviceDict];
          index = (int)[deviceList indexOfObject:theDeviceDict];
        }
      }
    }
    if (dict && index != -1) {
      NSLog(@"Replaced object %@", [[deviceList objectAtIndex:index] valueForKey:SyncKeyName]);
      [deviceList replaceObjectAtIndex:index withObject:dict];
      // Display notification that object changed
      
      [[NSNotificationCenter defaultCenter] postNotificationName:DeviceDidChange
                                                          object:[[deviceList objectAtIndex:index] valueForKey:SyncKeyName]];
      
    }
    if (DEBUG_UPDATE_DEVICE) {
      [self displayWithoutImage];
    }
    */
  }
}


-(void)sendGroup:(Group*)group {
  NSString *command = [NSString stringWithFormat:@"%@%@", COMMAND_ACTION_GROUP, group.name];
  
  if (DEBUG_UPDATE_DEVICE) NSLog(@"Action for group: %@", group.name);
  syncManager.delegate = self;
  [syncManager sendCommand:command];
}

-(void)sendAction:(NSString *)action withValue:(int)value forDevice:(Device *)device {
  NSString *command = [NSString stringWithFormat:@"%@%@%@%@%@%i", COMMAND_ACTION_DEVICE, device.name,
                       COMMAND_SEPERATOR, action, COMMAND_SEPERATOR, value];
  
  if (DEBUG_UPDATE_DEVICE) NSLog(@"Action %@:%i for device: %@", action, value, device.name);
  syncManager.delegate = self;
  [syncManager sendCommand:command];
}

-(void)activateSiri {
  [[SyncManager sharedSyncManager] sendCommand:SiriCommand];
}


@end
