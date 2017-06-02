//
//  EditSocketViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "EditSocketViewController.h"
#define TYPE_FREETEC @"FreeTec"
#define TYPE_CMI @"CMI"
#define TYPE_CONRAD @"Conrad"

#define ALERT_BUTTON_OK @"Ok"
#define ALERT_BUTTON_CANCEL @"Cancel"
#define ALERT_LEARNING_MESSAGE @"Learning Freetec Device"
#define ALERT_LEARNING_MESSAGE_INFORMAL @"Press the Learn Button on the FreeTec socket and click okay."
#define ALERT_SNIFFING_MESSAGE @"Learning CMI Device"
#define ALERT_SNIFFING_MESSAGE_INFORMAL @"Press the button on the remote of the CMI socket."

@interface EditSocketViewController ()

@end

@implementation EditSocketViewController
@synthesize socket, socketTypePopupButton, conradView, freetecView, cmiView, cmiCodeTextField, typeDependingView, conradGroupPopup, conradNumberPopup, sniffAlert;

- (id)initWithSocket:(Socket *)theSocket {
  if (self = [super init]) {
    // Get the pointer of the device
    socket =  theSocket;
    lastLightType = 0;
  }
  return self;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Init the socket type popup button with title and tags
  [socketTypePopupButton removeAllItems];
  [socketTypePopupButton addItemWithTitle:TYPE_FREETEC];
  [[socketTypePopupButton itemWithTitle:TYPE_FREETEC] setTag:freeTec_socket];
  [socketTypePopupButton addItemWithTitle:TYPE_CMI];
  [[socketTypePopupButton itemWithTitle:TYPE_CMI] setTag:cmi_socket];
  [socketTypePopupButton addItemWithTitle:TYPE_CONRAD];
  [[socketTypePopupButton itemWithTitle:TYPE_CONRAD] setTag:conrad_socket];
  // Select the current socket type in the popup button
  [socketTypePopupButton selectItemWithTag:[socket type]];
  [cmiCodeTextField setStringValue:[socket cmiTristate]];
  // Set the conrad popup button with title and tag
  [conradNumberPopup removeAllItems];
  [conradGroupPopup removeAllItems];
  for (int i = 1; i <= 4; i++) {
    [conradGroupPopup addItemWithTitle:[NSString stringWithFormat:@"%i", i]];
    [[conradGroupPopup itemWithTitle:[NSString stringWithFormat:@"%i", i]] setTag:i];
    [conradNumberPopup addItemWithTitle:[NSString stringWithFormat:@"%i", i]];
    [[conradNumberPopup itemWithTitle:[NSString stringWithFormat:@"%i", i]] setTag:i];
  }
  // Select the current group of the conrad buttons
  [conradGroupPopup selectItemWithTag:[socket conradGroup]];
  [conradNumberPopup selectItemWithTag:[socket conradNumber]];
  
  // Set the view to the current selected type
  [self socketTypePopupChanged:self];
}

/*
 * Called if the user updates the type popup. Sets the view accordingly to the selected type.
 */
- (IBAction)socketTypePopupChanged:(id)sender {
  //if ([sender tag] == lastLightType) return;
  //else lastLightType = [sender tag];
  
  // Remove the current views
  NSArray *subviews = [typeDependingView subviews];
  for (NSView *theView in subviews)[theView removeFromSuperview];
  
  // Set the view according to the selected type and update the type
  if ([[[socketTypePopupButton selectedItem] title] isEqualToString:TYPE_FREETEC]) {
    [typeDependingView addSubview:freetecView];
    [freetecView setFrame:[typeDependingView bounds]];
    [freetecView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    socket.type = freeTec_socket;
  } else if ([[[socketTypePopupButton selectedItem] title] isEqualToString:TYPE_CMI]) {
    [typeDependingView addSubview:cmiView];
    [cmiView setFrame:[typeDependingView bounds]];
    [cmiView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    socket.type = cmi_socket;
  } else if ([[[socketTypePopupButton selectedItem] title] isEqualToString:TYPE_CONRAD]) {
    [typeDependingView addSubview:conradView];
    [conradView setFrame:[typeDependingView bounds]];
    [conradView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    socket.type = conrad_socket;
  }
}

/*
 * Called if the user pressed the sniff smi button
 */
- (IBAction)cmiSniffButton:(id)sender {
  // Let the socket sniff cmi
  [socket sniffCMI];
  // Add an observer to get response if sniffed succesfully
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(sniffedSuccessfully:)
                                               name:SocketSniffedSuccessfully
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
    [socket sniffCMIDismissed];
  }
  // Toggle to off
  [socket toggle:false];
}

/*
 * Called if the sniff finished succesfully. The alert sheet is dismissed
 */
- (void) sniffedSuccessfully:(NSNotification*) notification {
  // Update the tristate value and dismiss the alert sheet
  [cmiCodeTextField setStringValue:[socket cmiTristate]];
  [NSApp endSheet: [sniffAlert window]];
}

/*
 * Called if the user wants to learn a freetec device
 */
- (IBAction)freetecLearnButton:(id)sender {
  // Let the socket learn itself
  [socket learnFreetec];
  // Display alertsheet that the user needs to press the learn button on the freetec device
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:ALERT_BUTTON_OK];
  [alert addButtonWithTitle:ALERT_BUTTON_CANCEL];
  [alert setMessageText:ALERT_LEARNING_MESSAGE];
  [alert setInformativeText:ALERT_LEARNING_MESSAGE_INFORMAL];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
  // On finish toggle the device to false
  [socket toggle:false];
}


/*
 * Called if the user changed the group of the conrad device
 */
-(IBAction)conradGroupChanged:(id)sender {
  socket.conradGroup = [[conradGroupPopup selectedItem] tag];
}

/*
 * Called if the user changed the number of the conrad device
 */
- (IBAction)conradNumberChanged:(id)sender {
  socket.conradNumber = [[conradNumberPopup selectedItem] tag];
}


@end
