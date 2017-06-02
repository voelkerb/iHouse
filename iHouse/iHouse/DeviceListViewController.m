//
//  DeviceListViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 06/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "DeviceListViewController.h"
#define ALL_DEVICE_TITLE @"Any Device"
#define ALL_ROOMS_TITLE @"Any Room"
@interface DeviceListViewController ()

@end

@implementation DeviceListViewController
@synthesize house, devicePopUpButton, roomPopUpButton, currentDeviceEditView, sideBarTableView, emptyView, createDeviceViewController, editDeviceViewController, viewWithTable;
@synthesize currentEditView, currentDeviceView, devicePreviewViewController, advancedEditDeviceViewController;

- (void)viewDidLoad {
  // Init the house object
  house = [House sharedHouse];
  
  // Add the view
  [viewWithTable setFrame:[self.view bounds]];
  [viewWithTable setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [self.view addSubview:viewWithTable];

  // Set view to emty view
  [emptyView setFrame:[currentEditView bounds]];
  [emptyView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [currentEditView addSubview:emptyView];
  
  // Init the Popup Button to show a list of all available device types
  [self initPopUpButtons];
  lastDevice = -1;
  [self changedSideBarTableAndView:0];
  
  [super viewDidLoad];
}


/*
 * Init the Popupbutton to show a list of all available device types an the all type
 */
- (void) initPopUpButtons {
  [devicePopUpButton removeAllItems];
  // At the All device filter mode with tag = total amount of different devices
  [devicePopUpButton addItemWithTitle:ALL_DEVICE_TITLE];
  [[devicePopUpButton itemAtIndex:0] setTag:differentDeviceCount];
  // Add all available devices to the dropdown menu and set its tag accordingly
  IDevice *dev = [[IDevice alloc] init];
  NSInteger numberOfItems = [devicePopUpButton numberOfItems];
  for (int i = 0; i < differentDeviceCount; i++) {
    [devicePopUpButton addItemWithTitle:[dev DeviceTypeToString:(DeviceType)(i)]];
    // +numberOfItems because there were exaclty numberOfItems items in list before
    [[devicePopUpButton itemAtIndex:i+numberOfItems] setTag:i];
  }
  
  [roomPopUpButton removeAllItems];
  [roomPopUpButton addItemWithTitle:ALL_ROOMS_TITLE];
  [[roomPopUpButton itemAtIndex:0] setTag:[[house rooms] count]];
  numberOfItems = [roomPopUpButton numberOfItems];
  for (int i = 0; i < [[house rooms] count]; i++) {
    [roomPopUpButton addItemWithTitle:[[house rooms][i] name]];
    // +numberOfItems because there were exaclty numberOfItems items in list before
    [[roomPopUpButton itemAtIndex:i+numberOfItems] setTag:i];
  }
  
}

/*
 * The Action when the device popupbutton is changed
 */
- (IBAction) filterChanged:(id)sender {
  
  // Table needs to redraw
  [sideBarTableView reloadData];
  
  lastDevice = -1;
  if ([sideBarTableView numberOfRows] < 1) {
    // Remove all Subviews
    NSMutableArray* thisPageSubviews = [NSMutableArray arrayWithArray:[currentEditView subviews]];
    [thisPageSubviews addObjectsFromArray:[currentDeviceView subviews]];
    [thisPageSubviews addObjectsFromArray:[currentDeviceEditView subviews]];
    for(NSView* thisPageSubview in thisPageSubviews) {
      [thisPageSubview removeFromSuperview];
    }
    // Set view to emty view
    [emptyView setFrame:[currentEditView bounds]];
    [emptyView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [currentEditView addSubview:emptyView];
  } else {
    [self changedSideBarTableAndView:0];
  }
}

/*
 * The User wants to add a device
 */
- (IBAction)addDevice:(id)sender {
  // Remove view with table
  [viewWithTable removeFromSuperview];
  // Add new device view
  createDeviceViewController = [[NewDeviceViewController alloc] initWithNibName:@"NewDeviceView" bundle:nil];
  [createDeviceViewController setDelegate:self];
  [[createDeviceViewController view] setFrame:[self.view bounds]];
  [[createDeviceViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [self.view addSubview:[createDeviceViewController view]];
}



/*
 * The User wants to delete the current device
 */
- (IBAction)removeDevice:(id)sender {
  // If no device in list or nothing selected, return
  if ([sideBarTableView selectedRow] < 0) return;
    
  // Remove current selected Device
  IDevice *theDevice = [self getListOfVisibleDevices][sideBarTableView.selectedRow];
  
  for (Room *theRoom in [house rooms]) {
    if ([[theRoom name] isEqualToString:[theDevice roomName]]) {
      [theRoom removeDevice:[theDevice name] :self];
      // Post notification to make room redraw itself
      [[NSNotificationCenter defaultCenter] postNotificationName:RoomDeviceDidChange object:theRoom];
    }
  }
  
  [sideBarTableView reloadData];
  
  lastDevice = -1;
  if ([sideBarTableView numberOfRows] < 1) {
    // draw empty room view
    [emptyView setFrame:[currentEditView bounds]];
    [emptyView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [currentEditView addSubview:emptyView];
  } else {
    [self changedSideBarTableAndView:0];
  }
}

// Delegate function if device changes to change name in tableview
- (void)deviceDidChange {
  [sideBarTableView reloadData];
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:lastDevice];
  [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
}

/*
 * Action performed by clicking object in sidebar table view
 */
- (IBAction)changedSideBarTable:(id)sender {
  [self changedSideBarTableAndView:[sender selectedRow]];
}
/*
 * Called within code
 */
- (void)changedSideBarTableAndView:(NSInteger)row {
  // If it is the same row or no row just return, else we need to change the view
  if (row < 0 || row >= [[self getListOfVisibleDevices] count]) {
    // Let the last row be selected
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:lastDevice];
    [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
    return;
  }
  // If it was the last row selected do nothing
  if (row == lastDevice) return;
  else lastDevice = row;
  

  // Open room view by passing by the room
  if ([[self getListOfVisibleDevices] count] != 0) {
    [self setViewsWithRow:row];
  }
  
  // Set it as selected
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:row];
  [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
}


- (void)setViewsWithRow:(NSInteger) row {
  // Remove all Subviews
  NSMutableArray* thisPageSubviews = [NSMutableArray arrayWithArray:[currentEditView subviews]];
  [thisPageSubviews addObjectsFromArray:[currentDeviceView subviews]];
  [thisPageSubviews addObjectsFromArray:[currentDeviceEditView subviews]];
  for(NSView* thisPageSubview in thisPageSubviews) {
    [thisPageSubview removeFromSuperview];
  }
  
  // Add the view for adding the devices name color and image
  editDeviceViewController = [[EditDeviceViewController alloc] initWithNibName:@"EditDeviceView" bundle:nil device:[self getListOfVisibleDevices][row]];
  [editDeviceViewController setDelegate:self];
  [[editDeviceViewController view] setFrame:[currentEditView bounds]];
  [[editDeviceViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [currentEditView addSubview:[editDeviceViewController view]];
  
  // Add the preview view
  devicePreviewViewController = [[DevicePreviewViewController alloc] initWithDevice:[self getListOfVisibleDevices][row]];
  [[devicePreviewViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [[devicePreviewViewController view] setFrame:[currentDeviceView bounds]];
  [currentDeviceView addSubview:[devicePreviewViewController view]];
  //[devicePreviewViewController drawViewCentered];
  
  // Add the device edit view
  advancedEditDeviceViewController = [[self getListOfVisibleDevices][row] deviceEditView];
  //NSView *view = [[self getListOfVisibleDevices][row] deviceEditView];
  [[advancedEditDeviceViewController view] setFrame:[currentDeviceEditView bounds]];
  [[advancedEditDeviceViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [currentDeviceEditView addSubview:[advancedEditDeviceViewController view]];
}

#pragma newDeviceViewController delegate
/*
 * The newDeviceViewController finished editing
 */
- (void)newDeviceFinished {
  // Remove new device view
  [[createDeviceViewController view] removeFromSuperview];
  
  // Add the tableview back
  [viewWithTable setFrame:[self.view bounds]];
  [viewWithTable setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [self.view addSubview:viewWithTable];
  
  lastDevice = -1;
  // Maybe sideBar needs to reload
  [sideBarTableView reloadData];
}




- (NSArray*) getListOfVisibleDevices {
  // Get the object inside the row
  NSMutableArray *roomArray = [[NSMutableArray alloc] init];
  // If all rooms devices should be displayed
  NSInteger tag = [[roomPopUpButton selectedItem] tag];
  if (tag == [[house rooms] count]) {
    roomArray = [NSMutableArray arrayWithArray:[house rooms]];
  } else {
    [roomArray addObject:[house rooms][tag]];
  }
  
  
  NSMutableArray *deviceArray = [[NSMutableArray alloc] init];
  // Search the list of rooms
  for (Room *theRoom in roomArray) {
    // If show all Devices
    if ([[devicePopUpButton selectedItem] tag] == differentDeviceCount) {
      [deviceArray addObjectsFromArray:[theRoom devices]];
    } else {
      for (IDevice *theDevice in [theRoom devices]) {
        if ([theDevice type] == [[devicePopUpButton selectedItem] tag]) [deviceArray addObject:theDevice];
      }
    }
  }
  
  return deviceArray;
  
}

#pragma TableView delegate methods

/*
 * Telling tableviews how many rows we have
 */
- (NSInteger)numberOfRowsInTableView:(nonnull NSTableView *)tableView {
  return [[self getListOfVisibleDevices] count];
}


/*
 * Fill information into table cell
 */
- (nullable NSView *)tableView:(nonnull NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
  
  
  IDevice *theDevices = [self getListOfVisibleDevices][row];
  // Get the identifier of the table column (we have only 1 so basicly useless)
  NSString *identifier = [tableColumn identifier];
  // Compare if we are in right column
  if ([identifier isEqualToString:@"MainCell"]) {
    // Create the cell View and paste image and name into it
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
    [cellView.imageView setImage:[theDevices image]];
    [cellView.textField setStringValue:[theDevices name]];
    return cellView;
  }
  // Return nil if not matching or wrong row
  return nil;
}

@end
