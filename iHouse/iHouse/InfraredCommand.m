//
//  InfraredCommand.m
//  iHouse
//
//  Created by Benjamin Völker on 20/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "InfraredCommand.h"
#import "InfraredCommandViewController.h"

// The default ir picture is blank
#define DEFAULT_IR_IMAGE_NAME @"blank.png"


#define DEBUG_INFRARED_COMMAND 1
#define STANDARD_REPEAT_COUNT_RAW 3
#define STANDARD_REPEAT_COUNT_OTHER 1

#define COMMAND_SEPERATOR @";"


NSString * const IRCommandEmptyCommand = @"new command";
NSString * const IRCommandImageChanged = @"IRCommandImageChanged";
NSString * const IRCommandLearnedSuccessfully = @"IRCommandLearnedSuccessfully";

@implementation InfraredCommand
@synthesize name, image;
@synthesize irCode, irCode2, irRawCode, irProtocoll, delegate, repeatCount;

- (id)init {
  self = [super init];
  if (self) {
    // The default values for a new device
    irCode = [NSNumber numberWithLong:0];
    irCode2 = [NSNumber numberWithLong:0];
    irRawCode = [[NSArray alloc] init];
    name = IRCommandEmptyCommand;
    image = [NSImage imageNamed:DEFAULT_IR_IMAGE_NAME];
    irProtocoll = IR_NEC;
    repeatCount = 0;
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.image forKey:@"image"];
  [encoder encodeObject:self.irCode forKey:@"irCode"];
  [encoder encodeObject:self.irCode2 forKey:@"irCode2"];
  [encoder encodeObject:self.irRawCode forKey:@"irRawCode"];
  [encoder encodeInteger:self.irProtocoll forKey:@"irProtocoll"];
  [encoder encodeInteger:self.repeatCount forKey:@"repeatCount"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    self.name = [decoder decodeObjectForKey:@"name"];
    self.image = [decoder decodeObjectForKey:@"image"];
    self.irCode = [decoder decodeObjectForKey:@"irCode"];
    self.irCode2 = [decoder decodeObjectForKey:@"irCode2"];
    self.irRawCode = [decoder decodeObjectForKey:@"irRawCode"];
    self.irProtocoll = [decoder decodeIntegerForKey:@"irProtocoll"];
    self.repeatCount = [decoder decodeIntegerForKey:@"repeatCount"];
    if (!irCode2) irCode2 = [NSNumber numberWithLong:0];
  }
  return self;
}

/*
 * A IR command is sent back to us after learning. The protocoll and code needs to be
 * stored, so that it can be toggled by the server.
 */
- (void)gotLearnCommand:(NSString *)cmd {
  // Get the first integer which determines the ir protocol type
  int type = [cmd intValue];
  // Find seperator to get the rest of the command without protocol type
  NSRange range = [cmd rangeOfString:COMMAND_SEPERATOR];
  cmd = [cmd substringFromIndex:range.location + range.length];
  // Next is the number of bytes
  int repeat = [cmd intValue];
  range = [cmd rangeOfString:COMMAND_SEPERATOR];
  cmd = [cmd substringFromIndex:range.location + range.length];
  // Next is the number of bytes
  int length = [cmd intValue];
  // Cut the length from the command
  range = [cmd rangeOfString:COMMAND_SEPERATOR];
  cmd = [cmd substringFromIndex:range.location + range.length];
  BOOL dualCode = [cmd boolValue];
  // Cut the length from the command
  range = [cmd rangeOfString:COMMAND_SEPERATOR];
  cmd = [cmd substringFromIndex:range.location + range.length];
  // If type is -1 we have a raw code which is a little bit tricky
  if (type == -1) {
    // Allocate array where the code is temporary stored
    NSMutableArray *theCode = [[NSMutableArray alloc] init];
    // In a loop extract the codes single bytes
    while (true) {
      // If no seperator is inside the string, we will break
      if ([cmd rangeOfString:COMMAND_SEPERATOR].location == NSNotFound) break;
      // Get integer value from string -> raw code value
      [theCode addObject:[NSNumber numberWithInt:[cmd intValue]]];
      // Remove fetched value from string with seperator
      cmd = [cmd substringFromIndex:[cmd rangeOfString:COMMAND_SEPERATOR].location+[COMMAND_SEPERATOR length]];
    }
    if (DEBUG_INFRARED_COMMAND) NSLog(@"Learned RAW: type: %i, length: %i, code: %@", type, length, theCode);
    // If the length did not match, sth went wrong while decoding
    if (length != [theCode count]) {
      if (DEBUG_INFRARED_COMMAND) NSLog(@"Length error: %i, %li", length, [theCode count]);
    }
    // Store raw protocol type and the raw code in an array
    irProtocoll = IR_RAW;
    repeatCount = STANDARD_REPEAT_COUNT_RAW;
    irRawCode = [[NSArray alloc] initWithArray:theCode];
  // If we do not have raw codes, things become very simple
  } else {
    // Extract the code and store the code in a single long value
    long code = [cmd longLongValue];
    if (dualCode) {
      // Cut the length from the command
      range = [cmd rangeOfString:COMMAND_SEPERATOR];
      cmd = [cmd substringFromIndex:range.location + range.length];
      long code2 = [cmd longLongValue];
      irCode2 = [NSNumber numberWithLong:code2];
    } else {
      irCode2 = [NSNumber numberWithLong:0];
    }
    if (DEBUG_INFRARED_COMMAND) NSLog(@"Learned NEC: type: %i, length: %i, code: %li", type, length, code);
    irProtocoll = type;
    repeatCount = STANDARD_REPEAT_COUNT_OTHER;
    irCode = [NSNumber numberWithLong:code];
  }
  if (repeat > 0 && repeat < 100) repeatCount = repeat;
  // Post notification that the command was learned successfully
  [[NSNotificationCenter defaultCenter] postNotificationName:IRCommandLearnedSuccessfully object:self];
}

/*
 * Returns the data for the toggle command
 */
- (NSData*)toggleCommand {
  // Allocate data object
  NSMutableData *data = [[NSMutableData alloc] init];
  
  if (DEBUG_INFRARED_COMMAND) {
    NSLog(@"Protocoll: %@", [self irProtocollToString:irProtocoll]);
  }
  
  // Depending on the protocoll of this command encode the data
  switch (irProtocoll) {
    // If in raw format
    case IR_RAW: {
      // Raw format identifier is 't0' then we need the number of bytes the of the command
      // Which is
      char rawData[5];
      bool dualcode = false;
      rawData[0] = 't';
      rawData[1] = (char) irProtocoll;
      rawData[2] = (char) repeatCount;
      rawData[3] = (char) dualcode;
      rawData[4] = (char)((int)67);//(char) ((int)[irRawCode count]);
      // Append it ot the array that is sent
      [data appendBytes:&rawData length:sizeof(rawData)];
      if (DEBUG_INFRARED_COMMAND) NSLog(@"Length of raw data: %li", ([irRawCode count]));
      if (DEBUG_INFRARED_COMMAND) NSLog(@"%c %i %i + data", rawData[0], (int)rawData[1], (int)rawData[2]);
      // For every value in the raw code
      for (NSNumber *theNumber in irRawCode) {
        // Get the integer value
        NSInteger theNum = [theNumber intValue];
        // And convert it to two chars MSB first
        char rawNum[2];
        rawNum[0] = (((int)theNum >> 8) & 0xFF);
        rawNum[1] = ((int)theNum & 0xFF);
        // Append the two bytes to the data sent
        if (DEBUG_INFRARED_COMMAND) NSLog(@"%li", theNum);
        [data appendBytes:&rawNum length:sizeof(rawNum)];
      }
      break;
    }
    // All other protocols have this type
    default: {
      bool dualCode = false;
      if ([irCode2 longValue] != 0) dualCode = true;
      if (dualCode) {
        char rawData[12];
        rawData[0] = 't';
        rawData[1] = (char) irProtocoll;
        rawData[2] = (char) repeatCount;
        rawData[3] = (char) dualCode;
        rawData[4] = (char) ([irCode longValue] >> 24);
        rawData[5] = (char) ([irCode longValue] >> 16);
        rawData[6] = (char) ([irCode longValue] >> 8);
        rawData[7] = (char) ([irCode longValue]);
        rawData[8] = (char) ([irCode2 longValue] >> 24);
        rawData[9] = (char) ([irCode2 longValue] >> 16);
        rawData[10] = (char) ([irCode2 longValue] >> 8);
        rawData[11] = (char) ([irCode2 longValue]);
        [data appendBytes:&rawData length:sizeof(rawData)];
        if (DEBUG_INFRARED_COMMAND) NSLog(@"Dualcode");
      } else {
        // Sent a 't' + protocol specifier + data as long MSB first
        char rawData[8];
        rawData[0] = 't';
        rawData[1] = (char) irProtocoll;
        rawData[2] = (char) repeatCount;
        rawData[3] = (char) dualCode;
        rawData[4] = (char) ([irCode longValue] >> 24);
        rawData[5] = (char) ([irCode longValue] >> 16);
        rawData[6] = (char) ([irCode longValue] >> 8);
        rawData[7] = (char) ([irCode longValue]);
        [data appendBytes:&rawData length:sizeof(rawData)];
        if (DEBUG_INFRARED_COMMAND) NSLog(@"%c %i %i %i %i %i", rawData[0], (int)rawData[1], (int)rawData[2], (int)rawData[3], (int)rawData[4], (int)rawData[5]);
      }
      break;
    }
  }
  return data;
}

/*
 * The delegate will delete us.
 */
- (void)deleteCommand {
  [delegate deleteCommand:self];
}


/*
 * The delegate will learn us.
 */
- (void)learnCommand {
  [delegate learnCommand:self];
}

/*
 * The delegate should stop learning.
 */
- (void)stopLearning {
  [delegate stopLearning];
}

/*
 * The delegate will toggle us.
 */
- (void)toggle {
  [delegate toggle:self];
}


/*
 * The delegate will return if we are connected.
 */
- (BOOL)isConnected {
  return [delegate isConnected];
}

/*
 * Returns the device view of the infrared command
 */
- (NSViewController *)deviceView {
  return [[InfraredCommandViewController alloc] initWithIRCommand:self :false];
}

/*
 * Returns the edit device view of the infrared command
 */
- (NSViewController *)deviceEditView {
  return [[InfraredCommandViewController alloc] initWithIRCommand:self :true];
}

// Return string from Protocol enum
- (NSString*)irProtocollToString:(IRProtocoll)theIRProtocoll {
  NSString *result = nil;
  switch(theIRProtocoll) {
    case IR_NEC:
      result = @"NEC";
      break;
    case IR_RAW:
      result = @"RAW";
      break;
    case IR_SONY:
      result = @"Sony";
      break;
    case IR_RC5:
      result = @"RC5";
      break;
    case IR_RC6:
      result = @"RC6";
      break;
    case IR_DISH:
      result = @"Dish";
      break;
    case IR_SHARP:
      result = @"Sharp";
      break;
    case IR_PANASONIC:
      result = @"Panasonic";
      break;
    case IR_JVC:
      result = @"JVC";
      break;
    case IR_SANYO:
      result = @"Sanyo";
      break;
    case IR_MITSUBISHI:
      result = @"Mitsubishi";
      break;
    default:
      [NSException raise:NSGenericException format:@"Unexpected IR MODE."];
  }
  return result;
}
@end
