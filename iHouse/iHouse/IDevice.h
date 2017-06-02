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
#import "Switch.h"
#import "EditSwitchViewController.h"
#import "SwitchViewController.h"
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
#import "IPadDisplay.h"
#import "IPadDisplayViewController.h"
#import "EditIPadDisplayViewController.h"
#import "Coffee.h"
#import "CoffeeViewController.h"
#import "EditCoffeeViewController.h"
#import "InfraredDevice.h"
#import "InfraredDeviceViewController.h"
#import "EditInfraredDeviceViewController.h"
#import "Sensor.h"
#import "SensorViewController.h"
#import "EditSensorViewController.h"
#import "Ambilight.h"
#import "AmbilightViewController.h"
#import "EditAmbilightViewController.h"

// The different possible devices as an ENUM
// Beware, if you add additional dfevices always put them at the end of this enum
// if you want to be able to use previous stored iHouse file
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
  rcSwitch,
  ambilight,
  // Stops here
  differentDeviceCount,
  iPadDisplay,
  speaker
};

// Key for dictionary
extern NSString * const iDeviceTileView;
// If the device name or image changed a notification with this name is posted
extern NSString * const iDeviceDidChange;

// The Functions the delegate has to implement
@protocol IDeviceDelegate <NSObject>

// The delegate needs to change something
- (NSString*)getRoomName;

@end



@interface IDevice : NSObject <NSCoding>

// The delegate variable
@property (weak) id<IDeviceDelegate> delegate;

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

// Returns if the device type can have selectors
- (BOOL)deviceTypeHasSelectors:(DeviceType) theType;

// Returns if the device type can perform action
- (BOOL)deviceTypeHasActions:(DeviceType) theType;

// Returns if the deviceViews of the devicekind can have different heights
- (BOOL)deviceViewHasDifferentSize;

// Returns the View of the Device
- (NSViewController*)deviceView;

// Returns the View of the Device
- (NSViewController*)deviceEditView;

// Returns the device type as a string
- (NSString*)roomName;

// Returns the device type as a string
- (NSString*)DeviceTypeToString:(DeviceType) theType;

#pragma mark voice command stuff
// Returns the standard voice commands of the iDevice if it has any
- (NSArray*)standardVoiceCommands;

// Returns the available voice command selectors e.g. "toggle:"
- (NSArray*)voiceCommandSelectors;

// Returns the availabe voice command selectors understandable e.g. "toggle the device"
- (NSArray*)voiceCommandSelectorsReadable;

// Executes the given selector on the device if exist and returns their responses
- (NSDictionary*)executeSelector:(NSString*)selector;
@end
