//
//  EditLightViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "EditLightViewController.h"
#define TYPE_FREETEC @"FreeTec"
#define TYPE_CMI @"CMI"
#define TYPE_CONRAD @"Conrad"

#define ALERT_BUTTON_OK @"Ok"
#define ALERT_BUTTON_CANCEL @"Cancel"
#define ALERT_LEARNING_MESSAGE @"Learning Freetec Device"
#define ALERT_LEARNING_MESSAGE_INFORMAL @"Press the Learn Button on the FreeTec light and click okay."
#define ALERT_SNIFFING_MESSAGE @"Learning CMI Device"
#define ALERT_SNIFFING_MESSAGE_INFORMAL @"Press the button on the remote of the CMI light."


@interface EditLightViewController ()

@end

@implementation EditLightViewController
@synthesize light, lightTypePopupButton, conradView, freetecView, cmiView, cmiCodeTextField, typeDependingView, conradGroupPopup, conradNumberPopup, sniffAlert;

- (id)initWithLight:(Light *)theLight {
    if (self = [super init]) {
      // Get the pointer of the device
      light =  theLight;
      lastLightType = 0;
    }
    return self;
  }



- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Init the light type popup button with title and tags
  [lightTypePopupButton removeAllItems];
  [lightTypePopupButton addItemWithTitle:TYPE_FREETEC];
  [[lightTypePopupButton itemWithTitle:TYPE_FREETEC] setTag:freeTec_light];
  [lightTypePopupButton addItemWithTitle:TYPE_CMI];
  [[lightTypePopupButton itemWithTitle:TYPE_CMI] setTag:cmi_light];
  [lightTypePopupButton addItemWithTitle:TYPE_CONRAD];
  [[lightTypePopupButton itemWithTitle:TYPE_CONRAD] setTag:conrad_light];
  // Select the current light type in the popup button
  [lightTypePopupButton selectItemWithTag:[light type]];
  [cmiCodeTextField setStringValue:[light cmiTristate]];
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
  [conradGroupPopup selectItemWithTag:[light conradGroup]];
  [conradNumberPopup selectItemWithTag:[light conradNumber]];
  
  // Set the view to the current selected type
  [self lightTypePopupChanged:self];
}

/*
 * Called if the user updates the type popup. Sets the view accordingly to the selected type.
 */
- (IBAction)lightTypePopupChanged:(id)sender {
  //if ([sender tag] == lastLightType) return;
  //else lastLightType = [sender tag];
  
  // Remove the current views
  NSArray *subviews = [typeDependingView subviews];
  for (NSView *theView in subviews)[theView removeFromSuperview];
  
  // Set the view according to the selected type and update the type
  if ([[[lightTypePopupButton selectedItem] title] isEqualToString:TYPE_FREETEC]) {
    [typeDependingView addSubview:freetecView];
    [freetecView setFrame:[typeDependingView bounds]];
    [freetecView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    light.type = freeTec_light;
  } else if ([[[lightTypePopupButton selectedItem] title] isEqualToString:TYPE_CMI]) {
    [typeDependingView addSubview:cmiView];
    [cmiView setFrame:[typeDependingView bounds]];
    [cmiView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    light.type = cmi_light;
  } else if ([[[lightTypePopupButton selectedItem] title] isEqualToString:TYPE_CONRAD]) {
    [typeDependingView addSubview:conradView];
    [conradView setFrame:[typeDependingView bounds]];
    [conradView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    light.type = conrad_light;
  }
}

/*
 * Called if the user pressed the sniff smi button
 */
- (IBAction)cmiSniffButton:(id)sender {
  // Let the light sniff cmi
  [light sniffCMI];
  // Add an observer to get response if sniffed succesfully
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(sniffedSuccessfully:)
                                               name:LightSniffedSuccessfully
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
    [light sniffCMIDismissed];
  }
  // Toggle to off
  [light toggle:false];
}

/*
 * Called if the sniff finished succesfully. The alert sheet is dismissed
 */
- (void) sniffedSuccessfully:(NSNotification*) notification {
  // Update the tristate value and dismiss the alert sheet
  [cmiCodeTextField setStringValue:[light cmiTristate]];
  [NSApp endSheet: [sniffAlert window]];
}

/*
 * Called if the user wants to learn a freetec device
 */
- (IBAction)freetecLearnButton:(id)sender {
  // Let the light learn itself
  [light learnFreetec];
  // Display alertsheet that the user needs to press the learn button on the freetec device
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:ALERT_BUTTON_OK];
  [alert addButtonWithTitle:ALERT_BUTTON_CANCEL];
  [alert setMessageText:ALERT_LEARNING_MESSAGE];
  [alert setInformativeText:ALERT_LEARNING_MESSAGE_INFORMAL];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
  // On finish toggle the device to false
  [light toggle:false];
}


/*
 * Called if the user changed the group of the conrad device
 */
-(IBAction)conradGroupChanged:(id)sender {
  light.conradGroup = [[conradGroupPopup selectedItem] tag];
}

/*
 * Called if the user changed the number of the conrad device
 */
- (IBAction)conradNumberChanged:(id)sender {
  light.conradNumber = [[conradNumberPopup selectedItem] tag];
}

@end
