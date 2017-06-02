//
//  SettingsViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 06/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "SettingsViewController.h"
#define SYSTEM_DEFAULT_VOICE_STRING @"System default"
@interface SettingsViewController ()

@end

@implementation SettingsViewController
@synthesize launchOnStartCheckbox, enableVoiceCommandCheckbox, voiceResponseAutoDismissCheckbox;
@synthesize commandLanguagePopupbutton, responseVoicePopupbutton, applicationLanguagePopupbutton;
@synthesize storeLocationTextfield, fontSizeCombobox;
@synthesize settings, speechSynthesizer;


- (void)viewDidLoad {
  [super viewDidLoad];
  
  // The settings object
  settings = [Settings sharedSettings];
  
  // The Speech synthesizer for demo speech
  speechSynthesizer = [[NSSpeechSynthesizer alloc] init];
  
  // The Checkboxes
  [launchOnStartCheckbox setState:[settings launchOnStart]];
  [voiceResponseAutoDismissCheckbox setState:[settings voiceResponseAutoDismiss]];
  [enableVoiceCommandCheckbox setState:[settings enableVoice]];
  
  // The language popup buttons
  [self initPopUpButtonsWithSupportedLanguages];
  [applicationLanguagePopupbutton selectItemWithTitle:[settings applicationLanguage]];
  [commandLanguagePopupbutton selectItemWithTitle:[settings voiceLanguage]];
  
  // The voice popup buttons
  [self initPopUpButtonsWithAvailableVoices];
  [responseVoicePopupbutton selectItemWithTitle:[settings voice]];
  
  [storeLocationTextfield setStringValue:[NSString stringWithFormat:@"%s", [[settings storeLocation] fileSystemRepresentation]]];
  [fontSizeCombobox setStringValue:[NSString stringWithFormat:@"%li", [settings fontSize]]];
}


- (void) initPopUpButtonsWithAvailableVoices {
  [[responseVoicePopupbutton menu] removeAllItems];
  
  // Make object with all voices matching the language
  NSMutableArray *listOfLanguageVoices = [[NSMutableArray alloc] init];
  for (NSString *voiceIdentifier in [NSSpeechSynthesizer availableVoices]) {
    NSString *voiceLocaleIdentifier = [[NSSpeechSynthesizer attributesForVoice:voiceIdentifier] objectForKey:NSVoiceLocaleIdentifier];
    //NSLog(@"Voice: %@, %@", [[NSSpeechSynthesizer attributesForVoice:voiceIdentifier] valueForKey:NSVoiceName], [[NSLocale localeWithLocaleIdentifier:@"en"] displayNameForKey:NSLocaleIdentifier value:voiceLocaleIdentifier]);
    if ([[[NSLocale localeWithLocaleIdentifier:@"en"] displayNameForKey:NSLocaleIdentifier value:voiceLocaleIdentifier] containsString:[settings voiceLanguage]]) {
      [listOfLanguageVoices addObject:voiceIdentifier];
    }
  }
  // If this list is not empty and the language is matching display system default voice
  if ([listOfLanguageVoices count] > 0) {
    NSString *identifyer = [[NSSpeechSynthesizer attributesForVoice:[NSSpeechSynthesizer defaultVoice]] objectForKey:NSVoiceLocaleIdentifier];
    if ([[[NSLocale localeWithLocaleIdentifier:identifyer] displayNameForKey:NSLocaleIdentifier value:@"en"] isEqualToString:[settings voiceLanguage]]) {
      NSMenuItem *defaultItem = [[NSMenuItem alloc] initWithTitle:SYSTEM_DEFAULT_VOICE_STRING action:NULL keyEquivalent:SYSTEM_DEFAULT_VOICE_STRING];
      [[responseVoicePopupbutton menu] addItem:defaultItem];
      [[responseVoicePopupbutton menu] addItem:[NSMenuItem separatorItem]];
    }
  }
  // Display the voices in list
  for (NSString *voiceIdentifier in listOfLanguageVoices) {
    NSString *voice = [[NSSpeechSynthesizer attributesForVoice:voiceIdentifier]
                       valueForKey: NSVoiceName];
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:voice action:NULL keyEquivalent:voice];
    [[responseVoicePopupbutton menu] addItem:item];
  }
  
}

- (void) initPopUpButtonsWithSupportedLanguages {
  [commandLanguagePopupbutton removeAllItems];
  [applicationLanguagePopupbutton removeAllItems];
  int i = 0;
  
  for (NSString *languageName in [settings supportedLanguages]) {
    [commandLanguagePopupbutton insertItemWithTitle:languageName atIndex:i];
    [applicationLanguagePopupbutton insertItemWithTitle:languageName atIndex:i];
    i++;
  }
}

- (IBAction)applicationLanguageChanged:(id)sender {
  [settings setTheApplicationLanguage:[[applicationLanguagePopupbutton selectedItem] title]];
  [settings store:self];
}

- (IBAction)commandLanguageChanged:(id)sender {
  settings.voiceLanguage = [[commandLanguagePopupbutton selectedItem] title];
  [self initPopUpButtonsWithAvailableVoices];
  [settings setTheVoice:[[responseVoicePopupbutton selectedItem] title]];
  [settings store:self];
}

- (IBAction)responseVoiceChanged:(id)sender {
  [settings setTheVoice:[[responseVoicePopupbutton selectedItem] title]];
  [settings store:self];
}

- (IBAction)fontSizeChanged:(id)sender {
  [settings setTheFontSize:[[fontSizeCombobox stringValue] intValue]];
  [settings store:self];
}

- (IBAction)enableVoiceCommandChanged:(id)sender {
  settings.enableVoice = [enableVoiceCommandCheckbox state];
  [settings store:self];
}

- (IBAction)voiceResponseAutoDismissChanged:(id)sender {
  settings.voiceResponseAutoDismiss = [voiceResponseAutoDismissCheckbox state];
  [settings store:self];
}

- (IBAction)playVoice:(id)sender {
  if([speechSynthesizer isSpeaking]) {
    [speechSynthesizer stopSpeaking];
  }
  // Make object with all voices matching the language
  if ([[[responseVoicePopupbutton selectedItem] title] isEqualToString:SYSTEM_DEFAULT_VOICE_STRING]) {
    speechSynthesizer = [[NSSpeechSynthesizer alloc] initWithVoice:[NSSpeechSynthesizer defaultVoice]];
  } else {
    for (NSString *voiceIdentifier in [NSSpeechSynthesizer availableVoices]) {
      if ([[[NSSpeechSynthesizer attributesForVoice:voiceIdentifier] valueForKey:NSVoiceName] isEqualToString:[[responseVoicePopupbutton selectedItem] title]]) {
        speechSynthesizer = [[NSSpeechSynthesizer alloc] initWithVoice:voiceIdentifier];
      }
    }
  }
  
  NSDictionary * attributes = [NSSpeechSynthesizer attributesForVoice:[speechSynthesizer voice]];
  
  NSString *theName = [attributes objectForKey:NSVoiceName];
  
  NSString *speakText = [NSString stringWithFormat:@"%@. %@",
                 theName,[attributes objectForKey:NSVoiceDemoText]];
  [speechSynthesizer startSpeakingString:speakText];
  
}

- (IBAction)launchOnStartChanged:(id)sender {
  settings.launchOnStart = [launchOnStartCheckbox state];
  [settings store:self];
}


@end
