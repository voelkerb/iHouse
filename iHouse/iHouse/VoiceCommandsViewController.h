//
//  VoiceCommandsViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 06/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "House.h"
#import "VoiceCommandsPreferenceViewController.h"
#import "NewVoiceCommandViewController.h"

@interface VoiceCommandsViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NewVoiceCommandViewControllerDelegate>

// The view with tables and currentview
@property (weak) IBOutlet NSView *viewWithTable;

// The Sidebar with the list of voice commands
@property (weak) IBOutlet NSTableView *sideBarTableView;

// The current view of the selected table item
@property (weak) IBOutlet NSView *currentView;

// The view if no voice command is preset
@property (weak) IBOutlet NSView *emptyView;

// The popUpButton displaying the available voice command types and rooms
@property (weak) IBOutlet NSPopUpButton *typePopUpButton;
@property (weak) IBOutlet NSPopUpButton *roomPopUpButton;

// The House object containing all voice commands
@property (strong) House *house;

// The view controller for editing the preferences of the voice command
@property (strong) VoiceCommandsPreferenceViewController *voiceCommandsPreferenceViewController;

// The view controller for adding a new voice command
@property (strong) NewVoiceCommandViewController *addVoiceCommandViewController;

// Action from the room tableview
- (IBAction)changedSideBarTable:(id)sender;

// Action from adding a voice command
- (IBAction)addVoiceCommand:(id)sender;

// Action from remove a voice command
- (IBAction)removeVoiceCommand:(id)sender;

// The Action when the popupbutton is changed
- (IBAction) filterChanged:(id)sender;

@end
