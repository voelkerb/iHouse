//
//  House.m
//  iHouse
//
//  Created by Benjamin Völker on 18/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "House.h"

#define FOLDER_NAME @"iHouse Data"
#define FILE_ENDING @".house"
#define FILE_NAME @"yourHouse"
#define DEBUG_STORE 0

@implementation House
@synthesize name, rooms, voiceCommands, groups;

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
      NSString *fileDirectory = [documentsDirectory stringByAppendingPathComponent:FOLDER_NAME];
      // Append fileName
      NSString *appFile = [fileDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", FILE_NAME, FILE_ENDING]];
      NSFileManager *fileManager = [NSFileManager defaultManager];
      // Look if the filePath already exist, if not create it
      if ([fileManager fileExistsAtPath:fileDirectory] == NO) {
        [fileManager createDirectoryAtPath:fileDirectory withIntermediateDirectories:NO attributes:nil error:nil];
      }
      sharedHouse = [NSKeyedUnarchiver unarchiveObjectWithFile:appFile];
      
      // If File does not exist create it
      if (sharedHouse == nil) {
        sharedHouse = [[self alloc] init];
      }
      
      // Archive the house object
      if (DEBUG_STORE) {
        NSLog(@"Opening... ");
        NSLog(@"Rooms:");
        for (Room *room in [sharedHouse rooms]) NSLog(@"\t%@", [room name]);
        NSLog(@"Devices:");
        for (Room *room in [sharedHouse rooms]) {
          for (IDevice *device in [room devices]) NSLog(@"\t%@", [device name]);
        }
        NSLog(@"VoiceCommands:");
        for (VoiceCommand *voiceCommand in [sharedHouse voiceCommands]) {
          NSLog(@"\t%@", [voiceCommand name]);
        }
        NSLog(@"Groups:");
        for (Group *group in [sharedHouse groups]) {
          NSLog(@"\t%@", [group name]);
        }
      }
    }
  }
  return sharedHouse;
}

- (id)init {
  if (self = [super init]) {
    name = @"my House";
    rooms = [[NSArray alloc] init];
    groups = [[NSArray alloc] init];
    voiceCommands = [[NSArray alloc] init];
  }
  return self;
}


// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.rooms forKey:@"rooms"];
  [encoder encodeObject:self.groups forKey:@"groups"];
  [encoder encodeObject:self.voiceCommands forKey:@"voiceCommands"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    self.name = [decoder decodeObjectForKey:@"name"];
    self.rooms = [decoder decodeObjectForKey:@"rooms"];
    self.groups = [decoder decodeObjectForKey:@"groups"];
    self.voiceCommands = [decoder decodeObjectForKey:@"voiceCommands"];
    if (!name) name = FILE_NAME;
    if (!rooms) rooms = [[NSArray alloc] init];
    if (!groups) groups = [[NSArray alloc] init];
    if (!voiceCommands) voiceCommands = [[NSArray alloc] init];
  }
  return self;
}


/*
 * Add a room with name color and image
 */
-(BOOL)addRoom:(NSString *)roomName :(NSColor *)theColor :(NSImage *)theImage :(id)sender {
    // Add new room with name image and color
  Room *newRoom = [[Room alloc] init];
  newRoom.name = roomName;
  newRoom.image = theImage;
  newRoom.color = theColor;
  
  return [self addRoom:newRoom :self];
}

/*
 * Add a room with name color and image
 */
-(BOOL)addRoom:(Room *)theRoom :(id)sender {
  // Go through every existing room
  for (Room *room in rooms) {
    // If name is matching to existing one, it cannot be stored
    if ([[room name] isEqualToString:[theRoom name]]) {
      return false;
    }
  }
  // Create new room array
  NSMutableArray *newRooms = [[NSMutableArray alloc] initWithArray:self.rooms];
  [newRooms addObject:theRoom];
  
  // Update member variable
  self.rooms = [NSArray arrayWithArray:newRooms];
  return true;
}

/*
 * Remove a room from the list of rooms
 */
- (BOOL)removeRoom: (NSString *) roomName : (id)sender {
  BOOL success = false;
  // The array of the new rooms
  NSMutableArray *newRooms = [[NSMutableArray alloc] init];
  // Go through every existing room
  for (Room *theRoom in rooms) {
    // If name is matching don't store it
    if ([[theRoom name] isEqualToString:roomName]) {
      success = true;
    // else store it
    } else {
      [newRooms addObject:theRoom];
    }
  }
  // Update member variable
  self.rooms = [NSArray arrayWithArray:newRooms];
  return success;
}



/*
 * Add a Voice command.
 */
-(BOOL)addVoiceCommand:(VoiceCommand *)theVoiceCommand :(id)sender {
  // Go through every existing voice command
  for (VoiceCommand *thisVoiceCommand in voiceCommands) {
    // If name is matching to existing one, it cannot be stored
    if ([[thisVoiceCommand name] isEqualToString:[theVoiceCommand name]]) {
      return false;
    }
  }
  // Create new voice command array
  NSMutableArray *newVoiceCommands = [[NSMutableArray alloc] initWithArray:self.voiceCommands];
  [newVoiceCommands addObject:theVoiceCommand];
  
  // Update member variable
  self.voiceCommands = [NSArray arrayWithArray:newVoiceCommands];
  
  // Post a notification that a voice command was added
  [[NSNotificationCenter defaultCenter] postNotificationName:VoiceCommandAdded object:theVoiceCommand];
  return true;
}

/*
 * Remove a Voice command from the list of voice commands
 */
- (BOOL)removeVoiceCommand:(NSString *)theVoiceCommandName :(id)sender {
  BOOL success = false;
  VoiceCommand *removedVoiceCommand = nil;
  // The array of the new voice commands
  NSMutableArray *newVoiceCommands = [[NSMutableArray alloc] init];
  // Go through every existing voice command
  for (VoiceCommand *theVoiceCommand in voiceCommands) {
    // If name is matching don't store it
    if ([[theVoiceCommand name] isEqualToString:theVoiceCommandName]) {
      success = true;
      removedVoiceCommand = theVoiceCommand;
      // else store it
    } else {
      [newVoiceCommands addObject:theVoiceCommand];
    }
  }
  // Update member variable
  self.voiceCommands = [NSArray arrayWithArray:newVoiceCommands];
  
  // Post a notification that a voice command was removed
  if (removedVoiceCommand) {
    [[NSNotificationCenter defaultCenter] postNotificationName:VoiceCommandRemoved object:removedVoiceCommand];
    if (DEBUG_STORE) NSLog(@"Deleted voice command %@ successfully.", removedVoiceCommand);
  }
  return success;
}

/*
 * Add a Group to the house.
 */
-(BOOL)addGroup:(Group *)theGroup :(id)sender {
  // Go through every existing room
  for (Group *group in groups) {
    // If name is matching to existing one, it cannot be stored
    if ([[group name] isEqualToString:[theGroup name]]) {
      return false;
    }
  }
  // Create new room array
  NSMutableArray *newGroups = [[NSMutableArray alloc] initWithArray:self.groups];
  [newGroups addObject:theGroup];
  
  // Update member variable
  self.groups = [NSArray arrayWithArray:newGroups];
  return true;
}


/*
 * Remove a Group from the list of groups
 */
- (BOOL)removeGroup:(NSString *)theGroupName :(id)sender {
  BOOL success = false;
  Group *removedGroup = nil;
  // The array of the new groups
  NSMutableArray *newGroups = [[NSMutableArray alloc] init];
  // Go through every existing group
  for (Group *theGroup in groups) {
    // If name is matching don't store it
    if ([[theGroup name] isEqualToString:theGroupName]) {
      success = true;
      removedGroup = theGroup;
      // else store it
    } else {
      [newGroups addObject:theGroup];
    }
  }
  // Update member variable
  self.groups = [NSArray arrayWithArray:newGroups];
  
  // Post a notification that a group was removed
  if (removedGroup) {
    [[NSNotificationCenter defaultCenter] postNotificationName:GroupRemoved object:removedGroup];
    if (DEBUG_STORE) NSLog(@"Deleted group %@ successfully.", removedGroup);
  }
  return success;
}



/*
 * Get the path where the data gets stored (this is the document directory)
 */
- (NSString *) pathForDataFile: (NSString *) fileName {
  // Append folder where it gets stored in// Get the path of the document directory
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  // Append folder where it gets stored in
  NSString *fileDirectory = [documentsDirectory stringByAppendingPathComponent:FOLDER_NAME];
  // Append fileName
  NSString *appFile = [fileDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", FILE_NAME, FILE_ENDING]];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  // Look if the filePath already exist, if not create it
  if ([fileManager fileExistsAtPath:fileDirectory] == NO) {
    [fileManager createDirectoryAtPath:fileDirectory withIntermediateDirectories:NO attributes:nil error:nil];
  }
  return appFile;
}

// Store House in File
- (BOOL)store:(id) sender {
  // Archive the house object
  if (DEBUG_STORE) {
    NSLog(@"Storing... ");
    NSLog(@"Rooms:");
    for (Room *room in rooms) NSLog(@"\t%@", [room name]);
    NSLog(@"Devices:");
    for (Room *room in rooms) {
      for (IDevice *device in [room devices]) NSLog(@"\t%@", [device name]);
    }
    NSLog(@"VoiceCommands:");
    for (VoiceCommand *voiceCommand in voiceCommands) NSLog(@"\t%@", [voiceCommand name]);
  }
  return [NSKeyedArchiver archiveRootObject:self toFile:[self pathForDataFile:FILE_NAME]];
}



@end
