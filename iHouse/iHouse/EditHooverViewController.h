//
//  EditHooverViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "Hoover.h"
#import "TCPServer.h"

@interface EditHooverViewController : NSViewController

@property (strong) Hoover *hoover;

// The label displaying the id of the meter
@property (weak) IBOutlet NSTextField *hostLabel;
// A popup button which is displayed in a alert window
@property (strong) NSPopUpButton *hostAlertPopup;
// The save button of the alert window (must be disabled if nothing selected)
@property (strong) NSButton *saveButton;
// The identify button to identify the selected host
@property (strong) NSButton *identifyButton;

- (id) initWithHoover:(Hoover*) theHoover;

// If the user wants to change the host
- (IBAction)changeHost:(id)sender;

@end
