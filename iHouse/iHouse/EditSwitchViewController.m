//
//  EditSwitchViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 11.02.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "EditSwitchViewController.h"
#import "House.h"

#define DEBUG_SWITCH_EDIT_VIEW 1

#define ALERT_BUTTON_OK @"Ok"
#define ALERT_BUTTON_CANCEL @"Cancel"
#define ALERT_SNIFFING_MESSAGE @"Learning Switch Device"
#define ALERT_SNIFFING_MESSAGE_INFORMAL @"Press the button on the remote of the switch."

@interface EditSwitchViewController ()

@end

@implementation EditSwitchViewController
@synthesize RCSwitch, devicePopUp, actionPopUp, codeTextField, sniffAlert;

- (id)initWithSwitch:(Switch *)theSwitch {
  if (self = [super init]) {
    // Get the pointer of the device
    RCSwitch =  theSwitch;
  }
  return self;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Select the current action in the popup button
  //[socketTypePopupButton selectItemWithTag:[socket type]];
  [codeTextField setStringValue:[RCSwitch cmiTristate]];
  
  // Init the action popup button with title and tags
  [devicePopUp removeAllItems];
  [actionPopUp removeAllItems];
  
  IDevice *switchDevice = nil;
  switchDevice = [[RCSwitch switchItem] objectForKey:KeySwitchItemDevice];
  NSString *switchSelector = @"";
  switchSelector = [[RCSwitch switchItem] objectForKey:KeySwitchItemSelector];
  Group *switchGroup = nil;
  switchGroup = [[RCSwitch switchItem] objectForKey:KeySwitchItemGroup];
  
  for (Room *theRoom in [[House sharedHouse] rooms]) {
    for (IDevice *theDevice in [theRoom devices]) {
      // If this is not a switch
      if (theDevice.type != rcSwitch) {
        [devicePopUp addItemWithTitle:[theDevice name]];
        // If this is a switch for a device
        if (switchDevice) {
          // Display all available selectors
          if ([switchDevice.name isEqualToString:[theDevice name]]) {
            [actionPopUp removeAllItems];
            NSArray *selectors = [[NSArray alloc] initWithArray:[theDevice voiceCommandSelectors]];
            NSArray *selectorsReadable = [[NSArray alloc] initWithArray:[theDevice voiceCommandSelectorsReadable]];
            if (DEBUG_SWITCH_EDIT_VIEW) NSLog(@"Available Selectors: %@", selectors);
            NSInteger i = 0;
            for (NSString *selector in selectorsReadable) {
              [actionPopUp addItemWithTitle:selector];
              [[actionPopUp lastItem] setTag:i];
              if ([[selectors objectAtIndex:i] isEqualToString:switchSelector]) {
                [actionPopUp selectItemWithTag:i];
              }
              i++;
            }
          }
        }
      }
    }
  }
  // Add separator
  [[devicePopUp menu] addItem:[NSMenuItem separatorItem]];
  
  // Now also add groups
  for (Group *theGroup in [[House sharedHouse] groups]) {
    [devicePopUp addItemWithTitle:[theGroup name]];
    // Add the all commands filter mode with tag = total amount of different devices
    //NSMenuItem *deviceItem = [[NSMenuItem alloc] initWithTitle:[theGroup name] action:NULL keyEquivalent:[theGroup name]];
    // Tag is the number of different iDevices
    //[[devicePopUp menu] addItem:deviceItem];
  }
  
  
  
  if (switchDevice) {
    [devicePopUp selectItemWithTitle:switchDevice.name];
  } else if (switchGroup) {
    [devicePopUp selectItemWithTitle:switchGroup.name];
    // Disable action popup for group
    [actionPopUp removeAllItems];
    [actionPopUp setEnabled:NO];
  } else {
    [devicePopUp selectItemAtIndex:-1];
  }
  // Highlight selected selector.
  if (switchSelector == nil) {
    [actionPopUp selectItemAtIndex:-1];
  }
}

- (IBAction)actionPopUpChanged:(id)sender {
  if (DEBUG_SWITCH_EDIT_VIEW) NSLog(@"ActionPopup Changed to: %@", [[actionPopUp selectedItem] title]);
  NSMutableDictionary *switchItem = [RCSwitch switchItem];
  IDevice *switchDevice = nil;
  switchDevice = [switchItem objectForKey:KeySwitchItemDevice];
  if (switchDevice != nil) {
    NSArray *selectors = [[NSArray alloc] initWithArray:[switchDevice voiceCommandSelectors]];
    NSArray *selectorsReadable = [[NSArray alloc] initWithArray:[switchDevice voiceCommandSelectorsReadable]];
    NSInteger index = [selectorsReadable indexOfObject:[[actionPopUp selectedItem] title]];
    if ([selectors objectAtIndex:index]) {
      [[RCSwitch switchItem] setObject:[selectors objectAtIndex:index] forKey:KeySwitchItemSelector];
    }
  }
}

- (IBAction)devicePopUpChanged:(id)sender {
  
  if (DEBUG_SWITCH_EDIT_VIEW) NSLog(@"DevicePopup Changed to: %@", [[devicePopUp selectedItem] title]);
  for (Room *theRoom in [[House sharedHouse] rooms]) {
    for (IDevice *theDevice in [theRoom devices]) {
      if ([[[devicePopUp selectedItem] title] isEqualToString:[theDevice name]]) {
        [[RCSwitch switchItem] removeAllObjects];
        [[RCSwitch switchItem] setObject:theDevice forKey:KeySwitchItemDevice];
      }
    }
  }
  for (Group *theGroup in [[House sharedHouse] groups]) {
      if ([[[devicePopUp selectedItem] title] isEqualToString:[theGroup name]]) {
        [[RCSwitch switchItem] removeAllObjects];
        [[RCSwitch switchItem] setObject:theGroup forKey:KeySwitchItemGroup];
      }
  }
  if ([[RCSwitch switchItem] objectForKey:KeySwitchItemGroup]) {
    [actionPopUp removeAllItems];
    [actionPopUp setEnabled:NO];
    [actionPopUp selectItemAtIndex:-1];
  } else if ([[RCSwitch switchItem] objectForKey:KeySwitchItemDevice]) {
    IDevice *device = [[RCSwitch switchItem] objectForKey:KeySwitchItemDevice];
    [actionPopUp setEnabled:YES];
    [actionPopUp removeAllItems];
    NSArray *selectors = [[NSArray alloc] initWithArray:[device voiceCommandSelectors]];
    NSArray *selectorsReadable = [[NSArray alloc] initWithArray:[device voiceCommandSelectorsReadable]];
    if (DEBUG_SWITCH_EDIT_VIEW) NSLog(@"Available Selectors: %@", selectors);
    NSInteger i = 0;
    for (NSString *selector in selectorsReadable) {
      [actionPopUp addItemWithTitle:selector];
      [[actionPopUp lastItem] setTag:i];
      i++;
    }
    [actionPopUp selectItemAtIndex:-1];
  }
  
}
/*
 * Called if the user pressed the sniff cmi button
 */
- (IBAction)sniffButton:(id)sender {
  // Let the switch sniff cmi
  [RCSwitch sniffCMI];
  // Add an observer to get response if sniffed succesfully
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(sniffedSuccessfully:)
                                               name:SwitchSniffedSuccessfully
                                             object:nil];
  // Init the alertsheet that pops up displaying that the button on the remote needs to be pressed
  sniffAlert = [[NSAlert alloc] init];
  [sniffAlert addButtonWithTitle:ALERT_BUTTON_CANCEL];
  [sniffAlert setMessageText:ALERT_SNIFFING_MESSAGE];
  [sniffAlert setInformativeText:ALERT_SNIFFING_MESSAGE_INFORMAL];
  [sniffAlert setAlertStyle:NSWarningAlertStyle];
  long response = [sniffAlert runModal];
  if (response == NSAlertFirstButtonReturn) {
    // If the user pressed cancel, stop sniffing
    [RCSwitch sniffCMIDismissed];
  }
}

/*
 * Called if the sniff finished succesfully. The alert sheet is dismissed
 */
- (void) sniffedSuccessfully:(NSNotification*) notification {
  // Update the tristate value and dismiss the alert sheet
  [codeTextField setStringValue:[RCSwitch cmiTristate]];
  [NSApp endSheet: [sniffAlert window]];
}

/*
 * Called if the user pressed the sniff cmi button
 */
- (IBAction)testButtonPressed:(id)sender {
  [RCSwitch activate];
}

@end
