//
//  HooverViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//



#import "HooverViewController.h"
#import "IDevice.h"

#define DEBUG_HOOVER true

#define START_IMAGE @"play.png"
#define STOP_IMAGE @"pause.png"

#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NO_CONNECTION_MESSAGE @"Hoover device not connected"
#define ALERT_NO_CONNECTION_MESSAGE_INFORMAL @"Connect an iHouse hoover to enable this feature."

@interface HooverViewController ()

@end

@implementation HooverViewController
@synthesize iDevice, deviceImage, deviceName, startStopButton, speedSlider, leftButton, rightButton, forwardButton, backwardButton, backView;


/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  HooverViewController *copy = [[HooverViewController allocWithZone: zone] initWithDevice:iDevice];
  return copy;
}

-(id)initWithDevice:(IDevice *)theDevice {
  self = [super init];
  if (self && (theDevice.type == hoover)) {
    iDevice = theDevice;
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
  [deviceName setStringValue:[iDevice name]];
  [deviceImage setImage:[iDevice image]];
  
  
  // Set start button and init the buttons to send actions on mouse down and up
  if ([(Hoover*)[iDevice theDevice] isCleaning]) [startStopButton setImage:[NSImage imageNamed:STOP_IMAGE]];
  else [startStopButton setImage:[NSImage imageNamed:START_IMAGE]];
  [self.leftButton sendActionOn: NSLeftMouseDownMask | NSLeftMouseUpMask];
  [self.rightButton sendActionOn: NSLeftMouseDownMask | NSLeftMouseUpMask];
  [self.forwardButton sendActionOn: NSLeftMouseDownMask | NSLeftMouseUpMask];
  [self.backwardButton sendActionOn: NSLeftMouseDownMask | NSLeftMouseUpMask];
  
  // Init Slider
  [speedSlider setMinValue:10];
  [speedSlider setMaxValue:ROOMBA_MAX_SPEED];
  [speedSlider setIntegerValue: [(Hoover*)[iDevice theDevice] speed]];
  [speedSlider setContinuous:NO];
  
  // Set the background color accordingly
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[[iDevice color] CGColor]];
  [backView setWantsLayer:YES];
  [backView setLayer:viewLayer];
}

/*
 * Called if the user presses the start/stop cleaning button
 */
- (IBAction)startStopCleaning:(id)sender {
  // The current state is cleaning so set the image to start image and stop cleaning
  if ([(Hoover*)[iDevice theDevice] isCleaning]) {
    if ([self checkConnected]) {
      [(Hoover*)[iDevice theDevice] stopCleaning];
      [startStopButton setImage:[NSImage imageNamed:START_IMAGE]];
    }
    if (DEBUG_HOOVER) NSLog(@"Stop pressed");
  // The current state is not cleaning so set the image to stop and start cleaning
  } else {
    if ([self checkConnected]) {
      [(Hoover*)[iDevice theDevice] startCleaning];
      [startStopButton setImage:[NSImage imageNamed:STOP_IMAGE]];
    }
    if (DEBUG_HOOVER) NSLog(@"Start pressed");
  }
}

/*
 * Called if the user presses the dock button
 */
- (IBAction)goHome:(id)sender {
  if (DEBUG_HOOVER) NSLog(@"Dock pressed");
  if ([self checkConnected]) [(Hoover*)[iDevice theDevice] comeToDock];
}

/*
 * Called if the user presses the left button
 */
- (IBAction)leftPressed:(id)sender {
  NSEvent *currentEvent = [[sender window] currentEvent];
  // On mouse down let him drive
  if ([currentEvent type] == NSLeftMouseDown) {
    if (DEBUG_HOOVER) NSLog(@"Left pressed");
    if ([self checkConnected]) [(Hoover*)[iDevice theDevice] drive:roomba_left :[speedSlider intValue]];
  // On mouse up let him stop
  } else if ([currentEvent type] == NSLeftMouseUp) {
    if (DEBUG_HOOVER) NSLog(@"Left released");
    if ([self checkConnected]) [(Hoover*)[iDevice theDevice] drive:roomba_stop :[speedSlider intValue]];
  }
}

/*
 * Called if the user presses the right button
 */
- (IBAction)rightPressed:(id)sender {
  NSEvent *currentEvent = [[sender window] currentEvent];
  // On mouse down let him drive
  if ([currentEvent type] == NSLeftMouseDown) {
    if (DEBUG_HOOVER) NSLog(@"Right pressed");
    if ([self checkConnected]) [(Hoover*)[iDevice theDevice] drive:roomba_right :[speedSlider intValue]];
  // On mouse up let him stop
  } else if ([currentEvent type] == NSLeftMouseUp) {
    if (DEBUG_HOOVER) NSLog(@"Right released");
    if ([self checkConnected]) [(Hoover*)[iDevice theDevice] drive:roomba_stop :[speedSlider intValue]];
  }
}

/*
 * Called if the user presses the forward button
 */
- (IBAction)forwardPressed:(id)sender {
  NSEvent *currentEvent = [[sender window] currentEvent];
  // On mouse down let him drive
  if ([currentEvent type] == NSLeftMouseDown) {
    if (DEBUG_HOOVER) NSLog(@"Forward pressed");
    if ([self checkConnected]) [(Hoover*)[iDevice theDevice] drive:roomba_forward :[speedSlider intValue]];
  // On mouse up let him stop
  } else if ([currentEvent type] == NSLeftMouseUp) {
    if (DEBUG_HOOVER) NSLog(@"Forward released");
    if ([self checkConnected]) [(Hoover*)[iDevice theDevice] drive:roomba_stop :[speedSlider intValue]];
  }
}

/*
 * Called if the user presses the backward button
 */
- (IBAction)backwardPressed:(id)sender {
  NSEvent *currentEvent = [[sender window] currentEvent];
  // On mouse down let him drive
  if ([currentEvent type] == NSLeftMouseDown) {
    if (DEBUG_HOOVER) NSLog(@"Backward pressed");
    if ([self checkConnected]) [(Hoover*)[iDevice theDevice] drive:roomba_backward :[speedSlider intValue]];
  // On mouse up let him stop
  } else if ([currentEvent type] == NSLeftMouseUp) {
    if (DEBUG_HOOVER) NSLog(@"Backward released");
    if ([self checkConnected]) [(Hoover*)[iDevice theDevice] drive:roomba_stop :[speedSlider intValue]];
  }
}

/*
 * Checks if the Hoover is connected over tcp.
 */
- (BOOL)checkConnected {
  if ([(Hoover*)[iDevice theDevice] isConnected]) return true;
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:ALERT_BUTTON_OK];
  [alert setMessageText:ALERT_NO_CONNECTION_MESSAGE];
  [alert setInformativeText:ALERT_NO_CONNECTION_MESSAGE_INFORMAL];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
  return false;
}

@end
