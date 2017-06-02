//
//  DeviceListViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 06/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "House.h"
#import "NewDeviceViewController.h"
#import "EditDeviceViewController.h"
#import "DevicePreviewViewController.h"

@interface DeviceListViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NewDeviceViewControllerDelegate, EditDeviceViewControllerDelegate>{
  NSInteger lastDevice;
}

// The Sidebar with the list of devices
@property (weak) IBOutlet NSTableView *sideBarTableView;

// The current view of the selected table item
@property (weak) IBOutlet NSView *currentDeviceEditView;
@property (weak) IBOutlet NSView *currentDeviceView;
@property (weak) IBOutlet NSView *currentEditView;

// The view with tables and currentview
@property (weak) IBOutlet NSView *viewWithTable;

// The view if no device is preset
@property (weak) IBOutlet NSView *emptyView;

// The popUpButton displaying the available device types and rooms
@property (weak) IBOutlet NSPopUpButton *devicePopUpButton;
@property (weak) IBOutlet NSPopUpButton *roomPopUpButton;

// The House object
@property (strong) House *house;

// The newDevice View controller
@property (strong) NewDeviceViewController *createDeviceViewController;
@property (strong) EditDeviceViewController *editDeviceViewController;
@property (strong) DevicePreviewViewController *devicePreviewViewController;
@property (strong) NSViewController *advancedEditDeviceViewController;


// Action from the device tableview
- (IBAction)changedSideBarTable:(id)sender;


// The Action when the popupbutton is changed
- (IBAction) filterChanged:(id)sender;

// The User wants to add a device to the list of devices
- (IBAction) addDevice:(id)sender;
// The User wants to delete the current device
- (IBAction)removeDevice:(id)sender;

@end
