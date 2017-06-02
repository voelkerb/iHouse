//
//  EditSwitchViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 11.02.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Switch.h"

@interface EditSwitchViewController : NSViewController

// The pointer to the switch
@property (strong) Switch *RCSwitch;
// The tristate textfield of the switch device
@property (weak) IBOutlet NSTextField *codeTextField;
// The action popup button switching the action
@property (weak) IBOutlet NSPopUpButton *actionPopUp;
// The device popup button switching the device
@property (weak) IBOutlet NSPopUpButton *devicePopUp;
// The alertsheet if the user presses sniff button
@property NSAlert *sniffAlert;

// Need to initiated with a switch
- (id)initWithSwitch:(Switch*) theSwitch;
// If the device popup button changed
- (IBAction)devicePopUpChanged:(id)sender;
// If the action popup button changed
- (IBAction)actionPopUpChanged:(id)sender;
// If the user wants to sniff a cmi device
- (IBAction)sniffButton:(id)sender;
// If the user wants to test the action
- (IBAction)testButtonPressed:(id)sender;
@end
