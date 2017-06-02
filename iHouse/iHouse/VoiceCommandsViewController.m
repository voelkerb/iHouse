//
//  VoiceCommandsViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 06/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "VoiceCommandsViewController.h"
#import "VoiceCommand.h"
#import "IDevice.h"

#define DEBUG_VC 1

#define STANDARD_COMMAND_NAME @"New command"

#define ALL_TYPE_TITLE @"Any Command"
#define ALL_ROOMS_TITLE @"Any Room"
#define UNBOUND_COMMANDS_TITLE @"Unbound Commands"

@interface VoiceCommandsViewController ()

@end

@implementation VoiceCommandsViewController

@synthesize sideBarTableView, currentView, house, emptyView, voiceCommandsPreferenceViewController, typePopUpButton, roomPopUpButton, viewWithTable, addVoiceCommandViewController;

- (id)init {
  if (self = [super init]) {
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do view setup here.
  
  // Init the house singletone
  house = [House sharedHouse];
  
  // Add the view
  [viewWithTable setFrame:[self.view bounds]];
  [viewWithTable setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [self.view addSubview:viewWithTable];
  
  
  // Init the Popup Button to show a list of all available device types
  [self initPopUpButtons];
  
  // Init SideBar to contain all voice commands of house
  [self initSideBarTable];
  
  // If voice command exist, set view and selection
  if ([[house voiceCommands] count] != 0) {
    [self changedSideBarTableAndView:0];
  // Else draw emptyview
  } else {
    [emptyView setFrame:[currentView bounds]];
    [emptyView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [currentView addSubview:emptyView];
  }
  
  // Add an observer for voice command name changes (we need to redraw the tableview
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceCommandNameChanged:) name:VoiceCommandNameChanged object:nil];
}

/*
 * Init the content of the sidebar, the names from the voice commands.
 */
- (void) initSideBarTable {
  // Select the generl item in the table View
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
  //[sideBarTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
  [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
  
  // The Sidebar is a tableview, just set its background color accordingly
  //[sideBarTableView setBackgroundColor:SIDEBAR_STYLE];
}

/*
 * Is called if the user wants to add a voice command.
 */
- (IBAction)addVoiceCommand:(id)sender {
  // Remove view with table
  [viewWithTable removeFromSuperview];
  // Add new command view
  addVoiceCommandViewController = [[NewVoiceCommandViewController alloc] init];
  [addVoiceCommandViewController setDelegate:self];
  [[addVoiceCommandViewController view] setFrame:[self.view bounds]];
  [[addVoiceCommandViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [self.view addSubview:[addVoiceCommandViewController view]];
}

/*
 * Is called if the user wants to remove the current voice command.
 */
- (IBAction)removeVoiceCommand:(id)sender {
  // If no interactiveVoiceCommand in list or nothing selected, return
  if ([[house voiceCommands] count] == 0 || [sideBarTableView selectedRow] < 0) return;
  
  // Remove current selected Voice Command
  [house removeVoiceCommand:[[house voiceCommands][sideBarTableView.selectedRow] name] :self];
  // If no voice command in list anymore
  if ([[house voiceCommands] count] == 0) {
    // Remove all Subviews
    NSArray* thisPageSubviews = [currentView subviews];
    for(NSView* thisPageSubview in thisPageSubviews) {
      [thisPageSubview removeFromSuperview];
    }
    // draw empty voiceCommand view
    [emptyView setFrame:[currentView bounds]];
    [emptyView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [currentView addSubview:emptyView];
  // else automatically select the new inserted voice command
  }
  // Reload data
  [sideBarTableView reloadData];
  
  // Select the row and show the corresponding view
  if ([[house voiceCommands] count] > [sideBarTableView selectedRow]) {
    [self changedSideBarTableAndView:[sideBarTableView selectedRow]];
  } else if ([[house voiceCommands] count] > 0) {
    [self changedSideBarTableAndView:[[house voiceCommands] count]-1];
  }
}


/*
 * Action performed by clicking object in sidebar table view
 */
- (IBAction)changedSideBarTable:(id)sender {
  [self changedSideBarTableAndView:[sender selectedRow]];
}

/*
 * Called within code.
 */
- (void)changedSideBarTableAndView:(NSInteger)row {
  // If it is the same row or no row just return, else we need to change the view
  if (row < 0 || row >= [[house voiceCommands] count]) {
    // Let the last row be selected
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:row];
    [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
    return;
  }
  // Remove all Subviews
  NSArray* thisPageSubviews = [currentView subviews];
  for(NSView* thisPageSubview in thisPageSubviews) {
    [thisPageSubview removeFromSuperview];
  }
  // Open interactive room view by passing by the Ineractive command
  if ([[house voiceCommands] count] != 0) {
    voiceCommandsPreferenceViewController = [[VoiceCommandsPreferenceViewController alloc] initWithVoiceCommand:[house voiceCommands][row]];
    [[voiceCommandsPreferenceViewController view] setFrame:[currentView bounds]];
    [[voiceCommandsPreferenceViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [currentView addSubview:[voiceCommandsPreferenceViewController view]];
  }
  
  // Set it as selected
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:row];
  [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
}

/*
 * If a command name was edited reload the tableview
 */
- (void)voiceCommandNameChanged:(NSNotification*)notification {
  [sideBarTableView reloadData];
}

/*
 * Init the Popupbutton to show a list of all available device types an the all type
 */
- (void) initPopUpButtons {
  [typePopUpButton removeAllItems];

  // Add the all commands filter mode with tag = total amount of different devices
  NSMenuItem *allTypeItem = [[NSMenuItem alloc] initWithTitle:ALL_TYPE_TITLE action:NULL keyEquivalent:ALL_TYPE_TITLE];
  // Tag is the number of different iDevices
  [allTypeItem setTag:differentDeviceCount];
  [[typePopUpButton menu] addItem:allTypeItem];
  // Add seperator
  [[typePopUpButton menu] addItem:[NSMenuItem separatorItem]];
  // Add the interactive command filter type
  NSMenuItem *interactiveTypeItem = [[NSMenuItem alloc] initWithTitle:UNBOUND_COMMANDS_TITLE action:NULL keyEquivalent:UNBOUND_COMMANDS_TITLE];
  // Tag is the number of different iDevices + 1
  [interactiveTypeItem setTag:differentDeviceCount+1];
  [[typePopUpButton menu] addItem:interactiveTypeItem];
  // Add seperator
  [[typePopUpButton menu] addItem:[NSMenuItem separatorItem]];
  
  // Add all available devices to the dropdown menu and set its tag accordingly
  IDevice *dev = [[IDevice alloc] init];
  for (int i = 0; i < differentDeviceCount; i++) {
    // if this device has voice commands
    if ([dev deviceTypeHasSelectors:i]) {
      NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[dev DeviceTypeToString:(DeviceType)(i)] action:NULL keyEquivalent:[dev DeviceTypeToString:(DeviceType)(i)]];
      // Tag is device enum
      [item setTag:i];
      [[typePopUpButton menu] addItem:item];
    }
  }
  
  // Init the room popoup button
  [roomPopUpButton removeAllItems];
  // Add All room as one option with the total number of rooms as tag
  [roomPopUpButton addItemWithTitle:ALL_ROOMS_TITLE];
  [[roomPopUpButton itemAtIndex:0] setTag:[[house rooms] count]];
  NSInteger numberOfItems = [roomPopUpButton numberOfItems];
  for (int i = 0; i < [[house rooms] count]; i++) {
    [roomPopUpButton addItemWithTitle:[[house rooms][i] name]];
    // +numberOfItems because there were exaclty numberOfItems items in list before
    [[roomPopUpButton itemAtIndex:i+numberOfItems] setTag:i];
  }
}

/*
 * The Action when the type popupbutton is changed
 */
- (IBAction) filterChanged:(id)sender {
  // Table needs to redraw
  [sideBarTableView reloadData];
  // If table has no rows, make empty view
  if ([sideBarTableView numberOfRows] < 1) {
    // Remove all Subviews
    NSArray* subviews = [[NSArray alloc] initWithArray:[currentView subviews]];
    for(NSView* theSubview in subviews) [theSubview removeFromSuperview];
    // Set view to emty view
    [emptyView setFrame:[currentView bounds]];
    [emptyView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [currentView addSubview:emptyView];
  // Else set the view to the first table entry
  } else {
    [self changedSideBarTableAndView:0];
  }
}


/*
 * Returns array of visible Voice commands for the given filter
 */
- (NSArray*) getListOfVisibleDevices {
  // Get the object inside the row
  NSMutableArray *deviceArray = [[NSMutableArray alloc] init];
  // If the room filter is set to commands in all rooms
  if ([[roomPopUpButton selectedItem] tag] == [[[House sharedHouse] rooms] count]) {
    // Go through all voice commands
    for (VoiceCommand* theVoiceCommand in [[House sharedHouse] voiceCommands]) {
      // If the type filter says all devices, add all devices
      if ([[typePopUpButton selectedItem] tag] == differentDeviceCount) {
        [deviceArray addObject:theVoiceCommand];
      // If the type filter is set to unbound devices search for devices without handlers
      } else if ([[typePopUpButton selectedItem] tag] == differentDeviceCount+1) {
        if (![theVoiceCommand handler]) {
          [deviceArray addObject:theVoiceCommand];
        }
      // Else search for devices with the same type as filter
      } else {
        if ([[theVoiceCommand handler] respondsToSelector:@selector(type)]) {
          if (DEBUG_VC) NSLog(@"Name %@, Tag: %li vs HandlerType: %li", theVoiceCommand.name, [[typePopUpButton selectedItem] tag], [(IDevice*)[theVoiceCommand handler] type] );
          if ([(IDevice*)[theVoiceCommand handler] type] == [[typePopUpButton selectedItem] tag]) {
            [deviceArray addObject:theVoiceCommand];
          }
        }
      }
    }
  // If the room filter is set
  } else {
    // Go through all voiceommands
    for (VoiceCommand* theVoiceCommand in [[House sharedHouse] voiceCommands]) {
      // And only take care of the commands that are stored in the room of the filter
      if ([[[roomPopUpButton selectedItem] title] isEqualToString:[[theVoiceCommand room] name]]) {
        // If the type filter says all devices, add all devices
        if ([[typePopUpButton selectedItem] tag] == differentDeviceCount) {
          [deviceArray addObject:theVoiceCommand];
        // If the type filter is set to unbound devices search for devices without handlers
        } else if ([[typePopUpButton selectedItem] tag] == differentDeviceCount+1) {
          if (![theVoiceCommand handler]) {
            [deviceArray addObject:theVoiceCommand];
          }
        // Else search for devices with the same type as filter
        } else {
          if ([(IDevice*)[theVoiceCommand handler] type] == [[typePopUpButton selectedItem] tag]) {
            [deviceArray addObject:theVoiceCommand];
          }
        }
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
  // Look for the selected filter
  return [[self getListOfVisibleDevices] count];
}


/*
 * Fill information into table cell
 */
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  // Get the object inside the row
  VoiceCommand *theVoiceCommand = [self getListOfVisibleDevices][row];
  // Get the identifier of the table column (we have only 1 so basicly useless)
  NSString *identifier = [tableColumn identifier];
  // Compare if we are in right column
  if ([identifier isEqualToString:@"MainCell"]) {
    // Create the cell View and paste image and name into it
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
    [cellView.textField setStringValue:[theVoiceCommand name]];
    return cellView;
  }
  // Return nil if not matching or wrong row
  return nil;
}


#pragma newDeviceViewController delegate

/*
 * The newDeviceViewController finished editing
 */
- (void)newVoiceCommandFinished {
  // Remove new device view
  [[addVoiceCommandViewController view] removeFromSuperview];
  
  // Add the tableview back
  [viewWithTable setFrame:[self.view bounds]];
  [viewWithTable setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [self.view addSubview:viewWithTable];
  
  // Maybe sideBar needs to reload
  [sideBarTableView reloadData];
}



@end
