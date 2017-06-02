//
//  AmbilightViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 06.03.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Ambilight.h"
#import "OnOffSwitchControl.h"
#import "DragDropImageView.h"

@class IDevice;
@interface AmbilightViewController : NSViewController

// The pointer to the device
@property (strong) IDevice *iDevice;

// The image of the ambilight
@property (weak) IBOutlet DragDropImageView *ambilightImage;
// The name of the ambilight
@property (weak) IBOutlet NSTextField *ambilightName;
// The backview with the bg color
@property (weak) IBOutlet NSView *backView;
@property (weak) IBOutlet NSSlider *brightnesSlider;

// This controller needs to be initiated with a ambilight device
- (id) initWithDevice:(IDevice*) theAmbilightDevice;

- (IBAction) openColorPicker:(id)sender;
- (IBAction) fadePressed:(id)sender;
- (IBAction) blackPressed:(id)sender;
- (IBAction) ambilightPressed:(id)sender;
- (IBAction)brightnessChanged:(id)sender;

@end
