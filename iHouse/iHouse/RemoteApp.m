//
//  RemoteApp.m
//  iHouse
//
//  Created by Benjamin Völker on 24/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "RemoteApp.h"
#import "TCPServer.h"
// Include everything from the house, since we need to do things depending on the devices :/
#import "House.h"
#import "Socket.h"
#import "Light.h"
#import "Meter.h"
#import "Heating.h"
#import "Hoover.h"
#import "InfraredDevice.h"
#import "Display.h"
#import "Microphone.h"
#import "Speaker.h"
#import "IPadDisplay.h"
#import "Sensor.h"
#import "IDevice.h"


#define DEBUG_REMOTE 1

// Command to start syncing everything
#define SYNC_COMMAND @"sync"
// Command to start updating a given device
#define UPDATE_DEVICE_COMMAND @"up:"
// Command to start voice command recognition
#define SIRI_DEVICE_COMMAND @"siri:"
// Command to perform an action on a device
#define ACTION_DEVICE_COMMAND @"action:"
// Command to activate a group
#define ACTION_GROUP_COMMAND @"group:"
// A seperator between name and value
#define SEPERATOR_COMMAND @";/;"
// If received autosync command the server starts syncing with device
#define AUTOSYNC_COMMAND @"autoSync"
// If the remote should identify itself
#define IDENTIFY_COMMAND @"identy"
// Dictionary Keys for syncing with the remote
#define SYNC_KEY_TYPE @"type"
#define SYNC_KEY_ROOM @"room"
#define SYNC_KEY_NAME @"name"
#define SYNC_KEY_IMAGE @"image"
#define SYNC_KEY_INFO @"info"
// Room and Group are simply different type numbers
#define SYNC_ROOM_TYPE 1000
#define SYNC_GROUP_TYPE 1001
// Images of devices and rooms are sent in this size squared(Size X Size)
#define IMAGE_SIZE 256
// The images of infrared devices commands are sent much smaller, to fasten synchronization
#define IR_IMAGE_SIZE 100

// The different actions for devices that exist:
// Switch actions can be lights and switchable sockets
#define SWITCH_ACTION @"switch"
// Toggle actions can be infrared devices, the string after the toggle command
#define TOGGLE_ACTION @"toggle:"

// Keys for specific devices info (e.g. light state, or heatin temp)
NSString * const SocketLightKeyState = @"SocketLightKeyState";
NSString * const HeatingKeyTemp = @"HeatingKeyTemp";
NSString * const IRKeyCommands = @"IRKeyCommands";

@implementation RemoteApp

@synthesize tcpConnectionHandler, host;

/*
 * Init this thing
 */
- (id)init {
  self = [super init];
  if (self) {
    host = @"";
    tcpConnectionHandler = [[TCPConnectionHandler alloc] init];
    tcpConnectionHandler.delegate = self;
  }
  return self;
}


/*
 * Identifies the connected remote.
 */
- (void)identify {
  [tcpConnectionHandler sendCommandWithNL:IDENTIFY_COMMAND];
}


/*
 * Returns if the device is connected over tcp or not.
 */
- (BOOL)isConnected {
  return [tcpConnectionHandler isConnected];
}

/*
 * If the device connected successfully.
 */
-(void)deviceConnected:(GCDAsyncSocket *)sock {
  // Init connection handler with correct socket
  tcpConnectionHandler = [[TCPConnectionHandler alloc] initWithSocket:sock];
  tcpConnectionHandler.delegate = self;
  
  if (DEBUG_REMOTE) NSLog(@"Remote Device connected");
}

/*
 * Will force the remote to sync itself (can be used so that changes made in the server application could be
 * automatically updated to the remote app)
 */
-(void)forceSync {
  // We can only sync if someone is connected
  if ([self isConnected]) {
    [tcpConnectionHandler sendCommandWithNL:AUTOSYNC_COMMAND];
    NSLog(@"Sync forced");
  }
}

/*
 * Will return the info dict for a given device.
 */
-(NSDictionary*)infoDictForDevice:(IDevice*)iDevice {
  // We need an info dict
  NSDictionary *dict = [[NSDictionary alloc] init];
  
  // Depending on the devices
  switch (iDevice.type) {
      // If it is a light, we need to add the current state of the light into the dictionary
    case light:
      dict = [NSDictionary dictionaryWithObjectsAndKeys:
              [NSNumber numberWithBool:[(Light*)iDevice.theDevice state]], SocketLightKeyState, nil];
      break;
      // The same for a switchable socket
    case switchableSocket:
      dict = [NSDictionary dictionaryWithObjectsAndKeys:
              [NSNumber numberWithBool:[(Socket*)iDevice.theDevice state]], SocketLightKeyState, nil];
      break;
      // For a meter device, send the last values
    case meter: {
      dict = [[(Meter*)[iDevice theDevice] storedDataHourMinute] lastObject];
      break;
    }
      // For a sensor device, send the last sensor values
    case sensor: {
      dict = [[(Sensor*)[iDevice theDevice] storedDataHourMinute] lastObject];
      break;
      
    }
      // For the heating send the current set temperature
    case heating:
      dict = [NSDictionary dictionaryWithObjectsAndKeys:
              [(Heating*)iDevice.theDevice currentTemperature], HeatingKeyTemp, nil];
      break;
      // More work for IR
    case ir: {
      // Allocate array to hold command information
      NSMutableArray *irCommands = [[NSMutableArray alloc] init];
      // Loop over all infrared commands in this device
      for (InfraredCommand *theCommand in [(InfraredDevice*)iDevice.theDevice infraredCommands]) {
        // Store image of the command
        NSImage *target = [self resizeImage:theCommand.image width:IR_IMAGE_SIZE];
        // Convert to Tiff since UIImage needs tiff
        NSData *imageData = [target TIFFRepresentation];
        // Add command name and image to the dict
        NSDictionary *commandDict = [NSDictionary dictionaryWithObjectsAndKeys:theCommand.name, SYNC_KEY_NAME,
                                     imageData, SYNC_KEY_IMAGE, nil];
        [irCommands addObject:commandDict];
      }
      // Add it again into a dict, which is a little bit useless but hey, it does not hurt much
      dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithArray:irCommands], IRKeyCommands, nil];
      break;
    }
    default:
      break;
  }
  return dict;
}

/*
 * Will return the info dict for a given device.
 */
-(NSDictionary*)completeInfoDictForDevice:(IDevice*)iDevice {
  // We need a mutable dictionary where we store the device name, type and the info dict
  NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
  [mutDict addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInteger:iDevice.type], SYNC_KEY_TYPE,
                                     iDevice.name, SYNC_KEY_NAME, nil]];
  
  [mutDict addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [self infoDictForDevice:iDevice], SYNC_KEY_INFO, nil]];
  return mutDict;
}

/*
 * Returns the iDevice for a given devuce name, will return nil else.
 * TODO: What if the device name changed on server side but remote
 * still asks for it?
 */
-(IDevice*)deviceWithName:(NSString*)deviceName {
  IDevice *device;
  for (Room *theRoom in [[House sharedHouse] rooms]) {
    for (IDevice *theDevice in [theRoom devices]) {
      if ([[theDevice name] isEqualToString:deviceName]) {
        device = theDevice;
      }
    }
  }
  return device;
}


/*
 * If the device sent a command to us, we need to respond accordingly.
 */
-(void)receivedCommand:(NSString *)theCommand {
  if (DEBUG_REMOTE) NSLog(@"Received remote Command: %@", theCommand);
  // If the command wants us to start voice command detection start it
  if ([theCommand containsString:SIRI_DEVICE_COMMAND]) {
    [[NSNotificationCenter defaultCenter] postNotificationName:StartVoiceCommandDetection object:self];
  // If the command is an action to toggle a group
  } else if ([theCommand containsString:ACTION_GROUP_COMMAND]) {
    // Decode Group command
    NSRange range = [theCommand rangeOfString:ACTION_GROUP_COMMAND];
    NSString *groupName = [theCommand substringFromIndex:range.location+range.length];
    if (DEBUG_REMOTE) NSLog(@"Group: %@", groupName);
    for (Group *theGroup in [[House sharedHouse] groups]) {
      if ([theGroup.name isEqualToString:groupName]) {
        [theGroup activate];
      }
    }
  // If the command is an action for a specific device
  } else if ([theCommand containsString:ACTION_DEVICE_COMMAND]) {
    // Decode Action command
    NSRange range = [theCommand rangeOfString:ACTION_DEVICE_COMMAND];
    theCommand = [theCommand substringFromIndex:range.location+range.length];
    // Handle action command in function
    [self handleDeviceActionCommand:theCommand];
  } else if ([theCommand containsString:UPDATE_DEVICE_COMMAND]) {
    NSRange range = [theCommand rangeOfString:UPDATE_DEVICE_COMMAND];
    // Extract the device name of the device to update
    theCommand = [theCommand substringFromIndex:range.location+range.length];
    if (DEBUG_REMOTE) NSLog(@"Update device: %@", theCommand);
    // Update the info of this device
    [self updateDevice:theCommand];
  // If command is a complete sync command
  } else if ([theCommand isEqualToString:SYNC_COMMAND]) {
    [self updateAll];
  }
}

/*
 * Update the complete house on the remote.
 */
-(void)updateAll {
  NSMutableArray *array = [[NSMutableArray alloc] init];
  // A complete update is indicated by a leading 0
  [array addObject:[NSNumber numberWithInt:0]];
  
  // Get every object inside the House
  House *theHouse = [House sharedHouse];
  
  // Loop over all Groups
  for (Group *theGroup in [theHouse groups]) {
    // Add the group with icon
    NSImage *target = [self resizeImage:[theGroup image] width:IMAGE_SIZE];
    NSData *imageData = [target TIFFRepresentation];
    //NSData *imageData = [self imageResize:sourceImageData newSize:NSMakeSize(IMAGE_SIZE, IMAGE_SIZE)];
    NSDictionary *dev = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithInteger:SYNC_GROUP_TYPE], SYNC_KEY_TYPE,
                         theGroup.name, SYNC_KEY_NAME,
                         imageData, SYNC_KEY_IMAGE,
                         nil];
    [array addObject:dev];
  }
  
  // Loop over all rooms
  for (Room *theRoom in [theHouse rooms]) {
    // Add the room with icon
    NSImage *target = [self resizeImage:[theRoom image] width:IMAGE_SIZE];
    NSData *imageData = [target TIFFRepresentation];
    //NSData *imageData = [self imageResize:sourceImageData newSize:NSMakeSize(IMAGE_SIZE, IMAGE_SIZE)];
    NSDictionary *dev = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithInteger:SYNC_ROOM_TYPE], SYNC_KEY_TYPE,
                         theRoom.name, SYNC_KEY_NAME,
                         imageData, SYNC_KEY_IMAGE,
                         nil];
    [array addObject:dev];
    
    // And all devices
    for (IDevice *theDevice in [theRoom devices]) {
      // If the type is not a remote
      if (theDevice.type != iPadDisplay && theDevice.type != rcSwitch && theDevice.type != display) {
        // Get information of it
        NSImage *target = [self resizeImage:[theDevice image] width:IMAGE_SIZE];
        NSData *imageData = [target TIFFRepresentation];
        NSDictionary *dev = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithInteger:theDevice.type], SYNC_KEY_TYPE,
                             theDevice.name, SYNC_KEY_NAME,
                             theDevice.roomName, SYNC_KEY_ROOM,
                             imageData, SYNC_KEY_IMAGE,
                             [self infoDictForDevice:theDevice], SYNC_KEY_INFO,
                             nil];
        [array addObject:dev];
      }
    }
  }
  [self sendArray:array];
}

/*
 * Update the info of a given device.
 */
-(void)updateDevice:(NSString*)deviceName {
  NSMutableArray *array = [[NSMutableArray alloc] init];
  
  // Indicate update of info for device
  // A 1 is only inside if this is an update for a single device
  [array addObject:[NSNumber numberWithInt:1]];
  
  // Get every object inside the House
  House *theHouse = [House sharedHouse];
  // Loop over all rooms
  for (Room *theRoom in [theHouse rooms]) {
    // And all devices
    for (IDevice *theDevice in [theRoom devices]) {
      // If the device really exists, add info dict and send
      if ([theDevice.name isEqualToString:deviceName]) {
        if (DEBUG_REMOTE) NSLog(@"Device found: %@", theDevice.name);
        NSDictionary *info = [self completeInfoDictForDevice:(IDevice*)theDevice];
        [array addObject:info];
      }
    }
  }
  [self sendArray:array];
}

/*
 * Handles a given action command
 */
-(void)handleDeviceActionCommand:(NSString*)theCommand {
  if (DEBUG_REMOTE) NSLog(@"Action device: %@", theCommand);
  // Remove seperator from command
  NSRange range = [theCommand rangeOfString:SEPERATOR_COMMAND];
  if (range.location != NSNotFound) {
    // Extract device name
    NSString *deviceName = [theCommand substringToIndex:range.location];
    if (DEBUG_REMOTE) NSLog(@"Device: %@", deviceName);
    theCommand = [theCommand substringFromIndex:range.location+range.length];
    range = [theCommand rangeOfString:SEPERATOR_COMMAND];
    if (range.location != NSNotFound) {
      // Extract action name e.g. switch
      NSString *actionName = [theCommand substringToIndex:range.location];
      if (DEBUG_REMOTE) NSLog(@"Action: %@", actionName);
      theCommand = [theCommand substringFromIndex:range.location+range.length];
      // Extract value which is in integer format
      int value = [theCommand intValue];
      if (DEBUG_REMOTE) NSLog(@"Value: %i", value);
      // Get the device with the given name
      IDevice *dev = [self deviceWithName:deviceName];
      // If device exists
      if (dev) {
        // Decode action
        // Switch Action
        if ([actionName isEqualToString:SWITCH_ACTION]) {
          // Type of iDevice must match to switch action (light or socket)
          if (dev.type != light && dev.type != switchableSocket) {
            NSLog(@"Device type does not match action");
            return;
          }
          // Performe toggle action
          [(Light*)dev.theDevice toggle:(bool)value];
        // Toggle action is available for IR Devices
        } else if ([actionName containsString:TOGGLE_ACTION]) {
          range = [actionName rangeOfString:TOGGLE_ACTION];
          // Extract name of IR command of the device
          NSString *commandName = [actionName substringFromIndex:range.location+range.length];
          if (DEBUG_REMOTE) NSLog(@"SubIRDevice: %@", commandName);
          // If type of device matches to IR
          if (dev.type != ir) {
            NSLog(@"Device type does not match action");
            return;
          }
          // Search for the command with the given name
          for (InfraredCommand* theCommand in [(InfraredDevice*)dev.theDevice infraredCommands]) {
            // Toggle if command exists
            if ([theCommand.name isEqualToString:commandName]) {
              [theCommand toggle];
              if (DEBUG_REMOTE) NSLog(@"Toggle: %@", commandName);
            }
          }
          
        }
      }
    }
  }
}


- (void)sendArray:(NSArray*) array {
  
  // Convert array to data
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
  //if (DEBUG_IPAD) NSLog(@"Number of kB: %.2f", (data.length/1024.0f));
  if (DEBUG_REMOTE) NSLog(@"Number of %li Bytes", (data.length));
  
  // Indicate that it is data by sending '/' at first
  char c = '/';
  NSMutableData *commandAndData = [[NSMutableData alloc] initWithBytes:&c length:1];
  
  // Get length of data as long value
  SInt64 long_value = CFSwapInt64HostToBig(data.length);
  // Pointer to long
  UInt8 *long_ptr = (UInt8 *)& long_value;
  // Store long into byte array and thus append the length of the data to be buffered
  [commandAndData appendData:[[NSData alloc] initWithBytes:long_ptr length:8]];
  // Appeld the data and send it
  [commandAndData appendData:data];
  [tcpConnectionHandler sendData:commandAndData];
  //NSLog(@"Data: %@", data);
}

/*
 * Resizes a given Image, by a given width, the target aspect ratio will fit the source ones.
 */
- (NSImage*) resizeImage:(NSImage*)sourceImage width:(NSInteger)width{
  // Compute target height
  float targetWidth = width;
  float targetHeight = sourceImage.size.height/(float)sourceImage.size.width * targetWidth;
  
  // Alloc target image
  NSImage*  targetImage = [[NSImage alloc] initWithSize:NSMakeSize(targetWidth, targetHeight)];
  
  NSSize originalSize = [sourceImage size];
  [targetImage lockFocus];
  [sourceImage drawInRect: NSMakeRect(0, 0, targetWidth, targetHeight) fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height) operation: NSCompositeSourceOver fraction: 1.0];
  [targetImage unlockFocus];
  
  return targetImage;
}


@end
