//
//  MeterViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Meter.h"
#import "PlotViewController.h"
#import "mbFliperViews.h"


@class IDevice;

@interface MeterViewController : NSViewController<NSCopying> {
  NSView *mAnimationView;
  NSView *mTargetView;
  mbFliperViews *fliper;
}

// The pointer to the device
@property (strong) IDevice *iDevice;

// A controlling object for the Plot
@property (strong) PlotViewController *plotViewController;

// The image of the meter
@property (weak) IBOutlet NSImageView *meterImage;
// The name of the meter
@property (weak) IBOutlet NSTextField *meterName;
// The backview with the bg color
@property (weak) IBOutlet NSView *backView;
@property (weak) IBOutlet NSView *backView2;
// The time of last update
@property (weak) IBOutlet NSTextField *lastUpdateLabel;
// The ID of the meter
@property (weak) IBOutlet NSTextField *idLabel;
// The voltage of the meter
@property (weak) IBOutlet NSTextField *voltageLabel;
// The current of the meter
@property (weak) IBOutlet NSTextField *currentLabel;
// The power of the meter
@property (weak) IBOutlet NSTextField *powerLabel;
// The avg power of the meter
@property (weak) IBOutlet NSTextField *avgPowerLabel;
// The energy of the meter
@property (weak) IBOutlet NSTextField *energyLabel;
// A popup for changing the time of the plot
@property (weak) IBOutlet NSPopUpButton *timePopUp;
// A popup for changing the value of the plot
@property (weak) IBOutlet NSPopUpButton *valuePopUp;
// The side on which the plot is viewed
@property (strong) IBOutlet NSView *plotSideView;
// The side on which the labels are displayed (litterally the front)
@property (strong) IBOutlet NSView *frontView;
// The plot view
@property (weak) IBOutlet NSView *plotView;

// This controller needs to be initiated with a meter device
- (id) initWithDevice:(IDevice*) theMeterDevice;

// The value of the value popup changed
- (IBAction)valuePopupChanged:(id)sender;
// The value of the time popup changed
- (IBAction)timePopupChanged:(id)sender;
// The user wants to flip to the back side (plot side)
- (IBAction)flipView:(id)sender;
// The user wants to flip to the front side
- (IBAction)flipBack:(id)sender;


@end