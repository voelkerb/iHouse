//
//  HeatingViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "HeatingViewController.h"
#import "IDevice.h"
#import "IDevice.h"

#define DEBUG_HEATING true

#define TEMPERATURE_UNIT_STRING @" °C"

#define SETTINGS_BUTTON_RESET @"Reset"
#define SETTINGS_BUTTON_ADA @"Start Adaptation"
#define SETTINGS_BUTTON_LOCK @"Lock"
#define SETTINGS_BUTTON_OK @"Ok"
#define SETTINGS_MESSAGE @"Advanced Preferences"

#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NO_CONNECTION_MESSAGE @"Heating device not connected"
#define ALERT_NO_CONNECTION_MESSAGE_INFORMAL @"Connect an iHouse heating device to enable this feature."

@interface HeatingViewController ()

@end

@implementation HeatingViewController
@synthesize iDevice, heatingImage, heatingName, tempLabel, tempSlider, backView, lockButton, adaButton, resetButton;

/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  HeatingViewController *copy = [[HeatingViewController allocWithZone: zone] initWithDevice:iDevice];
  return copy;
}

-(id)initWithDevice:(IDevice *)theHeatingDevice {
  self = [super init];
  if (self && (theHeatingDevice.type == heating)) {
    iDevice = theHeatingDevice;
    // Add observer for Temp changed on the device
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tempChanged:) name:HeatingTempDidChange object:nil];
    // Add observer for device edit change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:iDeviceDidChange object:nil];
  }
  return self;
}

// If the device was dedited, we need to redraw
-(void)reDraw:(NSNotification*)notification {
  if ([iDevice isEqualTo:[notification object]]) {
    [self viewDidLoad];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do view setup here.

  // Set name and image of the idevice
  [heatingName setStringValue:[iDevice name]];
  [heatingImage setImage:[iDevice image]];
  [heatingImage setAllowDrag:false];
  [heatingImage setAllowDrop:false];
  
  // Init the slider
  [tempSlider setMinValue:HEATING_MIN_TEMP];
  [tempSlider setMaxValue:HEATING_MAX_TEMP];
  [tempSlider setNumberOfTickMarks:(HEATING_MAX_TEMP - HEATING_MIN_TEMP)*2+1];
  [tempSlider setAllowsTickMarkValuesOnly:YES];
  [tempSlider setContinuous:YES];
  [tempSlider setFloatValue:[[(Heating*)[iDevice theDevice] currentTemperature] floatValue]];
  // Set the temp label
  [tempLabel setStringValue:[NSString stringWithFormat:@"%.1f%@", [tempSlider floatValue], TEMPERATURE_UNIT_STRING]];
  
  // Set the background color accordingly
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[[iDevice color] CGColor]];
  [backView setWantsLayer:YES];
  [backView setLayer:viewLayer];
}


/*
 * If the user changed the temperature on the device itself
 */
-(void)tempChanged:(NSNotification*)notification {
  // Update slider and temp label if the device was us
  if ([[notification object] isEqualTo:[iDevice theDevice]]) {
    [tempSlider setFloatValue:[[(Heating*)[iDevice theDevice] currentTemperature] floatValue]];
    [tempLabel setStringValue:[NSString stringWithFormat:@"%.1f%@", [tempSlider floatValue], TEMPERATURE_UNIT_STRING]];
  }
}

/*
 * Called if the user changed the temperature slider.
 */
- (IBAction)tempSliderChanged:(id)sender {
  [tempLabel setStringValue:[NSString stringWithFormat:@"%.1f%@", [tempSlider floatValue], TEMPERATURE_UNIT_STRING]];
  NSEvent *currentEvent = [[sender window] currentEvent];
  if ([currentEvent type] == NSLeftMouseUp) {
    // the slider was let go
    if ([self checkConnected]) {
      [(Heating*)[iDevice theDevice] setTemp:[NSNumber numberWithFloat:[tempSlider floatValue]]];
    } else {
      [tempSlider setIntegerValue:[[(Heating*)[iDevice theDevice] currentTemperature] floatValue]];
      [tempLabel setStringValue:[NSString stringWithFormat:@"%.1f%@", [tempSlider floatValue], TEMPERATURE_UNIT_STRING]];
    }
  }
}

/*
 * Called if the user presses the boost button
 */
- (IBAction)boostPressed:(id)sender {
  if (DEBUG_HEATING) NSLog(@"Boost pressed");
  if ([self checkConnected]) [(Heating*)[iDevice theDevice] boost];
}

- (IBAction)settingsPressed:(id)sender {
  if ([self checkConnected]) [self showEditSettingsAlert];
}

/*
 * Show an alert for advanced settings of the heating device.
 */
-(void)showEditSettingsAlert {
  // The accessory view of the alert sheet
  NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
  // Init the three buttons in this alert
  resetButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 80, 24)];
  [resetButton setTitle:SETTINGS_BUTTON_RESET];
  [resetButton setButtonType:NSMomentaryLightButton];
  [resetButton setBezelStyle:NSRoundedBezelStyle];
  [resetButton setTarget:self];
  [resetButton setAction:@selector(resetClicked:)];
  adaButton = [[NSButton alloc] initWithFrame:NSMakeRect(80, 0, 140, 24)];
  [adaButton setTitle:SETTINGS_BUTTON_ADA];
  [adaButton setButtonType:NSMomentaryLightButton];
  [adaButton setBezelStyle:NSRoundedBezelStyle];
  [adaButton setTarget:self];
  [adaButton setAction:@selector(adaClicked:)];
  lockButton = [[NSButton alloc] initWithFrame:NSMakeRect(220, 0, 80, 24)];
  [lockButton setTitle:SETTINGS_BUTTON_LOCK];
  [lockButton setButtonType:NSMomentaryLightButton];
  [lockButton setBezelStyle:NSRoundedBezelStyle];
  [lockButton setTarget:self];
  [lockButton setAction:@selector(lockClicked:)];
  NSArray *array = [NSArray arrayWithObjects:resetButton, adaButton, lockButton, nil];
  [view setSubviews:array];
  
  // Init the alert sheet with buttons, text and accessory view
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:SETTINGS_MESSAGE];
  [alert addButtonWithTitle:SETTINGS_BUTTON_OK];
  [alert setAccessoryView:view];
  [alert runModal];
}

/*
 * If reset was clicked.
 */
- (void)resetClicked:(id)sender {
  if (DEBUG_HEATING) NSLog(@"Reset pressed");
  if ([self checkConnected]) [(Heating*)[iDevice theDevice] reset];
}

/*
 * If ada was clicked.
 */
- (void)adaClicked:(id)sender {
  if (DEBUG_HEATING) NSLog(@"Ada pressed");
  if ([self checkConnected]) [(Heating*)[iDevice theDevice] ada];
}

/*
 * If lock was clicked.
 */
- (void)lockClicked:(id)sender {
  if (DEBUG_HEATING) NSLog(@"Lock pressed");
  if ([self checkConnected]) [(Heating*)[iDevice theDevice] lock];
}

/*
 * Checks if the Heating is connected over tcp.
 */
- (BOOL)checkConnected {
  if ([(Heating*)[iDevice theDevice] isConnected]) return true;
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:ALERT_BUTTON_OK];
  [alert setMessageText:ALERT_NO_CONNECTION_MESSAGE];
  [alert setInformativeText:ALERT_NO_CONNECTION_MESSAGE_INFORMAL];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
  return false;
}

@end
