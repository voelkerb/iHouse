//
//  Settings.m
//  KickIt
//
//  Created by Benjamin Völker on 01/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "Settings.h"
#import "House.h"
#define FILE_ENDING @".house"
#define FILE_NAME @"yourSettings"
#define STANDARD_IP @"Not set yet"

@implementation Settings
@synthesize serverIP;

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
      // Append fileName
      NSString *appFile = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", FILE_NAME, FILE_ENDING]];
           
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
  self = [super init];
  if (self) {
    // Init stuff goes here
    serverIP = STANDARD_IP;
    [self codingIndependentInits];
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:self.serverIP forKey:@"serverIP"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    self.serverIP = [decoder decodeObjectForKey:@"serverIP"];
    [self codingIndependentInits];
  }
  return self;
}

// Inits that must be done either if this object is newly inited or inted from file
- (void)codingIndependentInits {
  if (!serverIP) serverIP = STANDARD_IP;
}

/*
 * Get the path where the data gets stored (this is the document directory)
 */
- (NSString *) pathForDataFile {
  // Append folder where it gets stored in// Get the path of the document directory
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  // Append folder where it gets stored in
  // Append fileName
  NSString *appFile = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", FILE_NAME, FILE_ENDING]];
  // Look if the filePath already exist, if not create it
  return appFile;
}

// Store Settings in File
- (BOOL)store:(id) sender {
  // Archive the house object
  //NSLog(@"%@", [self pathForDataFile:FILE_NAME]);
  return [NSKeyedArchiver archiveRootObject:self toFile:[self pathForDataFile]];
}


@end
