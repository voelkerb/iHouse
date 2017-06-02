//
//  Device.m
//  LivingHome0.2
//
//  Created by Benjamin Völker on 5/9/14.
//  Copyright (c) 2014 Benny Völker. All rights reserved.
//

#import "IDevice.h"
#import "House.h"
#import "VoiceCommand.h"

#define DEBUG_IDEVICE 0
#define DEBUG 1

// The default device picture
#define DEFAULT_DEVICE_IMAGE_NAME @"devices_256.png"

NSString * const iDeviceTileView = @"iDeviceTileView";
NSString * const iDeviceDidChange = @"iDeviceDidChange";

@implementation IDevice
@synthesize name, theDevice, type, image, color, delegate;


- (id)init {
  self = [super init];
  if (self) {
    // The default values for a new device
    name = @"new device";
    image = [NSImage imageNamed:DEFAULT_DEVICE_IMAGE_NAME];
    type = light;
    theDevice = nil;
    color = [NSColor clearColor];
    [self changeDeviceType:type];
  }
  return self;
}

// Init with type
- (id)initWithDeviceType:(DeviceType) theType {
  self = [super init];
  if (self) {
    // The default values for a new device
    name = @"new device";
    image = [NSImage imageNamed:DEFAULT_DEVICE_IMAGE_NAME];
    type = theType;
    color = [NSColor clearColor];
    //Init with correct device
    [self changeDeviceType:theType];
  }
  return self;
}


// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeInteger:self.type forKey:@"type"];
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.image forKey:@"image"];
  [encoder encodeObject:self.theDevice forKey:@"theDevice"];
  [encoder encodeObject:self.color forKey:@"color"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    self.type = [decoder decodeIntegerForKey:@"type"];
    self.name = [decoder decodeObjectForKey:@"name"];
    self.image = [decoder decodeObjectForKey:@"image"];
    self.theDevice = [decoder decodeObjectForKey:@"theDevice"];
    self.color = [decoder decodeObjectForKey:@"color"];
    if (type == ir) [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceSubdevicesChanged:) name:IRDeviceCountChanged object:nil];
  }
  return self;
}

/*
 * Changes the device type. Allocs a new device and reinits all observers.
 */
-(void)changeDeviceType:(DeviceType)theType {
  // Remove all observers
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  type = theType;
  switch(theType) {
    case light:
      theDevice = [[Light alloc] init];
      break;
    case switchableSocket:
      theDevice = [[Socket alloc] init];
      break;
    case rcSwitch:
      theDevice = [[Switch alloc] init];
      break;
    case meter:
      theDevice = [[Meter alloc] init];
      break;
    case heating:
      theDevice = [[Heating alloc] init];
      break;
    case hoover:
      theDevice = [[Hoover alloc] init];
      break;
    case display:
      theDevice = [[Display alloc] init];
      break;
    case speaker:
      theDevice = [[Speaker alloc] init];
      break;
    case microphone:
      theDevice = [[Microphone alloc] init];
      break;
    case iPadDisplay:
      theDevice = [[IPadDisplay alloc] init];
      break;
    case coffee:
      theDevice = [[Coffee alloc] init];
      break;
    case ambilight:
      theDevice = [[Ambilight alloc] init];
      break;
    case ir:
      // Ir Devices need an observer for subdeviceChanges
      theDevice = [[InfraredDevice alloc] init];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceSubdevicesChanged:) name:IRDeviceCountChanged object:nil];
      break;
    case sensor:
      theDevice = [[Sensor alloc] init];
      break;
    default:
      [NSException raise:NSGenericException format:@"Unexpected MODE."];
      theDevice = nil;
  }
}

/*
 * If a subdevice changed, most of the voice commands and viewing stuff need to be redrawn
 */
- (void)deviceSubdevicesChanged:(NSNotification*)notification {
  if ([notification object] == theDevice) {
    if (DEBUG_IDEVICE) NSLog(@"SubdeviceChanged");
    // If the type is ir, all voice commands need to be reinited on subdevice change
    if (type == ir) [self initVoiceCommandsOfIR];
    // Post a notification that the iDevice changed
    [[NSNotificationCenter defaultCenter] postNotificationName:iDeviceDidChange object:self];
  }
}


/*
 * Return roomName from delegate
 */
- (NSString *)roomName {
  return [delegate getRoomName];
}

/*
 * Return if the device views can have different sizes.
 */
- (BOOL)deviceViewHasDifferentSize {
  // Only ir views have this atm
  if (type == ir) return true;
  return false;
}

- (BOOL)deviceTypeHasActions:(DeviceType) theType {
  BOOL result = false;
  switch(theType) {
    case light:
    case switchableSocket:
    case meter:
    case sensor:
    case heating:
    case hoover:
    case speaker:
    case coffee:
    case ambilight:
    case ir:
      result = true;
      break;
    default:
      result = false;
  }
  return result;
}

- (BOOL)deviceTypeHasSelectors:(DeviceType) theType {
  BOOL result = false;
  switch(theType) {
    case light:
    case switchableSocket:
    case meter:
    case sensor:
    case heating:
    case hoover:
    case speaker:
    case coffee:
    case ambilight:
    case ir:
      result = true;
      break;
    default:
      result = false;
  }
  return result;
}

/*
 * Returns the device view for the given type.
 */
- (NSViewController *)deviceView {
  switch(type) {
    case light: {
      return [[LightViewController alloc] initWithDevice:self];
      break;
    }
    case switchableSocket: {
      return [[SocketViewController alloc] initWithDevice:self];
      break;
    }
    case meter: {
      return [[MeterViewController alloc] initWithDevice:self];
      break;
    }
    case display: {
      return [[DisplayViewController alloc] initWithDevice:self];
      break;
    }
    case coffee: {
      return [[CoffeeViewController alloc] initWithDevice:self];
      break;
    }
    case sensor: {
      return [[SensorViewController alloc] initWithDevice:self];
      break;
    }
    case heating: {
      return [[HeatingViewController alloc] initWithDevice:self];
      break;
    }
    case hoover: {
      return [[HooverViewController alloc] initWithDevice:self];
      break;
    }
    case ir: {
      return [[InfraredDeviceViewController alloc] initWithDevice:self];
      break;
    }
    case microphone: {
      return [[MicrophoneViewController alloc] initWithDevice:self];
      break;
    }
    case iPadDisplay: {
      return [[IPadDisplayViewController alloc] initWithDevice:self];
      break;
    }
    case ambilight: {
      return [[AmbilightViewController alloc] initWithDevice:self];
      break;
    }
      // TODO: make rest work
    case speaker: {
      // return [[SpeakerViewController alloc] initWithDevice:self];
      break;
    }
      // Switch has no view
    case rcSwitch: {
      return [[SwitchViewController alloc] initWithDevice:self];
      break;
    }
    default:
      [NSException raise:NSGenericException format:@"Unexpected MODE."];
  }
  return nil;
}


/*
 * Returns the device edit view of the device.
 */
- (NSViewController *)deviceEditView {
  switch(type) {
    case light: {
      return [[EditLightViewController alloc] initWithLight:(Light *)theDevice];
      break;
    }
    case switchableSocket: {
      return [[EditSocketViewController alloc] initWithSocket:(Socket *)theDevice];
      break;
    }
    case rcSwitch: {
      return [[EditSwitchViewController alloc] initWithSwitch:(Switch *)theDevice];
      break;
    }
    case meter: {
      return [[EditMeterViewController alloc] initWithMeter:(Meter *)theDevice];
      break;
    }
    case display: {
      return [[EditDisplayViewController alloc] initWithDisplay:(Display *)theDevice];
      break;
    }
    case coffee: {
      return [[EditCoffeeViewController alloc] initWithCoffee:(Coffee *)theDevice];
      break;
    }
    case sensor: {
      return [[EditSensorViewController alloc] initWithSensor:(Sensor *)theDevice];
      break;
    }
    case heating: {
      return [[EditHeatingViewController alloc] initWithHeating:(Heating *)theDevice];
      break;
    }
    case hoover: {
      return [[EditHooverViewController alloc] initWithHoover:(Hoover *)theDevice];
      break;
    }
    case speaker: {
      return [[EditSpeakerViewController alloc] initWithSpeaker:(Speaker *)theDevice];
      break;
    }
    case microphone: {
      return [[EditMicrophoneViewController alloc] initWithMicrophone:(Microphone *)theDevice];
      break;
    }
    case iPadDisplay: {
      return [[EditIPadDisplayViewController alloc] initWithIPadDisplay:(IPadDisplay *)theDevice];
      break;
    }
    case ambilight: {
      return [[EditAmbilightViewController alloc] initWithAmbilight:(Ambilight *)theDevice];
      break;
    }
    case ir: {
      return [[EditInfraredDeviceViewController alloc] initWithInfraredDevice:(InfraredDevice *)theDevice];
      break;
    }
    default:
      [NSException raise:NSGenericException format:@"Unexpected MODE."];
  }
  return nil;
}


/*
 * Return string with readable name for the given device type
 */
- (NSString*)DeviceTypeToString:(DeviceType) theType{
  NSString *result = nil;
  switch(theType) {
    case light:
      result = @"Light";
      break;
    case switchableSocket:
      result = @"Socket";
      break;
    case rcSwitch:
      result = @"Switch";
      break;
    case meter:
      result = @"Meter";
      break;
    case sensor:
      result = @"Sensor";
      break;
    case heating:
      result = @"Heating";
      break;
    case hoover:
      result = @"Hoover";
      break;
    case display:
      result = @"Display";
      break;
    case speaker:
      result = @"Speaker";
      break;
    case microphone:
      result = @"Microphone";
      break;
    case iPadDisplay:
      result = @"Touch Display";
      break;
    case coffee:
      result = @"Coffee Machine";
      break;
    case ambilight:
      result = @"Ambilight Remote";
      break;
    case ir:
      result = @"Infrared Remote";
      break;
    case differentDeviceCount:
      result = @"Total number of different devices";
      break;
    default:
      [NSException raise:NSGenericException format:@"Unexpected MODE."];
  }
  return result;
}


#pragma mark voice command functions

/*
 * Returns the standard voice commands of the iDevice if there is any.
 */
-(NSArray *)standardVoiceCommands {
  NSArray *voiceCommandArray = [[NSArray alloc] init];
  // If the device has some standard voice commands init them here
  if ([theDevice respondsToSelector:@selector(standardVoiceCommands)]) {
    voiceCommandArray = [theDevice performSelector:@selector(standardVoiceCommands) withObject:nil];
  }
  
  // Set the handler to us and the roomName to our room for every command
  for (VoiceCommand* theVoiceCommand in voiceCommandArray) {
    if (![theVoiceCommand handler]) [theVoiceCommand setHandler:self];
    for (Room *theRoom in [[House sharedHouse] rooms]) {
      if ([[theRoom name] isEqualToString:[self roomName]]) {
        [theVoiceCommand setRoom:theRoom];
      }
    }
    
    // Add the name and the command at the end: e.g. Headlight on
    if (type == light || type == switchableSocket || type == ir) {
      [theVoiceCommand setName:[NSString stringWithFormat:@"%@ %@", name, [theVoiceCommand name]]];
      [theVoiceCommand setCommand:[NSString stringWithFormat:@"%@ %@", name, [theVoiceCommand command]]];
    }
    // Add the command and the name at the end: e.g. Energyconsumption of Headlight
    else if (type == meter) {
      [theVoiceCommand setName:[NSString stringWithFormat:@"%@ %@", [theVoiceCommand name], name]];
      [theVoiceCommand setCommand:[NSString stringWithFormat:@"%@ %@", [theVoiceCommand command], name]];
    }
    // Add the command and the roomname at the end: e.g. Temperature in TestRoom
    else if (type == sensor || type == heating) {
      [theVoiceCommand setName:[NSString stringWithFormat:@"%@ %@", [theVoiceCommand name], [self roomName]]];
      [theVoiceCommand setCommand:[NSString stringWithFormat:@"%@ %@", [theVoiceCommand command], [self roomName]]];
    }
  }
  return voiceCommandArray;
}

/*
 * Returns the available voice command selectors e.g. "toggle:".
 */
- (NSArray *)voiceCommandSelectors {
  NSArray *selectors = [[NSArray alloc] init];
  // Get the selectors from the device if there are any
  if ([theDevice respondsToSelector:@selector(selectors)]) {
    selectors = [theDevice performSelector:@selector(selectors)];
  }
  return selectors;
}

/*
 * Returns the availabe voice command selectors understandable e.g. "toggle the device".
 */
- (NSArray *)voiceCommandSelectorsReadable {
  NSArray *selectors = [[NSArray alloc] init];
  // Get the readable selectors from the device if there are any
  if ([theDevice respondsToSelector:@selector(readableSelectors)]) {
    selectors = [theDevice performSelector:@selector(readableSelectors)];
  }
  return selectors;
}

/*
 * Executes a given selector on the device.
 */
-(NSDictionary*)executeSelector:(NSString *)selector {
  // Look for selector delimiter
  NSRange range = [selector rangeOfString:@":"];
  // If a delimiter is found, the selector has an object attached as string
  if (range.location != NSNotFound) {
    // Get the real selector and the object
    NSString *realSelector = [selector substringToIndex:range.location + range.length];
    NSString *object = @"";
    if ([selector length] > range.length + range.location) {
      object = [selector substringFromIndex:range.location + range.length];
    }
    if (DEBUG_IDEVICE) NSLog(@"Selector: %@, Object: %@", realSelector, object);
    // If the Device does not respond to the selector, return error
    if (![theDevice respondsToSelector:NSSelectorFromString(realSelector)]) {
      return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:false], KeyVoiceCommandExecutedSuccessfully, nil];
    }
    // If the device responds to selector, perform it and store result in dictionary and return it
    NSDictionary *result = [theDevice performSelector:NSSelectorFromString(realSelector) withObject:object];
    if (DEBUG_IDEVICE) NSLog(@"selector %@ exists, executed with result: %@", realSelector, result);
    return result;
  }
  // No object is attached
  // If the Device does not respond to the selector, return error
  if (![theDevice respondsToSelector:NSSelectorFromString(selector)]) {
    return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:false], KeyVoiceCommandExecutedSuccessfully, nil];
  }
  // If the device responds to selector, perform it and store result in dictionary and return it
  NSDictionary *result = [theDevice performSelector:NSSelectorFromString(selector) withObject:nil];
  if (DEBUG) NSLog(@"selector %@ exists, executed with result: %@", selector, result);
  return result;
}


#pragma mark ir functions

/*
 * Reinits the voice commands of infrared commands
 */
-(void)initVoiceCommandsOfIR {
  if (DEBUG_IDEVICE) NSLog(@"Reinit all IR Voice commands");
  // Get the house object
  House *theHouse = [House sharedHouse];
  // Go through all available voice commands
  for (VoiceCommand *theCommand in [theHouse voiceCommands]) {
    // If this iDevice is the handler of the command remove it
    if ([[theCommand handler] isEqual:self]) {
      [theHouse removeVoiceCommand:[theCommand name] :self];
    }
  }
  // Go through every ir command of the infrared device
  for (InfraredCommand *theIRCommand in [(InfraredDevice *)theDevice infraredCommands]) {
    // If the ir command is not a dummy element add it as a voice command
    if (![[theIRCommand name] isEqualToString:IRCommandEmptyCommand]) {
      VoiceCommand *theVoiceCommand = [[VoiceCommand alloc] init];
      [theVoiceCommand setName:[NSString stringWithFormat:@"%@ %@",name, [theIRCommand name]]];
      [theVoiceCommand setCommand:[NSString stringWithFormat:@"%@ %@",name, [theIRCommand name]]];
      [theVoiceCommand setHandler:self];
      [theVoiceCommand setSelector:[NSString stringWithFormat:@"%@%@", IRDeviceSelectorToggle, [theIRCommand name]]];
      [theHouse addVoiceCommand:theVoiceCommand :self];
    }
  }
}


@end
