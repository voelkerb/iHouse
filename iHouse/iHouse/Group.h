//
//  Group.h
//  iHouse
//
//  Created by Benjamin Völker on 15/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDevice.h"
#import "GroupItem.h"

// The standard name of the group
#define STANDARD_GROUP_NAME @"new group"

// Key for dictionary
extern NSString* const KeyGroupDevice;
extern NSString* const KeyGroupSelector;
extern NSString* const KeyGroupStandardSelector;
extern NSString* const GroupRemoved;
extern NSString* const GroupAdded;
extern NSString* const GroupChanged;


@interface Group : NSObject<NSCoding>

// The name of the group
@property (strong) NSString *name;
// The image of the group
@property (strong) NSImage *image;
// An array holding the group items (seperate NSObject)
@property (strong) NSMutableArray *groupItems;

// Activate the group
-(BOOL)activate;
// Add a device to the group with the given selector
-(BOOL)addDevice:(IDevice*)theDevice withSelector:(NSString*)theSelector;
// Add a device to group
-(BOOL)addDevice;

@end
