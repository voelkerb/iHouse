//
//  EditDisplayViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "EditDisplayViewController.h"
#import "TCPServer.h"

#define DEBUG_DISPLAY_EDIT_VIEW true

#define DISPLAY_NOT_SET_LABEL @"not chosen yet"
#define ALERT_BUTTON_SAVE @"Save"
#define ALERT_BUTTON_CANCEL @"Cancel"
#define ALERT_BUTTON_IDENTIFY @"Identify"
#define ALERT_ID_MESSAGE @"Select the Display Host"
#define ALERT_ID_MESSAGE_INFORMAL @"Select the display host from the list of non bound displays. Press identify to identify the selected display."

@interface EditDisplayViewController ()

@end

@implementation EditDisplayViewController
@synthesize display;
@synthesize hostAlertPopup, hostLabel, saveButton, identifyButton;

- (id)initWithDisplay:(Display *)theDisplay {
  if (self = [super init]) {
    display = (Display *) theDisplay;
  }
  return self;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  // Set the id label and indicate if no label was set yet
  if (![display host] || [[display host] isEqualToString:@""]) [hostLabel setStringValue:DISPLAY_NOT_SET_LABEL];
  else [hostLabel setStringValue:[NSString stringWithFormat:@"%@", [display host]]];
}


/*
 * Called if the user wants to change the host
 */
- (IBAction)changeDisplayHost:(id)sender {
  // Add an observer to get devices
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newDisplayDeviceDiscovered:)
                                               name:TCPServerNewSocketDiscovered
                                             object:nil];
  
  
  
  TCPServer *tcpServer = [TCPServer sharedTCPServer];
  [tcpServer discoverSockets:[display discoverCommandResponse]];
  
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
  // If the user pressed save, the hostis stored and the label is updated
  if (returnCode == 1000) {
    [display freeSocket];
    display.host = [[hostAlertPopup selectedItem] title];
    [hostLabel setStringValue:[NSString stringWithFormat:@"%@", [display host]]];
    // Get the socket for the display
    TCPServer *tcpServer = [TCPServer sharedTCPServer];
    [tcpServer stopDiscovering];
    if (DEBUG_DISPLAY_EDIT_VIEW) NSLog(@"took display with host %@", [[tcpServer getSocketWithHost:[display host]] connectedHost]);
    [display deviceConnected:[tcpServer getSocketWithHost:[display host]]];
    
  } // if the user pressed cancel, nothing is done
  
  // Remove the observer for new devices
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TCPServerNewSocketDiscovered object:nil];
}

-(void)identifyClicked:(id)sender {
  NSString *host = [[hostAlertPopup selectedItem] title];
  if (DEBUG_DISPLAY_EDIT_VIEW) NSLog(@"Want to identify %@", host);
  
  Display *identifyDisplay = [[Display alloc] init];
  [identifyDisplay deviceConnected:[[TCPServer sharedTCPServer] getSocketWithHost:host]];
  [identifyDisplay beep];
  NSString *hostSubstring = host;
  while ([hostSubstring rangeOfString:@"."].location != NSNotFound) {
    if ([hostSubstring rangeOfString:@"."].location+1) hostSubstring = [hostSubstring substringFromIndex:[hostSubstring rangeOfString:@"."].location+1];
    else break;
  }
  [identifyDisplay setHeadline:[NSString stringWithFormat:@"   %@", hostSubstring] :display_red];
  [identifyDisplay freeSocket];
}

-(void)newDisplayDeviceDiscovered:(NSNotification*)notification {
  if (DEBUG_DISPLAY_EDIT_VIEW) NSLog(@"newDisplayDeviceDiscovered: %@", [notification object]);
  [hostAlertPopup addItemWithTitle:[notification object]];
  if (![saveButton isEnabled]) [saveButton setEnabled:YES];
  if (![identifyButton isEnabled]) [identifyButton setEnabled:YES];
}

@end
