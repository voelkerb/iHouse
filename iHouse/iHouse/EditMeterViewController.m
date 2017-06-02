//
//  EditMeterViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "EditMeterViewController.h"
#import "House.h"

#define DEBUG_EDIT_METER false

#define COMMAND_RESPONSE @"/"
#define COMMAND_METER @"m"
#define COMMAND_SEPERATOR @";"
#define METER_NOT_SET_LABEL @"not chosen yet"
#define ALERT_BUTTON_SAVE @"Save"
#define ALERT_BUTTON_CANCEL @"Cancel"
#define ALERT_ID_MESSAGE @"Select the Meter ID"
#define ALERT_ID_MESSAGE_INFORMAL @"Select the Meter ID from the list of non bound meters."



@interface EditMeterViewController ()

@end

@implementation EditMeterViewController
@synthesize myMeter, idAlertPopup, idLabel, saveButton;

- (id)initWithMeter:(Meter *)theMeter {
  if (self = [super init]) {
    // Get the pointer to the meter
    myMeter =  theMeter;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Set the id label and indicate if no label was set yet
  if ([myMeter meterID] == 0) [idLabel setStringValue:METER_NOT_SET_LABEL];
  else [idLabel setStringValue:[NSString stringWithFormat:@"%li", [myMeter meterID]]];
}

/*
 * Called if new data was received over serial. If this is meterdata and did not belong to a 
 * yet stored socket, it is added to a popup button.
 */
- (void)newMeterData:(NSNotification*)notification {
  // Get the command and construct the prefix
  NSString *theCommand = [notification object];
  NSString *cmdPrefix = [NSString stringWithFormat:@"%@%@", COMMAND_RESPONSE, COMMAND_METER];
  if (DEBUG_EDIT_METER) NSLog(@"%@", theCommand);
  // If the beginning of the string contains the meter prefix
  if ([[theCommand substringToIndex:[cmdPrefix length]] containsString:cmdPrefix]) {
    // Get the ID
    NSString *theIDasString = [theCommand substringFromIndex:[cmdPrefix length]];
    theIDasString = [theIDasString substringToIndex:[theIDasString rangeOfString:COMMAND_SEPERATOR].location];
    NSInteger theID = [theIDasString integerValue];
    
    // If the ID is already in the popup, return
    if ([idAlertPopup itemWithTitle:[NSString stringWithFormat:@"ID: %li", theID]]) return;
    
    // If not, look if a meter device is already using this id
    House *theHouse = [House sharedHouse];
    BOOL alreadyExists = false;
    for (Room *theRoom in [theHouse rooms]) {
      for (IDevice *theDevice in [theRoom devices]) {
        if ([theDevice type] == meter) {
          if ([(Meter*)[theDevice theDevice] meterID] == theID) {
            alreadyExists = true;
          }
        }
      }
    }
    // If no device is using the id, set the name and tag in the popup
    if (!alreadyExists) {
      [idAlertPopup addItemWithTitle:[NSString stringWithFormat:@"ID: %li", theID]];
      [[idAlertPopup itemWithTitle:[NSString stringWithFormat:@"ID: %li", theID]] setTag:theID];
      // Enabe the save button
      if (![saveButton isEnabled]) [saveButton setEnabled:YES];
    }
  }
}

/*
 * Called if the user wants to change the MeterID
 */
- (IBAction)changeMeterID:(id)sender {
  // Add an observer to get meter data
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newMeterData:)
                                               name:SerialConnectionHandlerSerialResponse
                                             object:nil];
  // And show the uppopping alert sheet
  [self showEditIDAlert];
}


/*
 * Show an alert where new meter devices are presented in a popup button.
 */
-(void)showEditIDAlert {
  // The accessory view of the alert sheet
  NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 180, 30)];
  // Add the PopUp button to the accessory view of the alert sheet
  idAlertPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 150, 24)];
  // Add a spinner as well to indicate that the search process has started
  NSProgressIndicator *spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(160, 3, 18, 18)];
  [spinner setStyle:NSProgressIndicatorSpinningStyle];
  [spinner startAnimation:self];
  NSArray *array = [NSArray arrayWithObjects:idAlertPopup, spinner, nil];
  [view setSubviews:array];
  
  // Init the alert sheet with buttons, text and accessory view
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:ALERT_ID_MESSAGE];
  [alert setInformativeText:ALERT_ID_MESSAGE_INFORMAL];
  [alert addButtonWithTitle:ALERT_BUTTON_SAVE];
  [alert addButtonWithTitle:ALERT_BUTTON_CANCEL];
  [alert setAccessoryView:view];
  
  // Get the save button from the alert sheet and disable it
  NSArray *buttons = [alert buttons];
  for (NSButton *theButton in buttons) {
    if ([theButton.title isEqualToString:ALERT_BUTTON_SAVE]) saveButton = theButton;
  }
  [saveButton setEnabled:NO];
  
  long returnCode = [alert runModal];
  // If the user pressed save, the meterID is stored and the label is updated
  if (returnCode == 1000) {
    myMeter.meterID = [[idAlertPopup selectedItem] tag];
    [idLabel setStringValue:[NSString stringWithFormat:@"%li", [myMeter meterID]]];
  } // if the user pressed cancel, nothing is done
  
  // Remove the observer for new meter devices
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SerialConnectionHandlerSerialResponse object:nil];
}

@end
