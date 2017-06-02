//
//  SocketViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "SocketViewController.h"
#import "IDevice.h"


#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NO_CONNECTION_MESSAGE @"Socket switcher not connected"
#define ALERT_NO_CONNECTION_MESSAGE_INFORMAL @"Connect a iHouse socket switcher over USB to switch "

@interface SocketViewController ()

@end

@implementation SocketViewController
@synthesize switchButton, socketImage, socketName, iDevice, backView;

/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  SocketViewController *copy = [[SocketViewController allocWithZone: zone] initWithDevice:iDevice];
  return copy;
}

- (id)initWithDevice:(IDevice *)theSocketDevice {
  self = [super init];
  if (self && (theSocketDevice.type == switchableSocket)) {
    // Get the pointer of the device
    iDevice = theSocketDevice;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(socketSwitched)
                                                 name:SocketSwitched
                                               object:nil];
    // Add observer for device edit change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:iDeviceDidChange object:nil];
  }
  return self;
}

// If the device was dedited, we need to redraw
-(void)reDraw:(NSNotification*)notification {
  if ([iDevice isEqualTo:[notification object]]) {
    [self viewDidLoad];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Set name and image of the device
  [socketName setStringValue:[iDevice name]];
  [socketImage setImage:[iDevice image]];
  [socketImage setAllowDrag:false];
  [socketImage setAllowDrop:false];
  
  // Set the background color accordingly
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[[iDevice color] CGColor]];
  [backView setWantsLayer:YES];
  [backView setLayer:viewLayer];
  
  // Set the state of the button according to the current state
  [switchButton setState:[(Socket *)[iDevice theDevice] state]];
}


/*
 * If the user pressed the toggle button
 */
- (IBAction)toggleSocket:(id)sender {
  // Try to toggle the device
  if ([self checkConnected]) [(Socket *)[iDevice theDevice] toggle:[switchButton state]];
  [switchButton setState:[(Socket *)[iDevice theDevice] state]];
}

- (void)socketSwitched {
  // Update the state of the toggle button
  [switchButton setState:[(Socket *)[iDevice theDevice] state]];
}



/*
 * Checks if the Socket deivce is connected over USB.
 */
- (BOOL)checkConnected {
  if ([(Socket*)[iDevice theDevice] isConnected]) return true;
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:ALERT_BUTTON_OK];
  [alert setMessageText:ALERT_NO_CONNECTION_MESSAGE];
  [alert setInformativeText:[NSString stringWithFormat:@"%@%@.", ALERT_NO_CONNECTION_MESSAGE_INFORMAL, [iDevice name]]];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
  return false;
}

@end
