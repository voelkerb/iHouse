//
//  EditMicrophoneViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "EditMicrophoneViewController.h"

#define DEBUG_MICRO_EDIT_VIEW true
#define ID_NOT_SET_LABEL @"not chosen yet"
#define ALERT_BUTTON_SAVE @"Save"
#define ALERT_BUTTON_CANCEL @"Cancel"
#define ALERT_BUTTON_IDENTIFY @"Identify"
#define ALERT_ID_MESSAGE @"Select the Microphone ID"
#define ALERT_ID_MESSAGE_INFORMAL @"Select the microphone id from the list. Press identify to identify the selected microphone."
#define MAX_NUMBER_MICROS 5

@interface EditMicrophoneViewController ()

@end

@implementation EditMicrophoneViewController
@synthesize microphone;
@synthesize hostAlertPopup, hostLabel, saveButton, identifyButton;


- (id)initWithMicrophone:(Microphone *)theMicrophone {
  if (self = [super init]) {
    microphone = (Microphone *) theMicrophone;
  }
  return self;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  // Set the id label and indicate if no label was set yet
  if ([microphone micID] == -1 || [microphone micID] == 0) [hostLabel setStringValue:ID_NOT_SET_LABEL];
  else [hostLabel setStringValue:[NSString stringWithFormat:@"%li", [microphone micID]]];
}


/*
 * Called if the user wants to change the device
 */
- (IBAction)changeMicroID:(id)sender {
  // And show the uppopping alert sheet
  [self showEditIDAlert];
}


/*
 * Show an alert where new devices are presented in a popup button.
 */
-(void)showEditIDAlert {
  
  // The accessory view of the alert sheet
  NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 280, 24)];
  // Add the PopUp button to the accessory view of the alert sheet
  hostAlertPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 150, 24)];
  // Add all possible micro ids
  for (int i = 1; i <= MAX_NUMBER_MICROS; i++) {
    [hostAlertPopup addItemWithTitle:[NSString stringWithFormat:@"%i", i]];
  }
  identifyButton = [[NSButton alloc] initWithFrame:NSMakeRect(200, 0, 80, 24)];
  [identifyButton setTitle:ALERT_BUTTON_IDENTIFY];
  [identifyButton setButtonType:NSMomentaryLightButton]; //Set what type button You want
  [identifyButton setBezelStyle:NSRoundedBezelStyle];
  [identifyButton setTarget:self];
  [identifyButton setAction:@selector(identifyClicked:)];
  NSArray *array = [NSArray arrayWithObjects:hostAlertPopup, identifyButton, nil];
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
  
  long returnCode = [alert runModal];
  // If the user pressed save, the host is stored and the label is updated
  if (returnCode == 1000) {
    microphone.micID = [[[hostAlertPopup selectedItem] title] integerValue];
    [hostLabel setStringValue:[NSString stringWithFormat:@"%li", [microphone micID]]];
    if (DEBUG_MICRO_EDIT_VIEW) NSLog(@"took micro with id %li", [microphone micID]);
  } // if the user pressed cancel, nothing is done
  
  // Remove the observer for new devices
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TCPServerNewSocketDiscovered object:nil];
}

-(void)identifyClicked:(id)sender {
  NSInteger micID = [[[hostAlertPopup selectedItem] title] integerValue];
  if (DEBUG_MICRO_EDIT_VIEW) NSLog(@"Want to identify %li", micID);
  Microphone *identifyMicrophone = [[Microphone alloc] init];
  identifyMicrophone.micID = micID;
  // Will dismiss automatically after given delay
  [identifyMicrophone audioOn];
  [identifyMicrophone performSelector:@selector(audioOff) withObject:nil afterDelay:2];
}

@end
