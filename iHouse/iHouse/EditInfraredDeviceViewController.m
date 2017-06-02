//
//  EditInfraredDeviceViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "EditInfraredDeviceViewController.h"
#import "TCPServer.h"
#import "House.h"

#define DEBUG_IR_EDIT_VIEW true

#define HOST_NOT_SET_LABEL @"not chosen yet"
#define ALERT_BUTTON_SAVE @"Save"
#define ALERT_BUTTON_CANCEL @"Cancel"
#define ALERT_BUTTON_IDENTIFY @"Identify"
#define ALERT_ID_MESSAGE @"Select the IR Host"
#define ALERT_ID_MESSAGE_INFORMAL @"Select the IR host from the list of non bound IR devices. Press identify to identify the IR device."



@interface EditInfraredDeviceViewController ()

@end

@implementation EditInfraredDeviceViewController
@synthesize infraredDevice, identifyButton, hostLabel, hostAlertPopup, saveButton, scrollView;

- (id)initWithInfraredDevice:(InfraredDevice *)theInfraredDevice {
  if (self = [super init]) {
    infraredDevice = (InfraredDevice *) theInfraredDevice;
    viewControllers = [[NSMutableArray alloc] init];
    // Add an observer, so that if the number of ir device did change than this view needs to be redrawn
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:IRDeviceCountChanged object:nil];
  }
  return self;
}

// If the device was dedited, we need to redraw the infrared views
-(void)reDraw:(NSNotification*)notification {
  if ([infraredDevice isEqualTo:[notification object]]) {
    [self initInfraredViews];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Set the host label and indicate if no host was set yet
  if (![infraredDevice host] || [[infraredDevice host] isEqualToString:@""]) [hostLabel setStringValue:HOST_NOT_SET_LABEL];
  else [hostLabel setStringValue:[NSString stringWithFormat:@"%@", [infraredDevice host]]];
  // Init the scrollview and the infrared views
  [self initScrollView];
  [self initInfraredViews];
}

/*
 * Init the scrollview and set the background color correctly.
 */
- (void) initScrollView {
  // The scroll view has no Border
  [scrollView setHasVerticalScroller:YES];
  [scrollView setHasHorizontalScroller:NO];
  [scrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
}

/*
 * Init the infrared views into scrollview.
 */
-(void)initInfraredViews {
  // Remove all previous views from the viewcontroller and from the view
  [viewControllers removeAllObjects];
  NSArray *subviews = [[NSArray alloc] initWithArray:[[scrollView documentView] subviews]];
  for (NSView *view in subviews) [view removeFromSuperview];
  
  // Init a document view for the scrollview, its flipped.
  NSFlippedView *commandsView = [[NSFlippedView alloc] initWithFrame:scrollView.frame];
  
  NSRect scrollFrame = NSMakeRect(0, 0, scrollView.frame.size.width, 0);
  
  // Add every single command view to the command view
  NSRect frame = NSMakeRect(0, 0, 0, 0);
  for (InfraredCommand* irCommand in [infraredDevice infraredCommands]) {
    // Get the view and set the frame accordingly
    NSViewController *irCommandViewController = [irCommand deviceView];
    frame.size.width = irCommandViewController.view.frame.size.width;
    frame.size.height = irCommandViewController.view.frame.size.height;
    frame.origin.x += irCommandViewController.view.frame.size.width;
    if (frame.origin.x + frame.size.width > commandsView.frame.size.width) {
      frame.origin.x = 0;
      frame.origin.y += irCommandViewController.view.frame.size.height;
      scrollFrame.size.height = frame.origin.y;
    } else {
      scrollFrame.size.height = frame.origin.y + frame.size.height;
    }
  }
  // Set the frame of the documentview
  [commandsView setFrame:scrollFrame];
  // Set the slider if big enough
  if (scrollFrame.size.height < scrollView.frame.size.height) {
    [scrollView setHasVerticalScroller:NO];
    [scrollView setVerticalScrollElasticity:NSScrollElasticityNone];
  }
  // Add every single command view to the command view
  frame = NSMakeRect(0, 0, 0, 0);
  for (InfraredCommand* irCommand in [infraredDevice infraredCommands]) {
    // Get the view and set the frame accordingly
    NSViewController *irCommandViewController = [irCommand deviceEditView];
    frame.size.width = irCommandViewController.view.frame.size.width;
    frame.size.height = irCommandViewController.view.frame.size.height;
    // Add the viewController
    [viewControllers addObject:irCommandViewController];
    
    // Add the view
    NSView *irCommandView = irCommandViewController.view;
    // Set its frame and add it as a subview of the view of all devices of this kind
    [irCommandView setFrame:frame];
    [commandsView addSubview:irCommandView];
    
    // Increment x position and if needed also the y position
    frame.origin.x += irCommandViewController.view.frame.size.width;
    if (frame.origin.x + frame.size.width > commandsView.frame.size.width) {
      frame.origin.x = 0;
      frame.origin.y += irCommandViewController.view.frame.size.height;
    }
  }
  // Set the document view
  [scrollView setDocumentView:commandsView];
}


/*
 * Called if the user wants to add an ir command.
 */
- (IBAction)addIRCommand:(id)sender {
  InfraredCommand *newIRCommand = [[InfraredCommand alloc] init];
  [infraredDevice addIRCommand:newIRCommand];
}

/*
 * Called if the user wants to change the host.
 */
- (IBAction)changeHost:(id)sender {
  // Add an observer to get devices
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newIRDeviceDiscovered:)
                                               name:TCPServerNewSocketDiscovered
                                             object:nil];
  
  // Start discovering
  TCPServer *tcpServer = [TCPServer sharedTCPServer];
  [tcpServer discoverSockets:[infraredDevice discoverCommandResponse]];
  
  // And show the uppopping alert sheet
  [self showEditHostAlert];
}


/*
 * Show an alert where new devices are presented in a popup button.
 */
-(void)showEditHostAlert {
  
  if (DEBUG_IR_EDIT_VIEW) NSLog(@"Show edit ir host");
  // The accessory view of the alert sheet
  NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 280, 24)];
  // Add the PopUp button to the accessory view of the alert sheet
  hostAlertPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 150, 24)];
  // Insert the currently available hosts from other remotes
  House *theHouse = [House sharedHouse];
  for (Room *theRoom in [theHouse rooms]) {
    for (IDevice *theDevice in [theRoom devices]) {
      if (theDevice.type == ir) {
        NSString *host = [(InfraredDevice*)[theDevice theDevice] host];
        if (DEBUG_IR_EDIT_VIEW) NSLog(@"Found host %@", host);
        if (host && ![host isEqualToString:@""]) {
          if (![hostAlertPopup itemWithTitle:host]) [hostAlertPopup addItemWithTitle:host];
        }
      }
    }
  }
  
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
  // If the alert popup has no items, set the buttons for identify and save to disabled
  if (![hostAlertPopup numberOfItems]) {
    [saveButton setEnabled:NO];
    [identifyButton setEnabled:NO];
  }
  
  long returnCode = [alert runModal];
  // If the user pressed save, the host is stored and the label is updated
  if (returnCode == 1000) {
    [infraredDevice freeSocket];
    infraredDevice.host = [[hostAlertPopup selectedItem] title];
    [hostLabel setStringValue:[NSString stringWithFormat:@"%@", [infraredDevice host]]];
    // Get the socket for the device
    TCPServer *tcpServer = [TCPServer sharedTCPServer];
    [tcpServer stopDiscovering];
    if (DEBUG_IR_EDIT_VIEW) NSLog(@"took ir remote with host %@", [[tcpServer getSocketWithHost:[infraredDevice host]] connectedHost]);
    [infraredDevice deviceConnected:[tcpServer getSocketWithHost:[infraredDevice host]]];
    
  } // if the user pressed cancel, nothing is done
  
  // Remove the observer for new devices
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TCPServerNewSocketDiscovered object:nil];
}

/*
 * If the user presses identify, let the ir device blink.
 */
-(void)identifyClicked:(id)sender {
  NSString *host = [[hostAlertPopup selectedItem] title];
  if (DEBUG_IR_EDIT_VIEW) NSLog(@"Want to identify %@", host);
  InfraredDevice *identifyDevice = [[InfraredDevice alloc] init];
  [identifyDevice deviceConnected:[[TCPServer sharedTCPServer] getSocketWithHost:host]];
  [identifyDevice identify];
  [identifyDevice freeSocket];
}

/*
 * If new IR devices connected.
 */
-(void)newIRDeviceDiscovered:(NSNotification*)notification {
  if (DEBUG_IR_EDIT_VIEW) NSLog(@"newIRDeviceDiscovered: %@", [notification object]);
  [hostAlertPopup addItemWithTitle:[notification object]];
  if (![saveButton isEnabled]) [saveButton setEnabled:YES];
  if (![identifyButton isEnabled]) [identifyButton setEnabled:YES];
}


@end
