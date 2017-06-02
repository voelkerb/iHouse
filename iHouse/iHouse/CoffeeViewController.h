//
//  CoffeeViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Coffee.h"
@class IDevice;

@interface CoffeeViewController : NSViewController<NSCopying>

// The device
@property (strong) IDevice *iDevice;

// The Image of the display
@property (weak) IBOutlet NSImageView *coffeeImage;
// The name of the display
@property (weak) IBOutlet NSTextField *nameLabel;
// The backview of the view in the color of the device
@property (weak) IBOutlet NSView *backView;

// If the coffee should be made with or without a cup
@property (weak) IBOutlet NSButton *withCupCheckBox;
// Button to toggle the machine on/off
@property (weak) IBOutlet NSButton *onOffButton;
// What kind of beverage should be made
@property (weak) IBOutlet NSPopUpButton *beveragePopUp;
// Some status messages of the machine
@property (weak) IBOutlet NSTextField *statusMsgLabel;
// The aroma slider 0-6
@property (weak) IBOutlet NSSlider *aromaSlider;
// The brightness slider 0-10
@property (weak) IBOutlet NSSlider *brightnessSlider;

- (id) initWithDevice:(IDevice*) theCoffeeDevice;
// Make the selected beverage
- (IBAction)makeBeverage:(id)sender;
// Changes the aroma
- (IBAction)changeAroma:(id)sender;
// Changes the display brightness
- (IBAction)changeBrightness:(id)sender;
// Make a factory reset
- (IBAction)factoryReset:(id)sender;
// Toggles the Machine on or off 
- (IBAction)toggleMachineOnOff:(id)sender;

@end
