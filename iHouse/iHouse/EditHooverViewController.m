//
//  EditHooverViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "EditHooverViewController.h"

#import "TCPServer.h"

#define DEBUG_HOOVER_EDIT_VIEW true

#define HOST_NOT_SET_LABEL @"not chosen yet"
#define ALERT_BUTTON_SAVE @"Save"
#define ALERT_BUTTON_CANCEL @"Cancel"
#define ALERT_BUTTON_IDENTIFY @"Identify"
#define ALERT_ID_MESSAGE @"Select the Hoover Host"
#define ALERT_ID_MESSAGE_INFORMAL @"Select the hover host from the list of non bound hoovers. Press identify to identify the selected hoover device."


@interface EditHooverViewController ()

@end

@implementation EditHooverViewController
@synthesize hoover;
@synthesize hostAlertPopup, hostLabel, saveButton, identifyButton;

- (id)initWithHoover:(Hoover *)theHoover {
  if (self = [super init]) {
    hoover = (Hoover *) theHoover;
  }
  return self;
}



- (void)viewDidLoad {
  [super viewDidLoad];
  // Set the id label and indicate if no label was set yet
  if (![hoover host] || [[hoover host] isEqualToString:@""]) [hostLabel setStringValue:HOST_NOT_SET_LABEL];
  else [hostLabel setStringValue:[NSString stringWithFormat:@"%@", [hoover host]]];
}


/*
 * Called if the user wants to change the host.
 */
- (IBAction)changeHost:(id)sender {
  // Add an observer to get devices
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newHooverDeviceDiscovered:)
                                               name:TCPServerNewSocketDiscovered
                                             object:nil];
  
  
  
  TCPServer *tcpServer = [TCPServer sharedTCPServer];
  [tcpServer discoverSockets:[hoover discoverCommandResponse]];
  
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
    [hoover freeSocket];
    hoover.host = [[hostAlertPopup selectedItem] title];
    [hostLabel setStringValue:[NSString stringWithFormat:@"%@", [hoover host]]];
    // Get the socket for the device
    TCPServer *tcpServer = [TCPServer sharedTCPServer];
    [tcpServer stopDiscovering];
    if (DEBUG_HOOVER_EDIT_VIEW) NSLog(@"took hoover with host %@", [[tcpServer getSocketWithHost:[hoover host]] connectedHost]);
    [hoover deviceConnected:[tcpServer getSocketWithHost:[hoover host]]];
    
  } // if the user pressed cancel, nothing is done
  
  // Remove the observer for new devices
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TCPServerNewSocketDiscovered object:nil];
}

/*
 * If the user presses identify, let the hoover blink.
 */
-(void)identifyClicked:(id)sender {
  NSString *host = [[hostAlertPopup selectedItem] title];
  if (DEBUG_HOOVER_EDIT_VIEW) NSLog(@"Want to identify %@", host);
  Hoover *identifyHoover = [[Hoover alloc] init];
  [identifyHoover deviceConnected:[[TCPServer sharedTCPServer] getSocketWithHost:host]];
  [identifyHoover identify];
  [identifyHoover freeSocket];
}

/*
 * If new hoover devices connected.
 */
-(void)newHooverDeviceDiscovered:(NSNotification*)notification {
  if (DEBUG_HOOVER_EDIT_VIEW) NSLog(@"newHooverDeviceDiscovered: %@", [notification object]);
  [hostAlertPopup addItemWithTitle:[notification object]];
  if (![saveButton isEnabled]) [saveButton setEnabled:YES];
  if (![identifyButton isEnabled]) [identifyButton setEnabled:YES];
}

@end
