//
//  House.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 05/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "House.h"
#define FILE_ENDING @".house"
#define FILE_NAME @"yourHouse"

@implementation House

@synthesize roomList, groupList;

/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedHouse {
  static House *sharedHouse = nil;
  @synchronized(self) {
    if (sharedHouse == nil) {
      // Init self from file
      // Get the path of the document directory
      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
      NSString *documentsDirectory = [paths objectAtIndex:0];
      // Append folder where it gets stored in
      // Append fileName
      NSString *appFile = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", FILE_NAME, FILE_ENDING]];
      
      sharedHouse = [NSKeyedUnarchiver unarchiveObjectWithFile:appFile];
      
      // If File does not exist create it
      if (sharedHouse == nil) {
        sharedHouse = [[self alloc] init];
      }
    }
  }
  return sharedHouse;
}

/*
 * Init function
 */
- (id)init {
  if((self = [super init])) {
    roomList = [[NSMutableArray alloc] init];
    groupList = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  //Encode properties, other class variables, etc
  [encoder encodeObject:self.roomList forKey:@"roomList"];
  [encoder encodeObject:self.groupList forKey:@"groupList"];
}

- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    //decode properties, other class vars
    self.roomList = [decoder decodeObjectForKey:@"roomList"];
    self.groupList = [decoder decodeObjectForKey:@"groupList"];
  }
  return self;
}

/*
 * Get the path where the data gets stored (this is the document directory)
 */
- (NSString *) pathForDataFile {
  // Append folder where it gets stored in// Get the path of the document directory
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  // Append folder where it gets stored in
  // Append fileName
  NSString *appFile = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", FILE_NAME, FILE_ENDING]];
  // Look if the filePath already exist, if not create it
  return appFile;
}

// Store Settings in File
- (BOOL)store {
  // Archive the house object
  //NSLog(@"%@", [self pathForDataFile:FILE_NAME]);
  return [NSKeyedArchiver archiveRootObject:self toFile:[self pathForDataFile]];
}


-(Device*)getDeviceNamed:(NSString*)deviceName {
  for (Room* theRoom in self.roomList) {
    for (Device* theDevice in theRoom.deviceList) {
      if ([theDevice.name isEqualToString:deviceName]) return theDevice;
    }
  }
  return nil;
}

-(void) initDummyHouse {
  Room* livingRoom = [[Room alloc] init];
  livingRoom.name = @"Living Room";
  Device* ceilingLight = [[Device alloc] init];
  ceilingLight.name = @"Ceiling Light";
  Device* standLight = [[Device alloc] init];
  standLight.name = @"Stand Light";
  [livingRoom addDevice:ceilingLight];
  [livingRoom addDevice:standLight];
  
  Room* kitchen = [[Room alloc] init];
  kitchen.name = @"Kitchen";
  Device* kitchenLight = [[Device alloc] init];
  kitchenLight.name = @"Light";
  [kitchen addDevice:kitchenLight];
  
  Room* bedroom = [[Room alloc] init];
  bedroom.name = @"Bedroom";
  Device* bedroomLight = [[Device alloc] init];
  bedroomLight.name = @"Light";
  [bedroom addDevice:bedroomLight];
  
  [self addRoom:livingRoom];
  [self addRoom:kitchen];
  [self addRoom:bedroom];
  
}


-(void)addRoom:(Room *)room {
  [roomList addObject:room];
}


-(void)addGroup:(Group *)group {
  [groupList addObject:group];
}

-(void)destroy {
  [groupList removeAllObjects];
  [roomList removeAllObjects];
}

@end
