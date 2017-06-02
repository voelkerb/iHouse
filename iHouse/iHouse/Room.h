//
//  Room.h
//  iHouse
//
//  Created by Benjamin Völker on 18/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "IDevice.h"

extern NSString * const RoomBackgroundDidChange;
extern NSString * const RoomNameDidChange;
extern NSString * const RoomImageDidChange;
extern NSString * const RoomDeviceDidChange;

@interface Room : NSObject <NSCoding, IDeviceDelegate>

// The name of the room
@property (strong) NSString *name;
// The color of the room
@property (strong) NSColor *color;
// The image of the room
@property (strong) NSImage* image;
// The devices inside the room
@property (strong) NSArray *devices;

// If something has changed
@property BOOL changed;


// Adding a room to a house
- (BOOL)addDevice:(NSString*) deviceName : (NSColor*) theColor : (NSImage*) theImage : (DeviceType) deviceType : (id)sender;

// Adding a room to a house
- (BOOL)addDevice: (IDevice*) theDevice : (id)sender;

// Remove a room of the house
- (BOOL)removeDevice:(NSString*) deviceName : (id)sender;

// Returns a sorted dictionary of devices in this room
- (NSDictionary*)sortedDevices;

@end
