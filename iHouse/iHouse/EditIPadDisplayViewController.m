//
//  EditTVViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "EditIPadDisplayViewController.h"
#import "TCPServer.h"


#define DEBUG_IPAD_EDIT_VIEW true

#define HOST_NOT_SET_LABEL @"not chosen yet"
#define ALERT_BUTTON_SAVE @"Save"
#define ALERT_BUTTON_CANCEL @"Cancel"
#define ALERT_BUTTON_IDENTIFY @"Identify"
#define ALERT_ID_MESSAGE @"Select the Remote Host"
#define ALERT_ID_MESSAGE_INFORMAL @"Select the remote host from the list of non bound remotes. Press identify to identify the selected remote device."

@interface EditIPadDisplayViewController ()

@end

@implementation EditIPadDisplayViewController
@synthesize iPadDisplay;

@synthesize hostAlertPopup, hostLabel, saveButton, identifyButton;

- (id)initWithIPadDisplay:(IPadDisplay *)theIPadDisplay {
  if (self = [super init]) {
    if ([theIPadDisplay isKindOfClass:[IPadDisplay class]]) iPadDisplay = (IPadDisplay *) theIPadDisplay;
    else iPadDisplay = [[IPadDisplay alloc] init];
  }
  return self;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  // Set the id label and indicate if no label was set yet
  if (![iPadDisplay host] || [[iPadDisplay host] isEqualToString:@""]) [hostLabel setStringValue:HOST_NOT_SET_LABEL];
  else [hostLabel setStringValue:[NSString stringWithFormat:@"%@", [iPadDisplay host]]];
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
  [tcpServer discoverSockets:[iPadDisplay discoverCommandResponse]];
  
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
    [iPadDisplay freeSocket];
    iPadDisplay.host = [[hostAlertPopup selectedItem] title];
    [hostLabel setStringValue:[NSString stringWithFormat:@"%@", [iPadDisplay host]]];
    // Get the socket for the device
    TCPServer *tcpServer = [TCPServer sharedTCPServer];
    [tcpServer stopDiscovering];
    if (DEBUG_IPAD_EDIT_VIEW) NSLog(@"took remote with host %@", [[tcpServer getSocketWithHost:[iPadDisplay host]] connectedHost]);
    [iPadDisplay deviceConnected:[tcpServer getSocketWithHost:[iPadDisplay host]]];
    
  } // if the user pressed cancel, nothing is done
  
  // Remove the observer for new devices
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TCPServerNewSocketDiscovered object:nil];
}

/*
 * If the user presses identify, let the hoover blink.
 */
-(void)identifyClicked:(id)sender {
  NSString *host = [[hostAlertPopup selectedItem] title];
  if (DEBUG_IPAD_EDIT_VIEW) NSLog(@"Want to identify %@", host);
  IPadDisplay *identifyDisplay = [[IPadDisplay alloc] init];
  identifyDisplay.autoSync = false;
  [identifyDisplay deviceConnected:[[TCPServer sharedTCPServer] getSocketWithHost:host]];
  [identifyDisplay identify];
  [identifyDisplay freeSocket];
}

/*
 * If new hoover devices connected.
 */
-(void)newHooverDeviceDiscovered:(NSNotification*)notification {
  if (DEBUG_IPAD_EDIT_VIEW) NSLog(@"newRemoteDeviceDiscovered: %@", [notification object]);
  [hostAlertPopup addItemWithTitle:[notification object]];
  if (![saveButton isEnabled]) [saveButton setEnabled:YES];
  if (![identifyButton isEnabled]) [identifyButton setEnabled:YES];
}

@end
