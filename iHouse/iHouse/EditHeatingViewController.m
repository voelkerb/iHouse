//
//  EditHeatingViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "EditHeatingViewController.h"
#import "TCPServer.h"

#define DEBUG_HEATING_EDIT_VIEW true

#define HOST_NOT_SET_LABEL @"not chosen yet"
#define ALERT_BUTTON_SAVE @"Save"
#define ALERT_BUTTON_CANCEL @"Cancel"
#define ALERT_BUTTON_IDENTIFY @"Identify"
#define ALERT_ID_MESSAGE @"Select the Heating Host"
#define ALERT_ID_MESSAGE_INFORMAL @"Select the heating host from the list of non bound heatings. Press identify to identify the selected heating device."

@interface EditHeatingViewController ()

@end

@implementation EditHeatingViewController
@synthesize heating;
@synthesize hostAlertPopup, hostLabel, saveButton, identifyButton;

- (id)initWithHeating:(Heating *)theHeating {
  if (self = [super init]) {
    heating = (Heating *) theHeating;
  }
  return self;
}



- (void)viewDidLoad {
  [super viewDidLoad];
  // Set the id label and indicate if no label was set yet
  if (![heating host] || [[heating host] isEqualToString:@""]) [hostLabel setStringValue:HOST_NOT_SET_LABEL];
  else [hostLabel setStringValue:[NSString stringWithFormat:@"%@", [heating host]]];
}


/*
 * Called if the user wants to change the device
 */
- (IBAction)changeHeatingHost:(id)sender {
  // Add an observer to get devices
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newHeatingDeviceDiscovered:)
                                               name:TCPServerNewSocketDiscovered
                                             object:nil];
    
  TCPServer *tcpServer = [TCPServer sharedTCPServer];
  [tcpServer discoverSockets:[heating discoverCommandResponse]];
  
  // And show the uppopping alert sheet
  [self showEditHostAlert];
}


/*
 * Show an alert where new devices are presented in a popup button.
 */
-(void)showEditHostAlert {
  
  // The accessory view of the alert sheet
  NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 280, 24)];
  // Add the PopUp button to the accessory view of the alert sheet
  hostAlertPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 150, 24)];
  // Add a spinner as well to indicate that the search process has started
  NSProgressIndicator *spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(160, 3, 18, 18)];
  identifyButton = [[NSButton alloc] initWithFrame:NSMakeRect(200, 0, 80, 24)];
  [identifyButton setTitle:ALERT_BUTTON_IDENTIFY];
  [identifyButton setButtonType:NSMomentaryLightButton]; //Set what type button You want
  [identifyButton setBezelStyle:NSRoundedBezelStyle];
  [identifyButton setTarget:self];
  [identifyButton setAction:@selector(identifyClicked:)];
  [spinner setStyle:NSProgressIndicatorSpinningStyle];
  [spinner startAnimation:self];
  NSArray *array = [NSArray arrayWithObjects:hostAlertPopup, spinner, identifyButton, nil];
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
  [identifyButton setEnabled:NO];
  
  long returnCode = [alert runModal];
  // If the user pressed save, the host is stored and the label is updated
  if (returnCode == 1000) {
    [heating freeSocket];
    heating.host = [[hostAlertPopup selectedItem] title];
    [hostLabel setStringValue:[NSString stringWithFormat:@"%@", [heating host]]];
    // Get the socket for the devices
    TCPServer *tcpServer = [TCPServer sharedTCPServer];
    [tcpServer stopDiscovering];
    if (DEBUG_HEATING_EDIT_VIEW) NSLog(@"took heating with host %@", [[tcpServer getSocketWithHost:[heating host]] connectedHost]);
    [heating deviceConnected:[tcpServer getSocketWithHost:[heating host]]];
    
  } // if the user pressed cancel, nothing is done
  
  // Remove the observer for new devices
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TCPServerNewSocketDiscovered object:nil];
}

/*
 * If the user pressed Identify the heating is boosted
 */
-(void)identifyClicked:(id)sender {
  NSString *host = [[hostAlertPopup selectedItem] title];
  if (DEBUG_HEATING_EDIT_VIEW) NSLog(@"Want to identify %@", host);
  Heating *identifyHeating = [[Heating alloc] init];
  [identifyHeating deviceConnected:[[TCPServer sharedTCPServer] getSocketWithHost:host]];
  [identifyHeating boost];
  [identifyHeating freeSocket];
}

/*
 * If a new host was detected.
 */
-(void)newHeatingDeviceDiscovered:(NSNotification*)notification {
  if (DEBUG_HEATING_EDIT_VIEW) NSLog(@"newHeatingDeviceDiscovered: %@", [notification object]);
  [hostAlertPopup addItemWithTitle:[notification object]];
  if (![saveButton isEnabled]) [saveButton setEnabled:YES];
  if (![identifyButton isEnabled]) [identifyButton setEnabled:YES];
}

@end
