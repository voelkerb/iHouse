//
//  Device.h
//  LivingHome0.2
//
//  Created by Benjamin Völker on 5/9/14.
//  Copyright (c) 2014 Benny Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Light.h"
#import "LightViewController.h"
#import "EditLightViewController.h"
#import "Socket.h"
#import "SocketViewController.h"
#import "EditSocketViewController.h"
#import "Meter.h"
#import "MeterViewController.h"
#import "EditMeterViewController.h"
#import "Heating.h"
#import "HeatingViewController.h"
#import "EditHeatingViewController.h"
#import "Hoover.h"
#import "HooverViewController.h"
#import "EditHooverViewController.h"
#import "Display.h"
#import "DisplayViewController.h"
#import "EditDisplayViewController.h"
#import "Speaker.h"
#import "SpeakerViewController.h"
#import "EditSpeakerViewController.h"
#import "Microphone.h"
#import "MicrophoneViewController.h"
#import "EditMicrophoneViewController.h"
#import "TV.h"
#import "TVViewController.h"
#import "EditTVViewController.h"
#import "Coffee.h"
#import "CoffeeViewController.h"
#import "EditCoffeeViewController.h"
#import "InfraredDevice.h"
#import "InfraredDeviceViewController.h"
#import "EditInfraredDeviceViewController.h"


// The Functions the delegate has to implement
@protocol DeviceDelegate <NSObject>

// The delegate needs to change something
- (NSString*)getRoomName;

@end


// The different possible devices as an ENUM
typedef NS_ENUM(NSUInteger, DeviceType) {
  light,
  switchableSocket,
  // Stops here
  differentDeviceCount,
  meter,
  heating,
  hoover,
  display,
  speaker,
  microphone,
  tv,
  coffee,
  ir
};


@interface Device : NSObject <NSCoding>

// The delegate variable
@property (weak) id<DeviceDelegate> delegate;

// The name of the device
@property (strong) NSString *name;
// The color of the device
@property (strong) NSColor *color;
// The image of the device
@property (strong) NSImage* image;
// The device type (see enums from above)
@property DeviceType type;
// The device object
@property (strong) NSObject *theDevice;


- (id)initWithDeviceType:(DeviceType) theType;

// Returns the device type as a string
- (void)changeDeviceType:(DeviceType) theType;

// Returns the View of the Device
- (NSView*)deviceView;

// Returns the View of the Device
- (NSView*)deviceEditView;

// Returns the device type as a string
- (NSString*)roomName;

// Returns the device type as a string
- (NSString*)DeviceTypeToString:(DeviceType) theType;



@end
