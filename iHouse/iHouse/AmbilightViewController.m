//
//  AmbilightViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 06.03.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "AmbilightViewController.h"
#import "IDevice.h"


#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NO_CONNECTION_MESSAGE @"Ambilight App not opened"
#define ALERT_NO_CONNECTION_MESSAGE_INFORMAL @"Open the iHouse ambilight application to control it from here."

@interface AmbilightViewController ()

@end

@implementation AmbilightViewController
@synthesize ambilightImage, ambilightName, iDevice, backView, brightnesSlider;

/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  AmbilightViewController *copy = [[AmbilightViewController allocWithZone: zone] initWithDevice:iDevice];
  return copy;
}

- (id)initWithDevice:(IDevice *)theAmbilightDevice {
  self = [super init];
  if (self && (theAmbilightDevice.type == ambilight)) {
    // Get the pointer of the device
    iDevice = theAmbilightDevice;
    [brightnesSlider setMaxValue:1.0];
    [brightnesSlider setMinValue:0.0];
    brightnesSlider.doubleValue = 1.0;
    [brightnesSlider setTarget:self];
    [brightnesSlider setContinuous:YES];
  
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
  // Set name and image of the device
  [ambilightName setStringValue:[iDevice name]];
  [ambilightImage setImage:[iDevice image]];
  [ambilightImage setAllowDrag:false];
  [ambilightImage setAllowDrop:false];
  
  // Set the background color accordingly
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[[iDevice color] CGColor]];
  [backView setWantsLayer:YES];
  [backView setLayer:viewLayer];
}


- (IBAction) ambilightPressed:(id)sender {
  NSLog(@"ambilightPressed");
  
  [(Ambilight*) [iDevice theDevice] toggleAmbilight:true];
}


- (IBAction) blackPressed:(id)sender {
  NSLog(@"blackPressed");
  
}

- (IBAction) fadePressed:(id)sender {
  NSLog(@"fadePressed");
  [(Ambilight*) [iDevice theDevice] toggleFade:true];
}


- (IBAction) openColorPicker:(id)sender {
  [NSApp activateIgnoringOtherApps:YES];
  [[NSColorPanel sharedColorPanel] setTarget:self];
  [[NSColorPanel sharedColorPanel] setAction:@selector(colorPicked:)];
  [[NSColorPanel sharedColorPanel] makeKeyAndOrderFront:nil];
}

- (void) colorPicked: (NSColorWell *) picker{
  NSLog(@"Color picked");
  //[ambilight writeColor:picker.color];
  
  [(Ambilight*) [iDevice theDevice] changeColor:picker.color];
  
}

- (IBAction) brightnessChanged:(id)sender {
  NSLog(@"Brightness changed");
  //[ambilight writeColor:picker.color];
}

/*
 * Checks if the ambilight deivce is connected over USB.
 */
- (BOOL)checkConnected {
  if ([(Ambilight*)[iDevice theDevice] isConnected]) return true;
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:ALERT_BUTTON_OK];
  [alert setMessageText:ALERT_NO_CONNECTION_MESSAGE];
  [alert setInformativeText:[NSString stringWithFormat:@"%@%@.", ALERT_NO_CONNECTION_MESSAGE_INFORMAL, [iDevice name]]];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
  return false;
}

@end
