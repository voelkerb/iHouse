//
//  Room.m
//  iHouse
//
//  Created by Benjamin Völker on 18/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "Room.h"
#import "House.h"

#define DEBUG_ROOM false

#define DEFAULT_ROOM_IMAGE_NAME @"roomBold_256.png"

NSString * const RoomBackgroundDidChange = @"RoomBackgroundDidChange";
NSString * const RoomNameDidChange = @"RoomNameDidChange";
NSString * const RoomImageDidChange = @"RoomImageDidChange";
NSString * const RoomDeviceDidChange = @"RoomDeviceDidChange";

@implementation Room
@synthesize name, color, image, devices, changed;

- (id)init {
  self = [super init];
  if (self) {
    // The default values for a new device
    name = @"new device";
    image = [NSImage imageNamed:DEFAULT_ROOM_IMAGE_NAME];
    devices = [[NSArray alloc] init];
    color = [NSColor clearColor];
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.image forKey:@"image"];
  [encoder encodeObject:self.devices forKey:@"devices"];
  [encoder encodeObject:self.color forKey:@"color"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    self.name = [decoder decodeObjectForKey:@"name"];
    self.image = [decoder decodeObjectForKey:@"image"];
    self.devices = [decoder decodeObjectForKey:@"devices"];
    self.color = [decoder decodeObjectForKey:@"color"];
    // Set delegate
    for (IDevice *theDevice in devices) theDevice.delegate = self;
  }
  return self;
}


/*
 * Add a device with name color and image and type
 */
-(BOOL)addDevice:(IDevice *)theDevice :(id)sender {
  // Go through every existing devices
  for (IDevice *device in devices) {
    // If name is matching to existing one, it cannot be stored
    if ([[device name] isEqualToString:[theDevice name]]) {
      return false;
    }
  }
  // Set delegate
  theDevice.delegate = self;
  // Create new device array
  NSMutableArray *newDevices = [[NSMutableArray alloc] initWithArray:self.devices];
  [newDevices addObject:theDevice];
  
  // Update member variable
  self.devices = [NSArray arrayWithArray:newDevices];
  
  
  // Add the voice commands of the device
  [self addVoiceCommandsOfDevice:theDevice];
  
  return true;
}

/*
 * Add a device with name color and image and type
 */
-(BOOL)addDevice:(NSString *)deviceName :(NSColor *)theColor :(NSImage *)theImage :(DeviceType)deviceType :(id)sender {
  IDevice *newDevice = [[IDevice alloc] init];
  newDevice.name = deviceName;
  newDevice.image = theImage;
  newDevice.color = theColor;
  newDevice.type = deviceType;
  return [self addDevice:newDevice:self];
}

/*
 * Remove a device from the list of devices
 */
- (BOOL)removeDevice: (NSString *) deviceName : (id)sender {
  BOOL success = false;
  // The array of the new devices
  NSMutableArray *newDevices = [[NSMutableArray alloc] init];
  // Go through every existing device
  for (IDevice *theDevice in devices) {
    // If name is matching don't store it
    if ([[theDevice name] isEqualToString:deviceName]) {
      success = true;
      // Delete the voice commands of this device
      [self deleteVoiceCommandsOfDevice:theDevice];
      // Free the socket of the device
      if ([[theDevice theDevice] respondsToSelector:@selector(freeSocket)]) {
        [[theDevice theDevice] performSelector:@selector(freeSocket) withObject: nil];
      }
      // else store it
    } else {
      [newDevices addObject:theDevice];
    }
  }
  if (DEBUG_ROOM) NSLog(@"deleting %@ %i", deviceName, success);
  // Update member variable
  self.devices = [NSArray arrayWithArray:newDevices];
  return success;
}



/*
 * Returns a sorted dictionary of devices in this room.
 */
-(NSDictionary *)sortedDevices {
  NSMutableArray *keys = [[NSMutableArray alloc] init];
  NSMutableArray *objects = [[NSMutableArray alloc] init];
  for (DeviceType theType = light; theType < differentDeviceCount; theType++) {
    NSMutableArray *deviceArray = [[NSMutableArray alloc] init];
    for (IDevice *theDevice in devices) {
      if (theType == [theDevice type]) {
        [deviceArray addObject:theDevice];
      }
    }
    IDevice *dummyDevice = [[IDevice alloc] init];
    if ([deviceArray count] > 0) {
      [keys addObject:[dummyDevice DeviceTypeToString:theType]];
      [objects addObject:deviceArray];
    }
  }
  
  NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithObjects:objects forKeys:keys];
  return dict;
}


/*
 * Adds the corresponding voice commands after adding the device to the room.
 */
- (void)addVoiceCommandsOfDevice:(IDevice*)theIDevice {
  House *theHouse = [House sharedHouse];
  for (VoiceCommand* theVoiceCommand in [theIDevice standardVoiceCommands]) {
    [theHouse addVoiceCommand:theVoiceCommand :self];
  }
  if (DEBUG_ROOM) NSLog(@"Added voice commands: %@",[theIDevice standardVoiceCommands]);
}

/*
 * Adds the corresponding voice commands after adding the device to the room.
 */
- (void)deleteVoiceCommandsOfDevice:(IDevice*)theIDevice {
  House *theHouse = [House sharedHouse];
  for (VoiceCommand* theVoiceCommand in [theHouse voiceCommands]) {
    if ([[theVoiceCommand handler] isEqualTo:theIDevice]) {
        [theHouse removeVoiceCommand:[theVoiceCommand name] :self];
    }
  }
}


#pragma mark iDevice delegate methods

// Returns the roomname of the device
-(NSString *)getRoomName {
  return self.name;
}


@end
