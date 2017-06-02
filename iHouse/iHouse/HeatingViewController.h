//
//  HeatingViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Heating.h"
#import "DragDropImageView.h"

@class IDevice;
@interface HeatingViewController : NSViewController<NSCopying>

// The pointer to the device
@property (strong) IDevice *iDevice;

// The image of the heating
@property (weak) IBOutlet DragDropImageView *heatingImage;
// The name of the heating
@property (weak) IBOutlet NSTextField *heatingName;
// The backview with the color of the device
@property (weak) IBOutlet NSView *backView;
// The temperature slider
@property (weak) IBOutlet NSSlider *tempSlider;
// The label displaying the temperature set on the slider
@property (weak) IBOutlet NSTextField *tempLabel;
// Lock pressed
@property (strong) NSButton *lockButton;
// ADA pressed
@property (strong) NSButton *adaButton;
// Reset pressed
@property (strong) NSButton *resetButton;

// The device needs to be initiated with an idevice
- (id) initWithDevice:(IDevice *) theHeatingDevice;
// Called if the temperature slider changed
- (IBAction)tempSliderChanged:(id)sender;
// Called if the user presses the boost button
- (IBAction)boostPressed:(id)sender;
- (IBAction)settingsPressed:(id)sender;

@end
