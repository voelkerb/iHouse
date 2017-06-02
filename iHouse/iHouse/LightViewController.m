//
//  LightViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "LightViewController.h"
#import "IDevice.h"

#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NO_CONNECTION_MESSAGE @"Light switcher not connected"
#define ALERT_NO_CONNECTION_MESSAGE_INFORMAL @"Connect a iHouse light switcher over USB to switch "


@interface LightViewController ()

@end

@implementation LightViewController
@synthesize switchButton, lightImage, lightName, iDevice, backView;


/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  LightViewController *copy = [[LightViewController allocWithZone: zone] initWithDevice:iDevice];
  return copy;
}


- (id)initWithDevice:(IDevice *)theLightDevice {
  self = [super init];
  if (self && (theLightDevice.type == light)) {
    // Get pointer to device
    iDevice = theLightDevice;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lightSwitched)
                                                 name:LightSwitched
                                               object:nil];
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
  // Set name and image
  [lightName setStringValue:[iDevice name]];
  [lightImage setImage:[iDevice image]];
  [lightImage setAllowDrag:false];
  [lightImage setAllowDrop:false];
  
  // Set the background color accordingly
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[[iDevice color] CGColor]];
  [backView setWantsLayer:YES];
  [backView setLayer:viewLayer];
  
  // Set the state of the button according to the current state
  [switchButton setState:[(Light *)[iDevice theDevice] state]];
}

/*
 * Is called if the user hits the toggle button.
 */
- (IBAction)toggleLight:(id)sender {
  // Try to toggle the device
  if ([self checkConnected]) [(Light *)[iDevice theDevice] toggle:[switchButton state]];
  [switchButton setState:[(Light *)[iDevice theDevice] state]];
}

- (void)lightSwitched {
  // Update the state of the toggle button
  [switchButton setState:[(Light *)[iDevice theDevice] state]];
}


/*
 * Checks if the Light device is connected over USB.
 */
- (BOOL)checkConnected {
  if ([(Light*)[iDevice theDevice] isConnected]) return true;
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:ALERT_BUTTON_OK];
  [alert setMessageText:ALERT_NO_CONNECTION_MESSAGE];
  [alert setInformativeText:[NSString stringWithFormat:@"%@%@.", ALERT_NO_CONNECTION_MESSAGE_INFORMAL, [iDevice name]]];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
  return false;
}

@end
