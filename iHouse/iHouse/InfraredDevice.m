//
//  InfraredDevice.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "InfraredDevice.h"
#import "TCPServer.h"
#import "VoiceCommand.h"
#import "House.h"

#define DEBUG_INFRARED_DEVICE 1
#define DISCOVER_COMMAND_RESPONSE @"iHouseInfrared"

#define COMMAND_PREFIX @"/"
#define COMMAND_IDENTIFY @"x"
#define COMMAND_LEARN @"a"
#define COMMAND_TOGGLE @"b"
#define COMMAND_LEARNED @"/l:"

#define VOICE_RESPONSES_NOT_CONNECTED @"Connection problem.", @"Sorry but the IR device is not connected."

NSString * const IRDeviceSelectorToggle = @"toggleIR:";
NSString * const IRDeviceCountChanged = @"IRDeviceCountChanged";

@implementation InfraredDevice
@synthesize infraredCommands, tcpConnectionHandler;

- (id)init {
  self = [super init];
  if (self) {
    // Init stuff goes here
    infraredCommands = [[NSMutableArray alloc] init];
    [self codingIndependentInits];
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:self.infraredCommands forKey:@"infraredCommands"];
  [encoder encodeObject:self.host forKey:@"host"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    self.infraredCommands = [decoder decodeObjectForKey:@"infraredCommands"];
    self.host = [decoder decodeObjectForKey:@"host"];
    [self codingIndependentInits];
  }
  return self;
}

// Inits that must be done either if this object is newly inited or inted from file
- (void)codingIndependentInits {
  // Init the connectionhandler and set its delegate
  tcpConnectionHandler = [[TCPConnectionHandler alloc] init];
  tcpConnectionHandler.delegate = self;
  // Set the delegate to us for every command so that this class can get called
  for (InfraredCommand *theCommand in infraredCommands) theCommand.delegate = self;
  // Add observer to change the voice commands
}

/*
 * If the device connected successfully.
 */
-(void)deviceConnected:(GCDAsyncSocket *)sock {
  // If a device connected realloc the connectionhandler and set the delegate
  tcpConnectionHandler = [[TCPConnectionHandler alloc] initWithSocket:sock];
  tcpConnectionHandler.delegate = self;
}

/*
 * Identifies the Infrared Device with a blinking LED.
 */
-(BOOL)identify {
  NSString *command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_IDENTIFY];
  return [tcpConnectionHandler sendCommand:command];
}

/*
 * If an IR command should be toggled.
 */
- (BOOL)toggleIRCommand:(InfraredCommand *)theInfraredCommand {
  if (DEBUG_INFRARED_DEVICE) NSLog(@"toggle command: %@, code: %li", [theInfraredCommand name], [[theInfraredCommand irCode] longValue]);
  // Set up the toggle command
  NSString *command = [NSString stringWithFormat:@"%@%@", COMMAND_PREFIX, COMMAND_TOGGLE];
  // Pack the command in a data
  NSMutableData *data = [[NSMutableData alloc] init];
  // Append the toggle command
  [data appendData:[command dataUsingEncoding:NSUTF8StringEncoding]];
  // Append the data for the toggle command directly from the ir command
  [data appendData:[theInfraredCommand toggleCommand]];
  // Send the data and store if succesfully sent
  return [tcpConnectionHandler sendData:data];
}

/*
 * If an IR command should be learned.
 */
- (BOOL)learnIRCommand:(InfraredCommand *)theInfraredCommand {
  // Store the command and set the internal state to learning
  learning = true;
  learnCommand = theInfraredCommand;
  if (DEBUG_INFRARED_DEVICE) NSLog(@"learn new command: %@", [learnCommand name]);
  // Get the learn command and send it to the socket
  NSString *command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_LEARN];
  return [tcpConnectionHandler sendCommand:command];
}

/*
 * If an IR command should be added.
 */
-(void)addIRCommand:(InfraredCommand *)theInfraredCommand {
  // If the command does not exist yet, add it to the list of command
  if (![infraredCommands containsObject:theInfraredCommand]) {
    [infraredCommands addObject:theInfraredCommand];
    // Set the its delegate
    theInfraredCommand.delegate = self;
    
    // Post notification for adding device
    [[NSNotificationCenter defaultCenter] postNotificationName:IRDeviceCountChanged object:self];
  }
}


/*
 * If an IR command should be removed.
 */
-(void)removeIRCommand:(InfraredCommand *)theInfraredCommand {
  // If the command exists in the list of command
  if ([infraredCommands containsObject:theInfraredCommand]) {
    // Remove it, set it to nil and also set the delegate to nil
    [infraredCommands removeObject:theInfraredCommand];
    theInfraredCommand.delegate = nil;
    theInfraredCommand = nil;
    // Post notification for adding device
    [[NSNotificationCenter defaultCenter] postNotificationName:IRDeviceCountChanged object:self];
  }
}


/*
 * Returns if the device is connected over tcp or not.
 */
- (BOOL)isConnected {
  return [tcpConnectionHandler isConnected];
}

/*
 * If the device sent a command to us.
 */
-(void)receivedCommand:(NSString *)theCommand {
  if (DEBUG_INFRARED_DEVICE) NSLog(@"Received IR Command: %@", theCommand);
  // If the command was a learning command
  if ([theCommand containsString:COMMAND_LEARNED]) {
    // If we are not learning anymore return
    if (!learning) return;
    // Remove the learning string from the data
    NSRange range = [theCommand rangeOfString:COMMAND_LEARNED];
    NSString *cmd = [theCommand substringFromIndex:range.location + range.length];
    if (DEBUG_INFRARED_DEVICE) NSLog(@"LearnedStr: %@", cmd);
    // Let the command decode the received data
    [learnCommand gotLearnCommand:cmd];
    // Set learning mode to false
    learning = false;
  }
}

/*
 * Returns the discovering command response for discovering hoovers.
 */
-(NSString *)discoverCommandResponse {
  return DISCOVER_COMMAND_RESPONSE;
}

/*
 * To make the socket free if the device is deleted
 */
- (void) freeSocket {
  // Free the socket again
  if (DEBUG_INFRARED_DEVICE) NSLog(@"Free socket of ir device");
  if (!tcpConnectionHandler.socket) return;
  TCPServer *tcpServer = [TCPServer sharedTCPServer];
  [tcpServer freeSocket:tcpConnectionHandler.socket];
}



#pragma mark voice command functions

/*
 * Return the available selectors for voice commands.
 */
-(NSArray *)selectors {
  NSMutableArray *selectors = [[NSMutableArray alloc] init];
  for (InfraredCommand *theIRCommand in infraredCommands) {
    if (![[theIRCommand name] isEqualToString:IRCommandEmptyCommand]) {
      [selectors addObject:[NSString stringWithFormat:@"%@%@",IRDeviceSelectorToggle, [theIRCommand name]]];
    }
  }
  return selectors;
}

/*
 * Returns the voice command extensions the device should be sensitive to.
 */
-(NSArray *)readableSelectors {
  NSMutableArray *selectors = [[NSMutableArray alloc] init];
  for (InfraredCommand *theIRCommand in infraredCommands) {
    if (![[theIRCommand name] isEqualToString:IRCommandEmptyCommand]) {
      [selectors addObject:[NSString stringWithFormat:@"Toggle %@", [theIRCommand name]]];
    }
  }
  return selectors;
}

/*
 * Toggles the given command
 */
- (NSDictionary*)toggleIR:(NSString *)theCommandName {
 
  // Look what command was spoken
  for (InfraredCommand *theCommand in infraredCommands) {
    if ([theCommandName isEqualToString:[theCommand name]]) {
      if (DEBUG_INFRARED_DEVICE) NSLog(@"Toggle: %@", [theCommand name]);
      // Toggle the ir command
      [self toggleIRCommand:theCommand];
    }
  }
  
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:[self isConnected]],
          KeyVoiceCommandExecutedSuccessfully, @"Okay", KeyVoiceCommandResponseString, nil];
}


#pragma mark InfraredCommand delegate functions
// The ir command wants to be learned
-(void)learnCommand:(InfraredCommand *)theCommand {
  [self learnIRCommand:theCommand];
}

// We should stop learning
- (void)stopLearning {
  learning = false;
}

// The ir command wants to be toggled
-(void)toggle:(InfraredCommand *)theCommand {
  [self toggleIRCommand:theCommand];
}

// The ir command wants to be deleted
-(void)deleteCommand:(InfraredCommand *)theCommand {
  if (DEBUG_INFRARED_DEVICE) NSLog(@"delete command: %@", [theCommand name]);
  [self removeIRCommand:theCommand];
}

@end
