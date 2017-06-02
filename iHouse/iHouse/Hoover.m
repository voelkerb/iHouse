//
//  Hoover.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "Hoover.h"
#import "TCPServer.h"
#import "VoiceCommand.h"

#define DEBUG_HOOVER true

#define DISCOVER_COMMAND_RESPONSE @"iHouseHoover"
#define COMMAND_PREFIX @"/"
#define COMMAND_IDENTIFY @"x"
#define COMMAND_START @"b"
#define COMMAND_DOCK @"c"
#define COMMAND_FORWARD @"w"
#define COMMAND_BACKWARD @"s"
#define COMMAND_STOP @" "
#define COMMAND_RIGHT @"d"
#define COMMAND_LEFT @"a"
#define COMMAND_SPEED @"p"
#define COMMAND_RADIUS @"t"


#define VOICE_COMMAND_START @"Start hoovering"
#define VOICE_RESPONSES_START @"The Hoover starts cleaning now.", @"Roomba go!."

#define VOICE_COMMAND_RETURN @"Return hoover"
#define VOICE_RESPONSES_RETURN @"The Hoover is going to the dock now.", @"Returning to the base!"
#define VOICE_RESPONSES_STOP @"Much cleaner now."
#define VOICE_COMMAND_STOP @"Stop hoovering"

#define VOICE_RESPONSES_NOT_CONNECTED @"Connection problem.", @"Sorry but the hoover is not connected."


@implementation Hoover
@synthesize tcpConnectionHandler, host, speed, isCleaning;

- (id)init {
  self = [super init];
  if (self) {
    host = @"";
    speed = 1000;
    [self codingIndependentInits];
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  // Coding stuff goes here
  [encoder encodeInteger:self.speed forKey:@"speed"];
  [encoder encodeObject:self.host forKey:@"host"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    // decoding stuff goes here
    self.speed = [decoder decodeIntegerForKey:@"speed"];
    self.host = [decoder decodeObjectForKey:@"host"];
    [self codingIndependentInits];
  }
  return self;
}

// Inits that must be done either if this object is newly inited or inted from file
- (void)codingIndependentInits {
  tcpConnectionHandler = [[TCPConnectionHandler alloc] init];
  tcpConnectionHandler.delegate = self;
  isCleaning = false;
}

/*
 * If the device connected successfully.
 */
-(void)deviceConnected:(GCDAsyncSocket *)sock {
  tcpConnectionHandler = [[TCPConnectionHandler alloc] initWithSocket:sock];
  tcpConnectionHandler.delegate = self;
}
/*
 * Identifies the roomba.
 */
-(BOOL)identify {
  NSString *command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_IDENTIFY];
  return [tcpConnectionHandler sendCommand:command];
}

/*
 * Simulates a start cleaning button press on the roomba.
 */
-(BOOL)startCleaning {
  BOOL success = true;
  NSString *command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_START];
  success = [tcpConnectionHandler sendCommand:command];
  if (success) isCleaning = true;
  return success;
}

/*
 * Simulates a stop cleaning button press on the roomba.
 */
-(BOOL)stopCleaning {
  BOOL success = true;
  NSString *command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_START];
  success = [tcpConnectionHandler sendCommand:command];
  if (success) isCleaning = false;
  return success;
}

/*
 * Simulates a come to Dock button press on the roomba.
 */
-(BOOL)comeToDock {
  BOOL success = true;
  NSString *command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_DOCK];
  success = [tcpConnectionHandler sendCommand:command];
  if (success) isCleaning = false;
  return success;
}

/*
 * Controlls the roomba.
 */
-(BOOL)drive:(RoombaDriveMode)mode :(NSInteger)theSpeed {
  BOOL success = true;
  NSString *command = @"";
  // If the speed is the current set speed, dont send the speed as well
  if (theSpeed != speed) {
    command = [NSString stringWithFormat:@"%@%@", COMMAND_PREFIX, COMMAND_SPEED];
    NSMutableData *data = [[NSMutableData alloc] init];
    [data appendData:[command dataUsingEncoding:NSUTF8StringEncoding]];
    // Speed is send as two bytes with MSB first
    char velocity[2];
    velocity[0] = (((int)theSpeed >> 8) & 0xFF);
    velocity[1] = ((int)theSpeed & 0xFF);
    [data appendBytes:&velocity length:2];
    success = [tcpConnectionHandler sendData:data];
    if (DEBUG_HOOVER) NSLog(@"Speed: %i %i", velocity[0], velocity[1]);
    // If this does not succeed the rest wont as well
    if (!success) return false;
  }
  // Update the speed
  speed = theSpeed;
  // Switch the driving mode and set the command accordingly
  switch (mode) {
    case roomba_stop:
      command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_STOP];
      break;
    case roomba_forward:
      command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_FORWARD];
      break;
    case roomba_backward:
      command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_BACKWARD];
      break;
    case roomba_left:
      command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_LEFT];
      break;
    case roomba_left_hard:
      command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_LEFT];
      break;
    case roomba_right:
      command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_RIGHT];
      break;
    case roomba_right_hard:
      command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_RIGHT];
      break;
  }
  success = [tcpConnectionHandler sendCommand:command];
  return success;
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
  if (DEBUG_HOOVER) NSLog(@"Received roomba Command: %@", theCommand);
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
  if (DEBUG_HOOVER) NSLog(@"Free socket of hoover");
  if (!tcpConnectionHandler.socket) return;
  TCPServer *tcpServer = [TCPServer sharedTCPServer];
  [tcpServer freeSocket:tcpConnectionHandler.socket];
}





#pragma mark voice command functions

/*
 * Starts the Roomba
 */
- (NSDictionary*)start {
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:[self startCleaning]],
          KeyVoiceCommandExecutedSuccessfully, nil];
}

/*
 * Stops the Roomba.
 */
- (NSDictionary*)stop {
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:[self stopCleaning]],
          KeyVoiceCommandExecutedSuccessfully, nil];
}

/*
 * Returns the Roomba to base.
 */
- (NSDictionary*)returnBase {
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:[self comeToDock]],
          KeyVoiceCommandExecutedSuccessfully, nil];
}

/*
 * Returns the standard voice commands of the device.
 */
-(NSArray *)standardVoiceCommands {
  VoiceCommand *startCommand = [[VoiceCommand alloc] init];
  [startCommand setName:VOICE_COMMAND_START];
  [startCommand setCommand:VOICE_COMMAND_START];
  [startCommand setSelector:@"start"];
  [startCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_START, nil]];
  VoiceCommand *stopCommand = [[VoiceCommand alloc] init];
  [stopCommand setName:VOICE_COMMAND_STOP];
  [stopCommand setCommand:VOICE_COMMAND_STOP];
  [stopCommand setSelector:@"stop"];
  [stopCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_STOP, nil]];
  VoiceCommand *returnCommand = [[VoiceCommand alloc] init];
  [returnCommand setName:VOICE_COMMAND_RETURN];
  [returnCommand setCommand:VOICE_COMMAND_RETURN];
  [returnCommand setSelector:@"returnBase"];
  [returnCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_RETURN, nil]];
  NSArray *commands = [[NSArray alloc] initWithObjects:startCommand, stopCommand, returnCommand, nil];
  return commands;
}

/*
 * Return the available selectors for voice commands.
 */
-(NSArray *)selectors {
  return [[NSArray alloc] initWithObjects:@"start", @"stop", @"returnBase", nil];
}

/*
 * Returns the voice command extensions the device should be sensitive to.
 */
-(NSArray *)readableSelectors {
  return [[NSArray alloc] initWithObjects:@"Start Roomba", @"Stop Roomba", @"Roomba returns to base", nil];
}

@end
