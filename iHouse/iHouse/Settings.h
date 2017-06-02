//
//  Settings.h
//  iHouse
//
//  Created by Benjamin Völker on 22/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const SettingsVoiceChanged;
extern NSString * const SettingsApplicationLanguageChanged;
extern NSString * const SettingsFontSizeChanged;

@interface Settings : NSObject <NSCoding>

// If the app should launch at startup
@property BOOL launchOnStart;
// If the app should interact with the user with voice commands
@property BOOL enableVoice;
// If the app should display the voice command window
@property BOOL voiceResponseAutoDismiss;
// The fontSize of the app
@property NSInteger fontSize;
// The storage location of the house data
@property NSURL *storeLocation;
// The Application language
@property NSString *applicationLanguage;
// The voice language
@property NSString *voiceLanguage;
// The voice language
@property NSString *voice;
// The supported languages as strings
@property NSArray *supportedLanguages;
// The name of the serial port
@property NSString *serialPortName;
// The port for the tcp connections
@property NSInteger tcpPort;

+ (id)sharedSettings;
- (BOOL)store:(id)sender;
- (NSString*)storePath;
- (NSString*)fileEnding;
// Custom setters for the settings
- (void)setTheVoice:(NSString *)theVoice;
- (void)setTheApplicationLanguage:(NSString *)theApplicationLanguage;
- (void)setTheFontSize:(NSInteger)theFontSize;

@end
