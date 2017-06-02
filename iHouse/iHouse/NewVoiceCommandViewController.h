//
//  newVoiceCommandViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 23/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VoiceCommandsPreferenceViewController.h"
#import "VoiceCommand.h"

// The Functions the delegate has to implement
@protocol NewVoiceCommandViewControllerDelegate <NSObject>

// The delegate needs to change something
- (void) newVoiceCommandFinished;

@end

@interface NewVoiceCommandViewController : NSViewController

// The delegate variable
@property (weak) id<NewVoiceCommandViewControllerDelegate> delegate;

// The view of the Device
@property (weak) IBOutlet NSView *voiceCommandView;

// The currently created voice command
@property (strong) VoiceCommand *voiceCommand;

// The view controller for editing the preferences of the voice command
@property (strong) VoiceCommandsPreferenceViewController *voiceCommandsPreferenceViewController;

// The popup buttons for for which room and which device
@property (weak) IBOutlet NSPopUpButton *roomPopUpButton;
@property (weak) IBOutlet NSPopUpButton *devicePopUpButton;


// If the User choose differently
- (IBAction)roomPopUpButtonChanged:(id)sender;
- (IBAction)typePopUpButtonChanged:(id)sender;

// Save or Cancel the new device
- (IBAction)cancelPressed:(id)sender;
- (IBAction)savePressed:(id)sender;


@end
