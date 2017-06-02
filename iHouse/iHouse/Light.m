//
//  Light.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "Light.h"
#import "VoiceCommandHandler.h"

// All Commands that are send to or received by the serialport
#define COMMAND_RESPONSE @"/"
#define COMMAND_LIGHT @"s"
#define COMMAND_CMI @"c"
#define COMMAND_SNIFF_CMI @"i"
#define COMMAND_CMI_ON @"01"
#define COMMAND_CMI_OFF @"10"
#define COMMAND_CONRAD @"o"
#define COMMAND_FREETEC @"f"

#define VOICE_COMMAND_ON @"on"
#define VOICE_RESPONSES_ON @"The Light is turned on now.", @"Okay, Light on."
#define VOICE_COMMAND_OFF @"off"
#define VOICE_RESPONSES_OFF @"The Light is turned off now.", @"Okay, Light off."
#define VOICE_RESPONSES_WENT_WRONG @"Something went wrong.", @"Connection problem."


// For notification when a light was sniffed succesfully
NSString * const LightSniffedSuccessfully = @"LightSniffedSuccessfully";
NSString * const LightSwitched = @"LightSwitched";

@implementation Light
@synthesize type, cmiTristate, conradGroup, conradNumber, freetecCode1, freetecCode2, freetecCode3, state, connectionHandler;

- (id)init {
  self = [super init];
  if (self) {
    // Init global variable
    type = freeTec_light;
    cmiTristate = @"0000000000";
    conradNumber = 1;
    conradGroup = 1;
    freetecCode1 = arc4random_uniform(255);
    freetecCode2 = arc4random_uniform(255);
    freetecCode3 = arc4random_uniform(5);
    state = false;
    // Init the connectionHandler object
    connectionHandler = [SerialConnectionHandler sharedSerialConnectionHandler];
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeBool:self.state forKey:@"state"];
  [encoder encodeInteger:self.type forKey:@"type"];
  [encoder encodeInteger:self.freetecCode1 forKey:@"freetecCode1"];
  [encoder encodeInteger:self.freetecCode2 forKey:@"freetecCode2"];
  [encoder encodeInteger:self.freetecCode3 forKey:@"freetecCode3"];
  [encoder encodeInteger:self.conradGroup forKey:@"conradGroup"];
  [encoder encodeInteger:self.conradNumber forKey:@"conradNumber"];
  [encoder encodeObject:self.cmiTristate forKey:@"cmiTristate"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    self.state = [decoder decodeBoolForKey:@"state"];
    self.type = [decoder decodeIntegerForKey:@"type"];
    self.freetecCode1 = [decoder decodeIntegerForKey:@"freetecCode1"];
    self.freetecCode2 = [decoder decodeIntegerForKey:@"freetecCode2"];
    self.freetecCode3 = [decoder decodeIntegerForKey:@"freetecCode3"];
    self.conradGroup = [decoder decodeIntegerForKey:@"conradGroup"];
    self.conradNumber = [decoder decodeIntegerForKey:@"conradNumber"];
    self.cmiTristate = [decoder decodeObjectForKey:@"cmiTristate"];
    // Init the connectionHandler object
    connectionHandler = [SerialConnectionHandler sharedSerialConnectionHandler];
  }
  return self;
}

/*
 * Returns if the Light switcher is connected over serial.
 */
- (BOOL)isConnected {
  return [connectionHandler serialPortIsOpen];
}

/*
 * Called if the user want to sniff a CMI device
 */
- (void)sniffCMI {
  // Register to get notifications if the serialport responsed with the tristate
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(sniffReceived:)
                                               name:SerialConnectionHandlerSerialResponse
                                             object:nil];
  // Send the sniff Command
  NSString *command = [NSString stringWithFormat:@"%@%@",COMMAND_LIGHT, COMMAND_SNIFF_CMI];
  NSDictionary* commandDict = [NSDictionary dictionaryWithObjectsAndKeys:command , SerialConnectionHandlerCommand, nil];
  //[[NSNotificationCenter defaultCenter] postNotificationName:ConnectionHandlerSerialCommand object:commandDict];
  [connectionHandler sendSerialCommand:commandDict];
}

/*
 * If something is received over serial this function looks if it is a light sniff command and if so, stores the sniffed
 * Tristate and informs delegates that sniff succeeded
 */
- (void)sniffReceived:(NSNotification *)notification {
  NSString *theCommand = [notification object];
  NSString *cmdPrefix = [NSString stringWithFormat:@"%@%@%@", COMMAND_RESPONSE, COMMAND_LIGHT, COMMAND_SNIFF_CMI];
  // If the beginning of the string contains the sniff command
  if ([[theCommand substringToIndex:[cmdPrefix length]] containsString:cmdPrefix]) {
    // Store the tristate
    cmiTristate = [theCommand substringFromIndex:[cmdPrefix length]];
    //NSLog(@"Heurika: %@", cmiTristate);
    // Remove the observer from the notificationcenter
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SerialConnectionHandlerSerialResponse object:nil];
    // And inform other that sniffing was successfull
    [[NSNotificationCenter defaultCenter] postNotificationName:LightSniffedSuccessfully object:nil];
  }
}

/*
 * If the user pressed cancel the sniffing is aborted.
 */
- (void)sniffCMIDismissed {
  // Remove the observer
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SerialConnectionHandlerSerialResponse object:nil];
  // Send something stupid over serial to stop the sniffing
  NSString *command = [NSString stringWithFormat:@"%@%@",COMMAND_LIGHT, COMMAND_CMI_OFF];
  NSDictionary* commandDict = [NSDictionary dictionaryWithObjectsAndKeys:command , SerialConnectionHandlerCommand, nil];
  //[[NSNotificationCenter defaultCenter] postNotificationName:ConnectionHandlerSerialCommand object:commandDict];
  [connectionHandler sendSerialCommand:commandDict];
}

/*
 * If a new freetec device should be learned.
 */
- (void)learnFreetec {
  // Generalte new random code
  freetecCode1 = arc4random_uniform(255);
  freetecCode2 = arc4random_uniform(255);
  freetecCode3 = arc4random_uniform(5);
  // Generate the command to learn the freetec light and send it with the connectionhandler
  NSData *data = [[NSData alloc] init];
  NSString *command = [NSString stringWithFormat:@"%@%@",COMMAND_LIGHT, COMMAND_FREETEC];
  const unsigned char free_bytes[] = {(Byte)freetecCode1, (Byte)freetecCode2, (Byte)freetecCode3, 1, 1};
  //NSLog(@"FreeTec %i %i %i %i", (int)freetecCode1, (int)freetecCode2, (int)freetecCode3, theState);
  data = [NSData dataWithBytes:free_bytes length:sizeof(free_bytes)];
  NSDictionary* commandDict = [NSDictionary dictionaryWithObjectsAndKeys:command , SerialConnectionHandlerCommand,
                               data , SerialConnectionHandlerData, nil];
  //[[NSNotificationCenter defaultCenter] postNotificationName:ConnectionHandlerSerialCommand object:commandDict];
  [connectionHandler sendSerialCommand:commandDict];
}


/*
 * Toggles the device on or off
 */
- (BOOL)toggle:(BOOL) theState {
  // Construct the command depending on the type of light and on the state
  NSString *command = COMMAND_LIGHT;
  NSData *data = [[NSData alloc] init];
  switch (type) {
      // Freetec devices command: "sf<(int)header1><(int)header2><(int)header3><(bool)theState><(bool)learn>"
    case freeTec_light:
      command = [NSString stringWithFormat:@"%@%@",command, COMMAND_FREETEC];
      const unsigned char free_bytes[] = {(Byte)freetecCode1, (Byte)freetecCode2, (Byte)freetecCode3, theState, 0};
      //NSLog(@"FreeTec %i %i %i %i", (int)freetecCode1, (int)freetecCode2, (int)freetecCode3, theState);
      data = [NSData dataWithBytes:free_bytes length:sizeof(free_bytes)];
      break;
      // CMI devices command: "sc<(char[10])Tristate><(char[2])theState>"
    case cmi_light:
      command = [NSString stringWithFormat:@"%@%@%@",command, COMMAND_CMI, cmiTristate];
      if (theState) {
        command = [NSString stringWithFormat:@"%@%@", command, COMMAND_CMI_ON];
      } else {
        command = [NSString stringWithFormat:@"%@%@", command, COMMAND_CMI_OFF];
      }
      break;
      // Conrad devices command: "so<(int)group><(int)number><(bool)theState>"
    case conrad_light:
      command = [NSString stringWithFormat:@"%@%@",command, COMMAND_CONRAD];
      const unsigned char con_bytes[] = {(int)conradGroup, (int)conradNumber, theState};
      //NSLog(@"Conrad %i %i %i", (int)conradGroup, (int)conradNumber, theState);
      data = [NSData dataWithBytes:con_bytes length:sizeof(con_bytes)];
      break;
  }
  
  // Generate command and send it with the connectionhandler
  NSDictionary* commandDict = [NSDictionary dictionaryWithObjectsAndKeys:command , SerialConnectionHandlerCommand,
                               data , SerialConnectionHandlerData, nil];
  // Update state variable if connectionhandler returned successfull transmission
  if ([connectionHandler sendSerialCommand:commandDict]) {
    NSLog(@"%@", commandDict);
    state = theState;
    // Post notification so that other can change their view
    [[NSNotificationCenter defaultCenter] postNotificationName:LightSwitched object:nil];
    return true;
  }
  return false;
}


#pragma mark voice command functions

/*
 * Toggles the device on
 */
- (NSDictionary*)toggleOn {
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:[self toggle:true]],
          KeyVoiceCommandExecutedSuccessfully, nil];
}

/*
 * Toggles the device off
 */
- (NSDictionary*)toggleOff {
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:[self toggle:false]],
          KeyVoiceCommandExecutedSuccessfully, nil];
}

/*
 * Toggles the device
 */
- (NSDictionary*)toggle {
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:[self toggle:!self.state]],
          KeyVoiceCommandExecutedSuccessfully, nil];
}

/*
 * Returns the standard voice commands of the device.
 */
-(NSArray *)standardVoiceCommands {
  VoiceCommand *onCommand = [[VoiceCommand alloc] init];
  [onCommand setName:VOICE_COMMAND_ON];
  [onCommand setCommand:VOICE_COMMAND_ON];
  [onCommand setSelector:@"toggleOn"];
  [onCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_ON, nil]];
  VoiceCommand *offCommand = [[VoiceCommand alloc] init];
  [offCommand setName:VOICE_COMMAND_OFF];
  [offCommand setCommand:VOICE_COMMAND_OFF];
  [offCommand setSelector:@"toggleOff"];
  [offCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_OFF, nil]];
  NSArray *commands = [[NSArray alloc] initWithObjects:onCommand, offCommand, nil];
  return commands;
}

/*
 * Return the available selectors for voice commands.
 */
-(NSArray *)selectors {
  return [[NSArray alloc] initWithObjects:@"toggleOn", @"toggleOff", @"toggle", nil];
}

/*
 * Returns the voice command extensions the device should be sensitive to.
 */
-(NSArray *)readableSelectors {
  return [[NSArray alloc] initWithObjects:@"Turn light on", @"Turn light off", @"Toggle light", nil];
}


@end
