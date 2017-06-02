//
//  Settings.m
//  iHouse
//
//  Created by Benjamin Völker on 22/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "Settings.h"
#define DEBUG_SETTINGS 0

#define FOLDER_NAME @"iHouse Data"
#define FILE_ENDING @".house"
#define FILE_NAME @"yourSettings"
#define SUPPORTED_LANGUAGES @"English" // TODO maybe german
#define DEFAULT_TCP_PORT 2000

NSString * const SettingsVoiceChanged = @"SettingsVoiceChanged";
NSString * const SettingsApplicationLanguageChanged = @"SettingsApplicationLanguageChanged";
NSString * const SettingsFontSizeChanged = @"SettingsFontSizeChanged";

@implementation Settings
@synthesize launchOnStart, enableVoice, voiceResponseAutoDismiss;
@synthesize fontSize, voice, voiceLanguage, applicationLanguage, storeLocation, supportedLanguages, serialPortName, tcpPort;



/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedSettings {
  static Settings *sharedSettings = nil;
  @synchronized(self) {
    if (sharedSettings == nil) {
      // Init self from file
      // Get the path of the document directory
      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
      NSString *documentsDirectory = [paths objectAtIndex:0];
      // Append folder where it gets stored in
      NSString *fileDirectory = [documentsDirectory stringByAppendingPathComponent:FOLDER_NAME];
      // Append fileName
      NSString *appFile = [fileDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", FILE_NAME, FILE_ENDING]];
      NSFileManager *fileManager = [NSFileManager defaultManager];
      // Look if the filePath already exist, if not create it
      if ([fileManager fileExistsAtPath:fileDirectory] == NO) {
        [fileManager createDirectoryAtPath:fileDirectory withIntermediateDirectories:NO attributes:nil error:nil];
      }
      
      sharedSettings = [NSKeyedUnarchiver unarchiveObjectWithFile:appFile];
      
      // If File does not exist create it
      if (sharedSettings == nil) {
        sharedSettings = [[self alloc] init];
      }
    }
  }
  return sharedSettings;
}

- (id)init {
  if (self = [super init]) {
    launchOnStart = true;
    enableVoice = true;
    voiceResponseAutoDismiss = true;
    fontSize = 18;
    voice = [NSString stringWithFormat:@"Agnes"];
    serialPortName = [NSString stringWithFormat:@""];
    tcpPort = DEFAULT_TCP_PORT;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    // Append folder where it gets stored in
    NSString *fileDirectory = [documentsDirectory stringByAppendingPathComponent:FOLDER_NAME];
    // Set default store location
    storeLocation = [NSURL URLWithString:fileDirectory];
    
    // List of supported Languages
    supportedLanguages = [[NSArray alloc] initWithObjects:SUPPORTED_LANGUAGES, nil];
    
    // Look if system language is supported or not
    BOOL systemLanguageSupported = false;
    for (NSString *supLanguage in supportedLanguages) {
      if (DEBUG_SETTINGS) NSLog(@"Compare: %@ with: %@", supLanguage, [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:@"en"]);
      if ([supLanguage isEqualToString:[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:@"en"]]) {
        systemLanguageSupported = true;
      }
    }
    // If language is supported, set the language to the system language
    if (systemLanguageSupported) {
      voiceLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:@"en"];
      applicationLanguage = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:@"en"];
      if (DEBUG_SETTINGS) NSLog(@"Systemlanguage supported: %@", [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:@"en"]);
    // else just set the language to american english
    } else {
      voiceLanguage = [supportedLanguages objectAtIndex:0];
      applicationLanguage = [supportedLanguages objectAtIndex:0];
    }
    
  }
  return self;
}




// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeBool:self.launchOnStart forKey:@"launchAtStartup"];
  [encoder encodeBool:self.enableVoice forKey:@"enableVoice"];
  [encoder encodeBool:self.voiceResponseAutoDismiss forKey:@"voiceResponseAutoDismiss"];
  [encoder encodeInteger:self.fontSize forKey:@"fontSize"];
  [encoder encodeObject:self.voice forKey:@"voiceName"];
  [encoder encodeObject:self.storeLocation forKey:@"storeLocation"];
  [encoder encodeObject:self.voiceLanguage forKey:@"voiceLanguage"];
  [encoder encodeObject:self.applicationLanguage forKey:@"applicationLanguage"];
  [encoder encodeObject:self.supportedLanguages forKey:@"supportedLanguages"];
  [encoder encodeObject:self.serialPortName forKey:@"serialPortName"];
  [encoder encodeInteger:self.tcpPort forKey:@"tcpPort"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    self.launchOnStart = [decoder decodeBoolForKey:@"launchAtStartup"];
    self.enableVoice = [decoder decodeBoolForKey:@"enableVoice"];
    self.voiceResponseAutoDismiss = [decoder decodeBoolForKey:@"voiceResponseAutoDismiss"];
    self.fontSize = [decoder decodeIntegerForKey:@"fontSize"];
    self.voice = [decoder decodeObjectForKey:@"voiceName"];
    self.storeLocation = [decoder decodeObjectForKey:@"storeLocation"];
    self.voiceLanguage = [decoder decodeObjectForKey:@"voiceLanguage"];
    self.applicationLanguage = [decoder decodeObjectForKey:@"applicationLanguage"];
    self.supportedLanguages = [decoder decodeObjectForKey:@"supportedLanguages"];
    self.serialPortName = [decoder decodeObjectForKey:@"serialPortName"];
    self.tcpPort = [decoder decodeIntegerForKey:@"tcpPort"];
  }
  return self;
}


/*
 * Get the path where the data gets stored (this is the document directory)
 */
- (NSString *) storePath {
  // Append folder where it gets stored in// Get the path of the document directory
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  // Append folder where it gets stored in
  NSString *fileDirectory = [documentsDirectory stringByAppendingPathComponent:FOLDER_NAME];
  return fileDirectory;
}

/*
 * Get the path where the data gets stored (this is the document directory)
 */
- (NSString *) pathForDataFile {
  // Append folder where it gets stored in// Get the path of the document directory
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  // Append folder where it gets stored in
  NSString *fileDirectory = [documentsDirectory stringByAppendingPathComponent:FOLDER_NAME];
  // Append fileName
  NSString *appFile = [fileDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", FILE_NAME, FILE_ENDING]];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  // Look if the filePath already exist, if not create it
  if ([fileManager fileExistsAtPath:fileDirectory] == NO) {
    [fileManager createDirectoryAtPath:fileDirectory withIntermediateDirectories:NO attributes:nil error:nil];
  }
  return appFile;
}

/*
 * Get the path where the data gets stored (this is the document directory)
 */
- (NSString *) fileEnding {
  return FILE_ENDING;
}

-(void)setTheVoice:(NSString *)theVoice {
  self.voice = theVoice;
  [[NSNotificationCenter defaultCenter] postNotificationName:SettingsVoiceChanged object:nil];
}

-(void)setTheApplicationLanguage:(NSString *)theApplicationLanguage {
  self.applicationLanguage = theApplicationLanguage;
  [[NSNotificationCenter defaultCenter] postNotificationName:SettingsApplicationLanguageChanged object:nil];
}

-(void)setTheFontSize:(NSInteger)theFontSize {
  self.fontSize = theFontSize;
  [[NSNotificationCenter defaultCenter] postNotificationName:SettingsFontSizeChanged object:nil];
}

// Store Settings in File
- (BOOL)store:(id) sender {
  // Archive the house object
  //NSLog(@"%@", [self pathForDataFile:FILE_NAME]);
  return [NSKeyedArchiver archiveRootObject:self toFile:[self pathForDataFile]];
}


@end
