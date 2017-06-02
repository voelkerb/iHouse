//
//  EditMeterViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Meter.h"

@interface EditMeterViewController : NSViewController<NSMenuDelegate>

// The meter device
@property (strong) Meter *myMeter;
// The label displaying the id of the meter
@property (weak) IBOutlet NSTextField *idLabel;
// A popup button which is displayed in a alert window
@property (strong) NSPopUpButton *idAlertPopup;
// The save button of the alert window (must be disabled if nothing selected)
@property (strong) NSButton *saveButton;

- (id) initWithMeter:(Meter*) theMeter;

// If the user wants to change the meterID
- (IBAction)changeMeterID:(id)sender;

@end
