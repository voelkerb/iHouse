//
//  newDeviceViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 20/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "NewDeviceViewController.h"
#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NAME_EXISTS_MESSAGE @"A device with the selected name already exists."
#define ALERT_NAME_EXISTS_MESSAGE_INFORMAL @"Please select a different name."

@interface NewDeviceViewController ()

@end

@implementation NewDeviceViewController
@synthesize deviceTypePopUpButton, roomPopUpButton, createDeviceView, house, delegate;
@synthesize nameTextField, image, colorWell;
@synthesize device, advancedDeviceEditView;


- (void)viewDidLoad {
  [super viewDidLoad];
  // Do view setup here.
  
  // Init the house object
  house = [House sharedHouse];
  device = [[IDevice alloc] initWithDeviceType:light];
  // Set name textfield, image and color accordingly
  [nameTextField setStringValue:[device name]];
  [image setImage:[device image]];
  [colorWell setColor:[device color]];
  // Init the popup buttons
  [self initPopUpButtons];
  
  // Set the view according to the type
  advancedDeviceEditView = [device deviceEditView];
  [[advancedDeviceEditView view] setFrame:[createDeviceView bounds]];
  [[advancedDeviceEditView view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [createDeviceView addSubview:[advancedDeviceEditView view]];
}

/*
 * Init the Popupbutton to show a list of all available device types an the all type
 */
- (void) initPopUpButtons {
  [deviceTypePopUpButton removeAllItems];
   // Add all available devices and rooms to the dropdown menus and set its tag accordingly
  for (int i = 0; i < differentDeviceCount; i++) {
    [deviceTypePopUpButton addItemWithTitle:[device DeviceTypeToString:(DeviceType)(i)]];
    [[deviceTypePopUpButton itemAtIndex:i] setTag:i];
  }
  [roomPopUpButton removeAllItems];
  for (int i = 0; i < [[house rooms] count]; i++) {
    [roomPopUpButton addItemWithTitle:[[house rooms][i] name]];
    [[roomPopUpButton itemAtIndex:i] setTag:i];
  }
}

/*
 * The user changed the popup button
 */
- (IBAction)popUpButtonChanged:(id)sender {
  // Change the type of the device
  device = [[IDevice alloc] initWithDeviceType:[[deviceTypePopUpButton selectedItem] tag]];
  //NSLog(@"Device: %@",[device DeviceTypeToString:[[deviceTypePopUpButton selectedItem] tag]]);
  //NSLog(@"Room: %@",[[house rooms][[[roomPopUpButton selectedItem] tag]] name]);
  // Remove the current view
  NSArray *views = [createDeviceView subviews];
  for (NSView *view in views) [view removeFromSuperview];
  // And set the view according to the type
  advancedDeviceEditView = [device deviceEditView];
  [[advancedDeviceEditView view] setFrame:[createDeviceView bounds]];
  [[advancedDeviceEditView view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [createDeviceView addSubview:[advancedDeviceEditView view]];
}

/*
 * Called if the user pressed the cancel button
 */
- (IBAction)cancelPressed:(id)sender {
  // Indicate to the delegate that the device finished editing
  [delegate newDeviceFinished];
}

/*
 * Called if the user pressed the save button
 */
- (IBAction)savePressed:(id)sender {
  if ([self checkNameExists]) return;
  // Store the current set properties of the device
  device.image = [image image];
  device.color = [colorWell color];
  device.name = [nameTextField stringValue];
  
  // And add the device to the selected room
  NSInteger tag = [[roomPopUpButton selectedItem] tag];
  Room *theRoom = house.rooms[tag];
  [theRoom addDevice:device :self];
  
  // Indicate new room device
  [[NSNotificationCenter defaultCenter] postNotificationName:RoomDeviceDidChange object:theRoom];
  // Indicate to the delegate that the device finished editing
  [delegate newDeviceFinished];
}

/*
 * If name did change
 */
- (IBAction)nameTextFieldChanged:(id)sender {
  [self checkNameExists];
}

- (BOOL)checkNameExists {
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
        nameExist = true;
      }
    }
  }
  
  if (!nameExist) {
    device.name = [nameTextField stringValue];
  }
  return nameExist;
}
@end
