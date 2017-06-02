//
//  Heating.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "Heating.h"
#import "TCPServer.h"
#import "VoiceCommand.h"

#define DEBUG_HEATING true

#define STANDARD_TEMP 5

#define DISCOVER_COMMAND_RESPONSE @"iHouseHeating"

#define COMMAND_PREFIX @"/"
#define COMMAND_BOOST @"b"
#define COMMAND_SET_TEMP @"t"
#define COMMAND_GET_TEMP @"g"
#define COMMAND_LOCK @"l"
#define COMMAND_ADAPTATION @"a"
#define COMMAND_RESET @"r"

#define VOICE_COMMAND_BOOST @"Start temperature boost in "
#define VOICE_RESPONSES_BOOST @"Warming up now.", @"The heating boosts now."

#define VOICE_COMMAND_OFF @"Stop heating in"
#define VOICE_COMMAND_SET_TEMP @"Set temperature to %i degrees in"
#define VOICE_COMMAND_SET_TEMP_LOOKUP @"Set temperature to "
#define VOICE_RESPONSE_SET_TEMP @"Okay, the temperature was set to %@ degrees."
#define VOICE_RESPONSE_TEMP_ALREADY_SET @"Sorry but this temperature is already set."
#define VOICE_RESPONSES_TEMP_RISING @"I will make it warm.", @"I feel cold too.", @"So I am not the only one freezing."
#define VOICE_RESPONSES_TEMP_FALLING @"Yeah it's warm enough in here.", @"Cooling down!"

#define VOICE_RESPONSES_NOT_CONNECTED @"Connection problem.", @"Sorry but the heating is not connected."
#define VOICE_RESPONSES_TEMPERATURE_ERROR @"Sorry but I can only set the temperature between 5 and 30 degrees."


NSString * const HeatingTempDidChange = @"HeatingTempDidChange";
NSString * const HeatingSelectorSetTemp = @"setHeatingTemp:";

@implementation Heating
@synthesize tcpConnectionHandler, host, currentTemperature;

- (id)init {
  self = [super init];
  if (self) {
    // Init stuff goes here
    currentTemperature = [NSNumber numberWithInt:STANDARD_TEMP];
    host = @"";
    [self codingIndependentInits];
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  // Coding stuff goes here
  [encoder encodeObject:self.host forKey:@"host"];
  [encoder encodeObject:self.currentTemperature forKey:@"currentTemperature"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    // decoding stuff goes here
    self.host = [decoder decodeObjectForKey:@"host"];
    self.currentTemperature = [decoder decodeObjectForKey:@"currentTemperature"];
    [self codingIndependentInits];
  }
  return self;
}

// Inits that must be done either if this object is newly inited or inted from file
- (void)codingIndependentInits {
  tcpConnectionHandler = [[TCPConnectionHandler alloc] init];
  tcpConnectionHandler.delegate = self;
}

/*
 * If the device connected successfully.
 */
-(void)deviceConnected:(GCDAsyncSocket *)sock {
  tcpConnectionHandler = [[TCPConnectionHandler alloc] initWithSocket:sock];
  tcpConnectionHandler.delegate = self;
}



/*
 * Makes adaptaion on the heating device.
 */
- (BOOL)ada {
  NSString *command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_ADAPTATION];
  return [tcpConnectionHandler sendCommand:command];
}

/*
 * Resets the heating device.
 */
- (BOOL)reset {
  NSString *command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_RESET];
  return [tcpConnectionHandler sendCommand:command];
}

/*
 * Simulates a lock of the heating device.
 */
- (BOOL)lock {
  NSString *command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_LOCK];
  return [tcpConnectionHandler sendCommand:command];
}

/*
 * Simulates a boost press on the heating device.
 */
- (BOOL)boost {
  NSString *command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_BOOST];
  return [tcpConnectionHandler sendCommand:command];
}


/*
 * Sets the temperature to the given temperature on the heating device.
 */
- (BOOL)setTemp:(NSNumber *)temp {
  if ([temp intValue] > HEATING_MAX_TEMP || [temp intValue] < HEATING_MIN_TEMP) return true;
  BOOL success = true;
  NSString *command = [NSString stringWithFormat:@"%@%@", COMMAND_PREFIX, COMMAND_SET_TEMP];
  // Store the integer in two bytes and attach it with the command to a data packed
  NSMutableData *data = [[NSMutableData alloc] init];
  [data appendData:[command dataUsingEncoding:NSUTF8StringEncoding]];
  char theTemp[2];
  // Send the float value of 0.5 steps as a double int value (e.g. 12.5° == 25)
  double floatTemp = [temp doubleValue]*2;
  int intTemp = (int)floatTemp;
  if (DEBUG_HEATING) NSLog(@"Set temp to: %i /2", intTemp);
  // First byte is MSB, second byte is LSB
  theTemp[0] = ((intTemp >> 8) & 0xFF);
  theTemp[1] = (intTemp & 0xFF);
  [data appendBytes:&theTemp length:2];
  // This data packed is send to the heating device
  success = [tcpConnectionHandler sendData:data];
  // Set member to new temperature on success
  if (success) currentTemperature = temp;
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
  if (DEBUG_HEATING) NSLog(@"Received Heating Command: %@", theCommand);
  // If the command was a set temp command change the member
  if ([theCommand containsString:COMMAND_SET_TEMP]) {
    // Get the temperature
    NSNumber *temp = [NSNumber numberWithDouble:[[theCommand substringFromIndex:
                                                  [theCommand rangeOfString:COMMAND_SET_TEMP].location +
                                                  [COMMAND_SET_TEMP length]] doubleValue]];
    if (DEBUG_HEATING) NSLog(@"Set temp to: %@",temp);
    // If the temperature was in range update the member and post a notification
    if ([temp integerValue] >= HEATING_MIN_TEMP && [temp integerValue] <= HEATING_MAX_TEMP) {
      currentTemperature = temp;
      [[NSNotificationCenter defaultCenter] postNotificationName:HeatingTempDidChange object:self];
    }
  // If it was a boost command
  } else if ([theCommand containsString:COMMAND_BOOST]) {
    if (DEBUG_HEATING) NSLog(@"Boost was pressed");
  }
}

/*
 * Returns the discovering command response for discovering device.
 */
-(NSString *)discoverCommandResponse {
  return DISCOVER_COMMAND_RESPONSE;
}

/*
 * To make the socket free if the device is deleted
 */
- (void) freeSocket {
  // Free the socket again
  if (DEBUG_HEATING) NSLog(@"Free socket of heating");
  if (!tcpConnectionHandler.socket) return;
  TCPServer *tcpServer = [TCPServer sharedTCPServer];
  [tcpServer freeSocket:tcpConnectionHandler.socket];
}





#pragma mark voice command functions

/*
 * Returns the movement.
 */
- (NSDictionary*)heatingBoost {
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:[self boost]], KeyVoiceCommandExecutedSuccessfully, nil];
}

/*
 * Returns the temperature.
 */
- (NSDictionary*)setHeatingTemp:(NSString*)theTempAsString {
  // The spoen response
  NSArray *responses = [[NSArray alloc] init];
  
  BOOL error = false;
  NSNumber *temp = [NSNumber numberWithDouble:[theTempAsString doubleValue]];
  if (DEBUG_HEATING) NSLog(@"Temp: %@, %@, Connected: %i", temp, currentTemperature, [self isConnected]);
  // Init response array
  NSMutableArray *theResponses = [[NSMutableArray alloc] init];
  NSString *responseString = [NSString stringWithFormat:VOICE_RESPONSE_SET_TEMP, temp];
  // Voice response for rising temperature
  if ([temp intValue] > [currentTemperature intValue]) {
    theResponses = [[NSMutableArray alloc] initWithObjects:responseString, VOICE_RESPONSES_TEMP_RISING, nil];
    // Voice response for falling temperature
  } else if ([temp intValue] < [currentTemperature intValue]) {
    theResponses = [[NSMutableArray alloc] initWithObjects:responseString, VOICE_RESPONSES_TEMP_FALLING, nil];
  }
  // Voice response for same temperature (must override previous)
  if ([temp intValue] == [currentTemperature intValue]) {
    theResponses = [[NSMutableArray alloc] initWithObjects:VOICE_RESPONSE_TEMP_ALREADY_SET, nil];
    // Voice response for too high or too low temperature
  } else if ([temp intValue] > HEATING_MAX_TEMP) {
    theResponses = [[NSMutableArray alloc] initWithObjects:VOICE_RESPONSES_TEMPERATURE_ERROR, nil];
  } else if ([temp intValue] < HEATING_MIN_TEMP) {
    theResponses = [[NSMutableArray alloc] initWithObjects:VOICE_RESPONSES_TEMPERATURE_ERROR, nil];
  }
  // Set responses and set temperature
  responses = [NSArray arrayWithArray:theResponses];
  if (![self isConnected]) error = true;
  if (![self setTemp:temp]) error = true;
  
  // Make random response from array
  NSString *response = @"";
  if ([responses count]) response = [responses objectAtIndex:arc4random_uniform((int)[responses count])];
  
  // Repsonse dictionary should be a text
  NSMutableDictionary *responseDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:!error],
                                       KeyVoiceCommandExecutedSuccessfully, response, KeyVoiceCommandResponseString, nil];
  return responseDict;
}

/*
 * Returns the standard voice commands of the device.
 */
-(NSArray *)standardVoiceCommands {
  
  VoiceCommand *boostCommand = [[VoiceCommand alloc] init];
  [boostCommand setName:VOICE_COMMAND_BOOST];
  [boostCommand setCommand:VOICE_COMMAND_BOOST];
  [boostCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_BOOST, nil]];
  [boostCommand setSelector:@"heatingBoost"];
  
  VoiceCommand *offCommand = [[VoiceCommand alloc] init];
  [offCommand setName:VOICE_COMMAND_OFF];
  [offCommand setCommand:VOICE_COMMAND_OFF];
  [offCommand setSelector:[NSString stringWithFormat:@"%@%i", HeatingSelectorSetTemp, 5]];
  
  VoiceCommand *tempCommand15 = [[VoiceCommand alloc] init];
  [tempCommand15 setName:[NSString stringWithFormat:VOICE_COMMAND_SET_TEMP, 15]];
  [tempCommand15 setCommand:[NSString stringWithFormat:VOICE_COMMAND_SET_TEMP, 15]];
  [tempCommand15 setSelector:[NSString stringWithFormat:@"%@%i", HeatingSelectorSetTemp, 15]];
  
  VoiceCommand *tempCommand20 = [[VoiceCommand alloc] init];
  [tempCommand20 setName:[NSString stringWithFormat:VOICE_COMMAND_SET_TEMP, 20]];
  [tempCommand20 setCommand:[NSString stringWithFormat:VOICE_COMMAND_SET_TEMP, 20]];
  [tempCommand20 setSelector:[NSString stringWithFormat:@"%@%i", HeatingSelectorSetTemp, 20]];
  
  VoiceCommand *tempCommand25 = [[VoiceCommand alloc] init];
  [tempCommand25 setName:[NSString stringWithFormat:VOICE_COMMAND_SET_TEMP, 25]];
  [tempCommand25 setCommand:[NSString stringWithFormat:VOICE_COMMAND_SET_TEMP, 25]];
  [tempCommand25 setSelector:[NSString stringWithFormat:@"%@%i", HeatingSelectorSetTemp, 25]];
  
  
  NSArray *commands = [[NSArray alloc] initWithObjects:boostCommand, offCommand, tempCommand15, tempCommand20,
                       tempCommand25, nil];
  return commands;
}

/*
 * Return the available selectors for voice commands.
 */
-(NSArray *)selectors {
  NSMutableArray *selectors = [[NSMutableArray alloc] initWithObjects:@"heatingBoost", nil];
  for (int i = HEATING_MIN_TEMP; i <= HEATING_MAX_TEMP; i++) {
    [selectors addObject:[NSString stringWithFormat:@"%@%i", HeatingSelectorSetTemp, i]];
  }
  return selectors;
}

/*
 * Returns the voice command extensions the device should be sensitive to.
 */
-(NSArray *)readableSelectors {
  NSMutableArray *selectors = [[NSMutableArray alloc] initWithObjects:@"Boost the Heating", nil];
  for (int i = HEATING_MIN_TEMP; i <= HEATING_MAX_TEMP; i++) {
    [selectors addObject:[NSString stringWithFormat:@"Sets temperature to %i degrees", i]];
  }
  return selectors;
}

@end
