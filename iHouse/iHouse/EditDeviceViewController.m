//
//  EditDeviceViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 20/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "EditDeviceViewController.h"
#define BOX_TITLE @"Properties of the "
#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NAME_EXISTS_MESSAGE @"A device with the selected name already exists."
#define ALERT_NAME_EXISTS_MESSAGE_INFORMAL @"Please select a different name."

@interface EditDeviceViewController ()

@end

@implementation EditDeviceViewController
@synthesize device, nameTextField, colorWell, imageView, theBox, delegate;

/*
 * Init the Room properly with object
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
                                    device: (IDevice *)theDevice {
  
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  
  if (self) {
    // Store name for further processing
    device = theDevice;
  }
  
  return self;
}

- (void)viewDidLoad {
  // Show the alpha slider of the color panel
  [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
  
  // Set values of the room
  [nameTextField setStringValue:[device name]];
  [colorWell setColor:[device color]];
  [imageView setImage:[device image]];
  [theBox setTitle:[NSString stringWithFormat:@"%@%@:",BOX_TITLE, [device DeviceTypeToString:[device type]]]];
  [super viewDidLoad];
}


/*
 * If name did change
 */
- (IBAction)nameTextFieldChanged:(id)sender {
  BOOL nameExist = false;
  House *theHouse = [House sharedHouse];
  for (Room *theRoom in [theHouse rooms]) {
    // If room with this name already exist, choose different one
    for (IDevice *theDevice in [theRoom devices]) {
      if ([[theDevice name] isEqualToString:[nameTextField stringValue]] && theDevice != device) {
        // Make alert sheet to display that the device already exist
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:ALERT_BUTTON_OK];
        [alert setMessageText:ALERT_NAME_EXISTS_MESSAGE];
        [alert setInformativeText:ALERT_NAME_EXISTS_MESSAGE_INFORMAL];
        [alert setAlertStyle:NSWarningAlertStyle];
        [nameTextField setStringValue:[device name]];
        [alert runModal];
      }
    }
  }
  
  if (!nameExist) {
    device.name = [nameTextField stringValue];
    [[NSNotificationCenter defaultCenter] postNotificationName:iDeviceDidChange object:device];
    [delegate deviceDidChange];
  }
}

/*
 * If image did change
 */
- (IBAction)imageChanged:(id)sender {
  device.image = [imageView image];
  [delegate deviceDidChange];
  [[NSNotificationCenter defaultCenter] postNotificationName:iDeviceDidChange object:device];
}

/*
 * If color did change
 */
- (IBAction)colorChanged:(id)sender {
  device.color = [colorWell color];
  [[NSNotificationCenter defaultCenter] postNotificationName:iDeviceDidChange object:device];
}

@end
