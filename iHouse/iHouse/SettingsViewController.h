//
//  SettingsViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 06/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Settings.h"

@interface SettingsViewController : NSViewController

@property (weak) IBOutlet NSButton *launchOnStartCheckbox;
@property (weak) IBOutlet NSButton *enableVoiceCommandCheckbox;
@property (weak) IBOutlet NSButton *voiceResponseAutoDismissCheckbox;
@property (weak) IBOutlet NSPopUpButton *commandLanguagePopupbutton;
@property (weak) IBOutlet NSPopUpButton *responseVoicePopupbutton;
@property (weak) IBOutlet NSPopUpButton *applicationLanguagePopupbutton;
@property (weak) IBOutlet NSComboBox *fontSizeCombobox;
@property (weak) IBOutlet NSTextField *storeLocationTextfield;
@property (strong) NSSpeechSynthesizer *speechSynthesizer;



// The settingsObject
@property (strong) Settings *settings;

- (IBAction)applicationLanguageChanged:(id)sender;
- (IBAction)commandLanguageChanged:(id)sender;
- (IBAction)responseVoiceChanged:(id)sender;
- (IBAction)fontSizeChanged:(id)sender;
- (IBAction)enableVoiceCommandChanged:(id)sender;
- (IBAction)voiceResponseAutoDismissChanged:(id)sender;

- (IBAction)playVoice:(id)sender;
- (IBAction)launchOnStartChanged:(id)sender;

@end
