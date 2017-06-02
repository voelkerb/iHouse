//
//  HooverViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "Hoover.h"

@class IDevice;
@interface HooverViewController : NSViewController<NSCopying>

// The pointer to the device
@property (strong) IDevice *iDevice;

// The image of the device
@property (weak) IBOutlet NSImageView *deviceImage;
// The name of the device
@property (weak) IBOutlet NSTextField *deviceName;
// The backview with the color of the device
@property (weak) IBOutlet NSView *backView;
// The start stop button
@property (weak) IBOutlet NSButton *startStopButton;
// The speed slider
@property (weak) IBOutlet NSSlider *speedSlider;
// The driving buttons just for fun
@property (weak) IBOutlet NSButton *leftButton;
@property (weak) IBOutlet NSButton *rightButton;
@property (weak) IBOutlet NSButton *backwardButton;
@property (weak) IBOutlet NSButton *forwardButton;

// The device needs to be initiated with an idevice
- (id) initWithDevice:(IDevice *) theDevice;

// Called if the start/stop cleaning button is pressed
- (IBAction)startStopCleaning:(id)sender;

// Called if the user presses the dock button
- (IBAction)goHome:(id)sender;
- (IBAction)leftPressed:(id)sender;
- (IBAction)rightPressed:(id)sender;
- (IBAction)forwardPressed:(id)sender;
- (IBAction)backwardPressed:(id)sender;

@end