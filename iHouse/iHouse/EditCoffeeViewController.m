//
//  EditCoffeeViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "EditCoffeeViewController.h"
#define DEBUG_COFFEE_EDIT_VIEW true

#define HOST_NOT_SET_LABEL @"not chosen yet"
#define ALERT_BUTTON_SAVE @"Save"
#define ALERT_BUTTON_CANCEL @"Cancel"
#define ALERT_BUTTON_IDENTIFY @"Identify"
#define ALERT_ID_MESSAGE @"Select the Coffee Host"
#define ALERT_ID_MESSAGE_INFORMAL @"Select the coffee host from the list of non bound coffee machines. Press identify to identify the selected coffee machine."

@interface EditCoffeeViewController ()

@end

@implementation EditCoffeeViewController
@synthesize coffee;
@synthesize hostAlertPopup, hostLabel, saveButton, identifyButton;

- (id)initWithCoffee:(Coffee *)theCoffee {
  if (self = [super init]) {
    coffee = (Coffee *) theCoffee;
  }
  return self;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  // Set the id label and indicate if no label was set yet
  if (![coffee host] || [[coffee host] isEqualToString:@""]) [hostLabel setStringValue:HOST_NOT_SET_LABEL];
  else [hostLabel setStringValue:[NSString stringWithFormat:@"%@", [coffee host]]];
}


/*
 * Called if the user wants to change the device
 */
- (IBAction)changeCoffeeHost:(id)sender {
  // Add an observer to get devices
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newCoffeeDeviceDiscovered:)
                                               name:TCPServerNewSocketDiscovered
                                             object:nil];
  
  
  
  TCPServer *tcpServer = [TCPServer sharedTCPServer];
  [tcpServer discoverSockets:[coffee discoverCommandResponse]];
  
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
    [coffee freeSocket];
    coffee.host = [[hostAlertPopup selectedItem] title];
    [hostLabel setStringValue:[NSString stringWithFormat:@"%@", [coffee host]]];
    // Get the socket for the host
    TCPServer *tcpServer = [TCPServer sharedTCPServer];
    [tcpServer stopDiscovering];
    if (DEBUG_COFFEE_EDIT_VIEW) NSLog(@"took coffee with host %@", [[tcpServer getSocketWithHost:[coffee host]] connectedHost]);
    [coffee deviceConnected:[tcpServer getSocketWithHost:[coffee host]]];
    
  } // if the user pressed cancel, nothing is done
  
  // Remove the observer for new devices
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TCPServerNewSocketDiscovered object:nil];
}

-(void)identifyClicked:(id)sender {
  NSString *host = [[hostAlertPopup selectedItem] title];
  if (DEBUG_COFFEE_EDIT_VIEW) NSLog(@"Want to identify %@", host);
  
  Coffee *identifyCoffee = [[Coffee alloc] init];
  [identifyCoffee deviceConnected:[[TCPServer sharedTCPServer] getSocketWithHost:host]];
  [identifyCoffee factoryReset];
  NSString *hostSubstring = host;
  while ([hostSubstring rangeOfString:@"."].location != NSNotFound) {
    if ([hostSubstring rangeOfString:@"."].location+1) hostSubstring = [hostSubstring substringFromIndex:[hostSubstring rangeOfString:@"."].location+1];
    else break;
  }
  [identifyCoffee freeSocket];
}

-(void)newCoffeeDeviceDiscovered:(NSNotification*)notification {
  if (DEBUG_COFFEE_EDIT_VIEW) NSLog(@"newCoffeeDeviceDiscovered: %@", [notification object]);
  [hostAlertPopup addItemWithTitle:[notification object]];
  if (![saveButton isEnabled]) [saveButton setEnabled:YES];
  if (![identifyButton isEnabled]) [identifyButton setEnabled:YES];
}

@end
