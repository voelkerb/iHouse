//
//  GroupItem.m
//  iHouse
//
//  Created by Benjamin Völker on 15/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "GroupItem.h"
#import "Group.h"
#import "House.h"
#import "VoiceCommand.h"
#import "SynthesizedSpeechHandler.h"

#define DEBUG_GROUP_ITEM 1

@implementation GroupItem
@synthesize device, selector;

/*
 * Init with defaul values.
 */
- (id)init {
  self = [super init];
  if (self) {
    // The default values for a new device
    selector = KeyGroupStandardSelector;
    device = nil;//KeyGroupStandardSelector;
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:self.device forKey:@"device"];
  [encoder encodeObject:self.selector forKey:@"selector"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    self.device = [decoder decodeObjectForKey:@"device"];
    self.selector = [decoder decodeObjectForKey:@"selector"];
    // If decoding fails, reinit with standard values
    if (!selector) selector = KeyGroupStandardSelector;
    if (!device) device = nil;
  }
  return self;
}


/*
 * Performs the stored selector on the device
 */
-(BOOL)performTheSelector {
  if (!device) return false;
  // Get the response from exectuting the selector
  NSDictionary *responseDict = [device executeSelector:selector];
  NSLog(@"Group Item: %@, Response: %@", device.name, responseDict);
  
  if (!responseDict || ![[responseDict objectForKey:KeyVoiceCommandExecutedSuccessfully] boolValue]) {
    if (DEBUG_GROUP_ITEM) NSLog(@"Execution of Selector %@ failed", selector);
    return false;
  } else {
    // If this contains a response string get it
    if ([responseDict objectForKey:KeyVoiceCommandResponseString]) {
      NSString *speakIt = [responseDict objectForKey:KeyVoiceCommandResponseString];
      // If it contains an extra speek friendly string take this instead
      if ([responseDict objectForKey:KeyVoiceCommandResponseSpeechString]) {
        speakIt = [responseDict objectForKey:KeyVoiceCommandResponseSpeechString];
      }
      SynthesizedSpeechHandler *synthSpeechHandler = [SynthesizedSpeechHandler sharedSynthesizedSpeechHandler];
      [synthSpeechHandler speakStringIfReady:speakIt];
    }    
    return true;
  }
  /*
  for (Room *theRoom in [[House sharedHouse] rooms]) {
    for (IDevice *theDevice in [theRoom devices]) {
      if ([[theDevice name] isEqualToString:deviceName]) {
        
        [theDevice executeSelector:selector];
        return true;
      }
    }
  }
  */
  return false;
}

@end
