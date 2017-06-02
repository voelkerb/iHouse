//
//  Device.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 05/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>


@interface Device : NSObject<NSCoding>
// The different possible devices as an ENUM
typedef NS_ENUM(NSUInteger, DeviceType) {
  light,
  switchableSocket,
  meter,
  display,
  coffee,
  sensor,
  heating,
  hoover,
  ir,
  microphone,
  // Stops here
  differentDeviceCount,
  iPadDisplay,
  speaker
};


@property (strong) NSString *name;
@property (strong) UIImage *image;
@property (strong) NSMutableDictionary *info;
@property DeviceType type;

- (NSString*)deviceTypeToString;
- (NSString*)DeviceTypeToString:(DeviceType) theType;

@end
