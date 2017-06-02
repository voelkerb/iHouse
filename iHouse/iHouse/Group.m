//
//  Group.m
//  iHouse
//
//  Created by Benjamin Völker on 15/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "Group.h"

// Default image for a group
#define DEFAULT_GROUP_IMAGE_NAME @"groups_256.png"

#define DEBUG_GROUP 1

// Keys for dictionary
NSString* const KeyGroupDevice = @"keyGroupDevice";
NSString* const KeyGroupSelector = @"keyGroupSelector";
NSString* const KeyGroupStandardSelector = @"KeyGroupStandardSelector";
NSString* const GroupRemoved = @"GroupRemoved";
NSString* const GroupAdded = @"GroupAdded";
NSString* const GroupChanged = @"GroupChanged";

@implementation Group

@synthesize name, image, groupItems;

/*
 * Init Function sets all values of the group to standard
 */
- (id)init {
  self = [super init];
  if (self) {
    // The default values for a new device
    name = STANDARD_GROUP_NAME;
    image = [NSImage imageNamed:DEFAULT_GROUP_IMAGE_NAME];
    groupItems = [[NSMutableArray alloc] init];
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.image forKey:@"image"];
  [encoder encodeObject:self.groupItems forKey:@"groupItems"];}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    self.name = [decoder decodeObjectForKey:@"name"];
    self.image = [decoder decodeObjectForKey:@"image"];
    self.groupItems = [decoder decodeObjectForKey:@"groupItems"];
    // If some decoding goes wrong, set variables to standard
    if (!name) name = @"new group";
    if (!image) image = [NSImage imageNamed:DEFAULT_GROUP_IMAGE_NAME];
    if (!groupItems) groupItems = [[NSMutableArray alloc] init];
  }
  return self;
}

/*
 * Add a device with selector to the dictionary array
 */
-(BOOL)addDevice:(IDevice *)theDevice withSelector:(NSString *)theSelector {
  // Allocate new group item
  GroupItem *item = [[GroupItem alloc] init];
  // Set device and selector of the device
  item.device = theDevice;
  item.selector = theSelector;
  // Add the item to the list of group items
  [groupItems addObject:item];
  return true;
}

/*
 * Add a new group item with standard values
 */
-(BOOL)addDevice {
  GroupItem *item = [[GroupItem alloc] init];
  [groupItems addObject:item];
  return true;
}

/*
 * Activate the group.
 */
-(BOOL)activate {
  BOOL success = true;
  // Loop over all group items
  for (GroupItem *theItem in groupItems) {
    if (DEBUG_GROUP) NSLog(@"Perform: %@ on: %@", theItem.selector, theItem.device.name);
    // Perform the action of each device (this could of course fail)
    if (![theItem performTheSelector]) success = false;
  }
  return success;
}

@end
