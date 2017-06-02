//
//  Device.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 05/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "Device.h"

@implementation Device

@synthesize image, name, type, info;

/*
 * Init function
 */
- (id)init {
  if((self = [super init])) {
    image = [UIImage imageNamed:@"devices_256"];
    name = [[NSString alloc] initWithFormat:@"New Device"];
    type = light;
    info = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  //Encode properties, other class variables, etc
  [encoder encodeObject:self.image forKey:@"image"];
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeInteger:self.type forKey:@"type"];
  [encoder encodeObject:self.info forKey:@"info"];
}

- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    //decode properties, other class vars
    self.image = [decoder decodeObjectForKey:@"image"];
    self.name = [decoder decodeObjectForKey:@"name"];
    self.type = [decoder decodeIntegerForKey:@"type"];
    self.info = [decoder decodeObjectForKey:@"info"];
  }
  return self;
}

/*
 * Return string with readable name for the given device type
 */

- (NSString*)deviceTypeToString {
  return [self DeviceTypeToString:self.type];
}

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


@end
