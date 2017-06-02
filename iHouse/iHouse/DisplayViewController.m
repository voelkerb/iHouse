//
//  DisplayViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "DisplayViewController.h"
#import "IDevice.h"

#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NO_CONNECTION_MESSAGE @" Display not connected"
#define ALERT_NO_CONNECTION_MESSAGE_INFORMAL1 @"Connect the "
#define ALERT_NO_CONNECTION_MESSAGE_INFORMAL2 @" display over Wifi to enable this feature."


@interface DisplayViewController ()

@end

@implementation DisplayViewController
@synthesize iDevice, imageNameTextField, nameLabel, displayImage, warningMsgTextField, headlineMsgTextField, backView;

/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  DisplayViewController *copy = [[DisplayViewController allocWithZone: zone] initWithDevice:iDevice];
  
  copy.imageNameTextField = imageNameTextField;
  copy.headlineMsgTextField = headlineMsgTextField;
  copy.warningMsgTextField = warningMsgTextField;
  return copy;
}

- (id)initWithDevice:(IDevice *)theDisplayDevice {
  self = [super init];
  if (self && (theDisplayDevice.type == display)) {
    // Get the pointer of the device
    iDevice = theDisplayDevice;
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
  [nameLabel setStringValue:[iDevice name]];
  [displayImage setImage:[iDevice image]];
  
  // Set the background color accordingly
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[[iDevice color] CGColor]];
  [backView setWantsLayer:YES];
  [backView setLayer:viewLayer];
}

/*
 * Is called, if the user presses the beep button. A beep sound is played.
 */
- (IBAction)beepPressed:(id)sender {
  if ([self checkConnected]) [(Display*)[iDevice theDevice] beep];
}

/*
 * Is called, if the user enters a warning message in the warning-textfield and presses enter.
 * A warning triangle is displayed alternated with the warning message
 */
- (IBAction)setWarning:(id)sender {
  if ([self checkConnected]) [(Display*)[iDevice theDevice] setWarning:[warningMsgTextField stringValue]];
}

/*
 * Is called, if the user enters a headline in the headline-textfield and presses enter.
 * The headline is displayed in red on the Display.
 */
- (IBAction)setHeadline:(id)sender {
  if ([self checkConnected]) [(Display*)[iDevice theDevice] setHeadline:[headlineMsgTextField stringValue] :display_red];
}

/*
 * Is called if the user enters an image name in the image-textfield and presses enter.
 * If the image exists on the SD card of the display, it is displayed.
 */
- (IBAction)setImage:(id)sender {
  if ([self checkConnected]) [(Display*)[iDevice theDevice] setImageNamed:[imageNameTextField stringValue]];
}

/*
 * Is called, if the user presses the reset button. The display is resetted to black.
 */
- (IBAction)resetDisplay:(id)sender {
  if ([self checkConnected]) [(Display*)[iDevice theDevice] reset :display_black];
}

/*
 * Checks if the display is connected over tcp
 */
- (BOOL)checkConnected {
  if ([(Display*)[iDevice theDevice] isConnected]) return true;
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:ALERT_BUTTON_OK];
  [alert setMessageText:[NSString stringWithFormat:@"%@%@", [iDevice name], ALERT_NO_CONNECTION_MESSAGE]];
  [alert setInformativeText:[NSString stringWithFormat:@"%@%@%@", ALERT_NO_CONNECTION_MESSAGE_INFORMAL1,
                             [iDevice name], ALERT_NO_CONNECTION_MESSAGE_INFORMAL2]];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
  return false;
}


@end
