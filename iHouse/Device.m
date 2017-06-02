//
//  Device.m
//  LivingHome0.2
//
//  Created by Benjamin Völker on 5/9/14.
//  Copyright (c) 2014 Benny Völker. All rights reserved.
//

#import "Device.h"
// The default device picture
#define DEFAULT_DEVICE_IMAGE_NAME @"devices_256.png"

@implementation Device
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

-(void)changeDeviceType:(DeviceType)theType {
  switch(theType) {
    case light:
      theDevice = [[Light alloc] init];
      break;
    case switchableSocket:
      theDevice = [[Socket alloc] init];
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
    case tv:
      theDevice = [[TV alloc] init];
      break;
    case coffee:
      theDevice = [[Coffee alloc] init];
      break;
    case ir:
      theDevice = [[InfraredDevice alloc] init];
      break;
    default:
      [NSException raise:NSGenericException format:@"Unexpected MODE."];
      theDevice = nil;
  }
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
  }
  return self;
}

// Return roomName from delegate
- (NSString *)roomName {
  return [delegate getRoomName];
}

- (NSView *)deviceView {
  NSView *theView = [[NSView alloc] init];
  switch(type) {
    case light: {
      LightViewController *lightView = [[LightViewController alloc] initWithDevice:self];
      theView = lightView.view;
      break;
    }
    case switchableSocket: {
      SocketViewController *socketView = [[SocketViewController alloc] initWithSocket:(Socket *)theDevice];
      theView = socketView.view;
      break;
    }
    case meter: {
      MeterViewController *socketView = [[MeterViewController alloc] initWithMeter:(Meter *)theDevice];
      theView = socketView.view;
      break;
    }
    case heating: {
      MeterViewController *socketView = [[MeterViewController alloc] initWithMeter:(Meter *)theDevice];
      theView = socketView.view;
      break;
    }
    case hoover: {
      HooverViewController *socketView = [[HooverViewController alloc] initWithHoover:(Hoover *)theDevice];
      theView = socketView.view;
      break;
    }
    case display: {
      DisplayViewController *socketView = [[DisplayViewController alloc] initWithDisplay:(Display *)theDevice];
      theView = socketView.view;
      break;
    }
    case speaker: {
      SpeakerViewController *socketView = [[SpeakerViewController alloc] initWithSpeaker:(Speaker *)theDevice];
      theView = socketView.view;
      break;
    }
    case microphone: {
      MicrophoneViewController *socketView = [[MicrophoneViewController alloc] initWithMicrophone:(Microphone *)theDevice];
      theView = socketView.view;
      break;
    }
    case tv: {
      TVViewController *socketView = [[TVViewController alloc] initWithTV:(TV *)theDevice];
      theView = socketView.view;
      break;
    }
    case coffee: {
      CoffeeViewController *socketView = [[CoffeeViewController alloc] initWithCoffee:(Coffee *)theDevice];
      theView = socketView.view;
      break;
    }
    case ir: {
      InfraredDeviceViewController *socketView = [[InfraredDeviceViewController alloc] initWithInfraredDevice:(InfraredDevice *)theDevice];
      theView = socketView.view;
      break;
    }
    default:
      [NSException raise:NSGenericException format:@"Unexpected MODE."];
  }
  return theView;
}


- (NSView *)deviceEditView {
  NSView *theView = [[NSView alloc] init];
  switch(type) {
    case light: {
      EditLightViewController *lightView = [[EditLightViewController alloc] initWithLight:(Light *)theDevice];
      theView = lightView.view;
      break;
    }
    case switchableSocket: {
      EditSocketViewController *socketView = [[EditSocketViewController alloc] initWithSocket:(Socket *)theDevice];
      theView = socketView.view;
      break;
    }
    case meter: {
      EditMeterViewController *socketView = [[EditMeterViewController alloc] initWithMeter:(Meter *)theDevice];
      theView = socketView.view;
      break;
    }
    case heating: {
      EditMeterViewController *socketView = [[EditMeterViewController alloc] initWithMeter:(Meter *)theDevice];
      theView = socketView.view;
      break;
    }
    case hoover: {
      EditHooverViewController *socketView = [[EditHooverViewController alloc] initWithHoover:(Hoover *)theDevice];
      theView = socketView.view;
      break;
    }
    case display: {
      EditDisplayViewController *socketView = [[EditDisplayViewController alloc] initWithDisplay:(Display *)theDevice];
      theView = socketView.view;
      break;
    }
    case speaker: {
      EditSpeakerViewController *socketView = [[EditSpeakerViewController alloc] initWithSpeaker:(Speaker *)theDevice];
      theView = socketView.view;
      break;
    }
    case microphone: {
      EditMicrophoneViewController *socketView = [[EditMicrophoneViewController alloc] initWithMicrophone:(Microphone *)theDevice];
      theView = socketView.view;
      break;
    }
    case tv: {
      EditTVViewController *socketView = [[EditTVViewController alloc] initWithTV:(TV *)theDevice];
      theView = socketView.view;
      break;
    }
    case coffee: {
      EditCoffeeViewController *socketView = [[EditCoffeeViewController alloc] initWithCoffee:(Coffee *)theDevice];
      theView = socketView.view;
      break;
    }
    case ir: {
      EditInfraredDeviceViewController *socketView = [[EditInfraredDeviceViewController alloc] initWithInfraredDevice:(InfraredDevice *)theDevice];
      theView = socketView.view;
      break;
    }
    default:
      [NSException raise:NSGenericException format:@"Unexpected MODE."];
  }
  return theView;
}

// Return string from enum
- (NSString*)DeviceTypeToString:(DeviceType) theType{
  NSString *result = nil;
  switch(theType) {
    case light:
      result = @"Light";
      break;
    case switchableSocket:
      result = @"Socket";
      break;
    case meter:
      result = @"Meter";
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
    case tv:
      result = @"TV";
      break;
    case coffee:
      result = @"Coffee Maschine";
      break;
    case ir:
      result = @"Infrared controllabe device";
      break;
    case differentDeviceCount:
      result = @"Total number of different devices";
      break;
    default:
      [NSException raise:NSGenericException format:@"Unexpected MODE."];
  }
  return result;
}
@end
