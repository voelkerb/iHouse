//
//  SensorViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 16/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Sensor.h"
#import "DragDropImageView.h"
#import "PlotViewController.h"
#import "mbFliperViews.h"

@class IDevice;

@interface SensorViewController : NSViewController<NSCopying> {
  NSView *mAnimationView;
  NSView *mTargetView;
  mbFliperViews *fliper;
}

// The pointer to the device
@property (strong) IDevice *iDevice;

// A controlling object for the Plot
@property (strong) PlotViewController *plotViewController;

// The image of the sensor
@property (weak) IBOutlet DragDropImageView *sensorImage;
// The name of the sensor
@property (weak) IBOutlet NSTextField *sensorName;
// The backview wit the color of the device
@property (weak) IBOutlet NSView *backView;
@property (weak) IBOutlet NSView *backView2;
// The time of last update
@property (weak) IBOutlet NSTextField *lastUpdateLabel;
// The ID of the sensor
@property (weak) IBOutlet NSTextField *idLabel;
// The temperature of the sensor
@property (weak) IBOutlet NSTextField *tempLabel;
// The brightness of the sensor
@property (weak) IBOutlet NSTextField *brightnessLabel;
// The pressure of the sensor
@property (weak) IBOutlet NSTextField *pressureLabel;
// The humidity of the sensor
@property (weak) IBOutlet NSTextField *humidityLabel;
// The movement detection of the sensor
@property (weak) IBOutlet NSTextField *movementLabel;
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


// The device needs to be initiated with an idevice
- (id) initWithDevice:(IDevice *) theSensorDevice;



// The value of the value popup changed
- (IBAction)valuePopupChanged:(id)sender;
// The value of the time popup changed
- (IBAction)timePopupChanged:(id)sender;
// The user wants to flip to the back side (plot side)
- (IBAction)flipView:(id)sender;
// The user wants to flip to the front side
- (IBAction)flipBack:(id)sender;

@end
