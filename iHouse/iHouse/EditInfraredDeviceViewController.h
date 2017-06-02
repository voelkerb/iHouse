//
//  EditInfraredDeviceViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "InfraredDevice.h"
#import "TCPServer.h"
#import "NSFlippedView.h"

@interface EditInfraredDeviceViewController : NSViewController {
  NSMutableArray *viewControllers;
}

@property (strong) InfraredDevice *infraredDevice;

// The label displaying the id of the meter
@property (weak) IBOutlet NSTextField *hostLabel;
// The ir srollview
@property (weak) IBOutlet NSScrollView *scrollView;
// A popup button which is displayed in a alert window
@property (strong) NSPopUpButton *hostAlertPopup;
// The save button of the alert window (must be disabled if nothing selected)
@property (strong) NSButton *saveButton;
// The identify button to identify the selected host
@property (strong) NSButton *identifyButton;

- (id) initWithInfraredDevice:(InfraredDevice*) theInfraredDevice;

// If the user wants to change the host
- (IBAction)changeHost:(id)sender;

// If the user wants to add a IR command
- (IBAction)addIRCommand:(id)sender;

@end
