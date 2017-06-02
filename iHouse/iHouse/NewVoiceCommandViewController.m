//
//  newVoiceCommandViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 23/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "NewVoiceCommandViewController.h"
#import "IDevice.h"
#import "House.h"
#import "Calendar.h"
#import "Weather.h"

#define STANDARD_COMMAND_NAME @"New command"

#define ALL_ROOMS_TITLE @"Any Room"
#define UNBOUND_COMMANDS_TITLE @"Unbound Command"
#define CALENDAR_COMMANDS_TITLE @"Calendar"
#define WEATHER_COMMANDS_TITLE @"Weather"


@interface NewVoiceCommandViewController ()

@end

@implementation NewVoiceCommandViewController
@synthesize devicePopUpButton, roomPopUpButton, voiceCommandView, delegate, voiceCommandsPreferenceViewController, voiceCommand;


- (id)init {
  if (self = [super init]) {
    voiceCommand = [[VoiceCommand alloc] init];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do view setup here.
  
  // Init the popup buttons
  [self initPopUpButtons];
  
  // Set the view according to the type
  [self setTheVoiceCommandView];
}

/*
 * Init the Popupbutton to show a list of all available device types and rooms.
 */
- (void) initPopUpButtons {
  // Get the house object
  House *theHouse = [House sharedHouse];
  [roomPopUpButton removeAllItems];
  // Add any room as a possible selection
  NSMenuItem *allRoomsItem = [[NSMenuItem alloc] initWithTitle:ALL_ROOMS_TITLE action:NULL keyEquivalent:ALL_ROOMS_TITLE];
  // Set tag to different number of rooms
  [allRoomsItem setTag:[[theHouse rooms] count]];
  [[roomPopUpButton menu] addItem:allRoomsItem];
  // Add visual seperator
  [[roomPopUpButton menu] addItem:[NSMenuItem separatorItem]];
  // Add all rooms to the dropdown menu and set its tag accordingly
  for (int i = 0; i < [[theHouse rooms] count]; i++) {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[[theHouse rooms][i] name] action:NULL keyEquivalent:[[theHouse rooms][i] name]];
    [item setTag:i];
    [[roomPopUpButton menu] addItem:item];
  }
  
  // Set up the device popup button
  [devicePopUpButton removeAllItems];
  
  // Add the unbound device as a option
  NSMenuItem *allTypeItem = [[NSMenuItem alloc] initWithTitle:UNBOUND_COMMANDS_TITLE action:NULL keyEquivalent:UNBOUND_COMMANDS_TITLE];
  // Tag is the number of different iDevices
  [allTypeItem setTag:differentDeviceCount];
  [[devicePopUpButton menu] addItem:allTypeItem];
  // Add a seperator
  [[devicePopUpButton menu] addItem:[NSMenuItem separatorItem]];
  
  // Add weather and calendard
  NSMenuItem *calendarTypeItem = [[NSMenuItem alloc] initWithTitle:CALENDAR_COMMANDS_TITLE action:NULL keyEquivalent:CALENDAR_COMMANDS_TITLE];
  // Tag is the number of different iDevices
  [calendarTypeItem setTag:100];
  [[devicePopUpButton menu] addItem:calendarTypeItem];
  // Add a seperator
  [[devicePopUpButton menu] addItem:[NSMenuItem separatorItem]];
  // Add weather and calendard
  NSMenuItem *weatherTypeItem = [[NSMenuItem alloc] initWithTitle:WEATHER_COMMANDS_TITLE action:NULL keyEquivalent:WEATHER_COMMANDS_TITLE];
  // Tag is the number of different iDevices
  [weatherTypeItem setTag:100];
  [[devicePopUpButton menu] addItem:weatherTypeItem];
  // Add a seperator
  [[devicePopUpButton menu] addItem:[NSMenuItem separatorItem]];
  
  // Add all available devices to the dropdown menu and set its tag accordingly
  for (Room *theRoom in [theHouse rooms]) {
    for (IDevice *theDevice in [theRoom devices]) {
      if ([theDevice deviceTypeHasSelectors:theDevice.type]) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[theDevice name] action:NULL keyEquivalent:[theDevice name]];
        [item setTag:[theDevice type]];
        [[devicePopUpButton menu] addItem:item];
      }
    }
  }
}


/*
 * The user changed the popup button.
 */
- (IBAction)roomPopUpButtonChanged:(id)sender {
  // If any room is selected create dummy room with anroom name and set the room
  if ([[[roomPopUpButton selectedItem] title] isEqualToString:ALL_ROOMS_TITLE]) {
    Room *theRoom = [[Room alloc] init];
    theRoom.name = VoiceCommandAnyRoom;
    [voiceCommand setRoom:theRoom];
  // Else just set the room to the selected one
  } else {
    for (Room* theRoom in [[House sharedHouse] rooms]) {
      if ([[theRoom name] isEqualToString:[[roomPopUpButton selectedItem] title]]) {
        [voiceCommand setRoom:theRoom];
      }
    }
  }
  
  // Reinit the available devices to only show the devices in the selected room
  [devicePopUpButton removeAllItems];
  // Add the unbound device type to the dropdown menu
  NSMenuItem *allTypeItem = [[NSMenuItem alloc] initWithTitle:UNBOUND_COMMANDS_TITLE action:NULL keyEquivalent:UNBOUND_COMMANDS_TITLE];
  [allTypeItem setTag:differentDeviceCount];
  [[devicePopUpButton menu] addItem:allTypeItem];
  // Add a seperator item
  [[devicePopUpButton menu] addItem:[NSMenuItem separatorItem]];
  
  
  // Add weather and calendard
  NSMenuItem *calendarTypeItem = [[NSMenuItem alloc] initWithTitle:CALENDAR_COMMANDS_TITLE action:NULL keyEquivalent:CALENDAR_COMMANDS_TITLE];
  // Tag is the number of different iDevices
  [calendarTypeItem setTag:100];
  [[devicePopUpButton menu] addItem:calendarTypeItem];
  // Add a seperator
  [[devicePopUpButton menu] addItem:[NSMenuItem separatorItem]];
  // Add weather and calendard
  NSMenuItem *weatherTypeItem = [[NSMenuItem alloc] initWithTitle:WEATHER_COMMANDS_TITLE action:NULL keyEquivalent:WEATHER_COMMANDS_TITLE];
  // Tag is the number of different iDevices
  [weatherTypeItem setTag:100];
  [[devicePopUpButton menu] addItem:weatherTypeItem];
  // Add a seperator
  [[devicePopUpButton menu] addItem:[NSMenuItem separatorItem]];
  
  
  House *theHouse = [House sharedHouse];
  // If any room is selected, add all devices
  if ([[[voiceCommand room] name] isEqualToString:VoiceCommandAnyRoom]) {
    // Add all available devices to the dropdown menu and set its tag accordingly
    for (Room *theRoom in [theHouse rooms]) {
      for (IDevice *theDevice in [theRoom devices]) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[theDevice name] action:NULL keyEquivalent:[theDevice name]];
        [item setTag:[theDevice type]];
        [[devicePopUpButton menu] addItem:item];
      }
    }
  // If one room is selected, add only the devices in this room to the dropdown menu
  } else {
    // Add all available devices to the dropdown menu and set its tag accordingly
    for (Room *theRoom in [theHouse rooms]) {
      if ([[theRoom name] isEqualToString:[[voiceCommand room] name]]) {
        for (IDevice *theDevice in [theRoom devices]) {
          NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[theDevice name] action:NULL keyEquivalent:[theDevice name]];
          [item setTag:[theDevice type]];
          [[devicePopUpButton menu] addItem:item];
        }
      }
    }
  }
  // Reset the handler if one was set before and the view
  [voiceCommand setHandler:nil];
  [self setTheVoiceCommandView];
}

/*
 * The user changed the popup button.
 */
- (IBAction)typePopUpButtonChanged:(id)sender {
  // Reset the handler if there was any
  [voiceCommand setHandler:nil];
  // Set the handler according to the selected device
  if ([CALENDAR_COMMANDS_TITLE isEqualToString:[[devicePopUpButton selectedItem] title]]
      && [[devicePopUpButton selectedItem] tag] == 100) {
    NSLog(@"Heurika");
    [voiceCommand setHandler:[Calendar sharedCalendar]];
  } else if ([WEATHER_COMMANDS_TITLE isEqualToString:[[devicePopUpButton selectedItem] title]]
             && [[devicePopUpButton selectedItem] tag] == 100) {
    [voiceCommand setHandler:[Weather sharedWeather]];
    NSLog(@"Heurika");
  } else {
    House *theHouse = [House sharedHouse];
    // Go through all devices and search for the selected device
    for (Room *theRoom in [theHouse rooms]) {
      for (IDevice *theDevice in [theRoom devices]) {
        if ([[theDevice name] isEqualToString:[[devicePopUpButton selectedItem] title]]) {
          [voiceCommand setHandler:theDevice];
        }
      }
    }
  }
  // Reset the view
  [self setTheVoiceCommandView];
}

/*
 * The view is set with the currently set voice command.
 */
-(void)setTheVoiceCommandView {
  // Remove the current view
  NSArray *views = [voiceCommandView subviews];
  for (NSView *view in views) [view removeFromSuperview];
  // And set the view according to the voice command
  voiceCommandsPreferenceViewController = [[VoiceCommandsPreferenceViewController alloc] initWithVoiceCommand:voiceCommand];
  // Notifications should be disabled since the command is not stored yet
  [voiceCommandsPreferenceViewController disableNotifications];
  [[voiceCommandsPreferenceViewController view] setFrame:[voiceCommandView bounds]];
  [[voiceCommandsPreferenceViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [voiceCommandView addSubview:[voiceCommandsPreferenceViewController view]];
}

/*
 * Called if the user pressed the cancel button.
 */
- (IBAction)cancelPressed:(id)sender {
  // Indicate to the delegate that the voice command finished editing
  [delegate newVoiceCommandFinished];
}

/*
 * Called if the user pressed the save button.
 */
- (IBAction)savePressed:(id)sender {
  // Add the voice command to the House
  [[House sharedHouse] addVoiceCommand:voiceCommand :self];
  // Indicate to the delegate that the device finished editing
  [delegate newVoiceCommandFinished];
}

@end
