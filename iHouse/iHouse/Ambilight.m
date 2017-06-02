//
//  AmbiLight.m
//  iHouse
//
//  Created by Benjamin Völker on 06.03.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "Ambilight.h"
#import "VoiceCommand.h"

#define VOICE_COMMAND_ON @"on"
#define VOICE_COMMAND_FADE @"fade"
#define VOICE_RESPONSES_AMB_ON @"The ambilight is turned on now.", @"Okay, ambilight on."
#define VOICE_RESPONSES_FADE_ON @"Fading is turned on now.", @"Okay, fading on."
#define VOICE_COMMAND_OFF @"off"
#define VOICE_RESPONSES_OFF @"The ambilight is turned off now.", @"Okay, I make it dark."
#define VOICE_RESPONSES_WENT_WRONG @"Something went wrong.", @"Connection problem."

@implementation Ambilight

- (id)init {
  self = [super init];
  if (self) {
    [self codingIndependentInits];
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    [self codingIndependentInits];
  }
  return self;
}

-(void)codingIndependentInits {
  ambilightService = [AmbilightService sharedAmbilightService];
}

/*
 * Returns if the ambilight switcher is connected over serial.
 */
- (BOOL)isConnected {
  // TODO
  return true;
}

/*
 * Toggles the device on or off
 */
- (BOOL)toggleAmbilight:(BOOL) theState {
  
  ambilightService.ambilight = theState;
  [ambilightService sendData];
  // TODO
  return false;
}


/*
 * Toggles the device on or off
 */
- (BOOL)toggleFade:(BOOL) theState {
  
  ambilightService.fade = theState;
  [ambilightService sendData];
  // TODO
  return false;
}

/*
 * Change brightness
 */
- (BOOL)brightnessChange:(float) brightness {
  ambilightService.brightness = brightness;
  [ambilightService sendData];
  // TODO
  return false;
}

/*
 * Change brightness
 */
- (BOOL)changeColor:(NSColor*) color {
  
  ambilightService.currentColor = color;
  [ambilightService sendData];
  // TODO
  return false;
}


#pragma mark voice command functions

/*
 * Toggles the device
 */
- (NSDictionary*)ambilightOn {
  bool success = true;
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:[self toggleAmbilight:success]],
          KeyVoiceCommandExecutedSuccessfully, nil];
}
/*
 * Toggles the device
 */
- (NSDictionary*)fadeOn {
  bool success = true;
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:[self toggleFade:success]],
          KeyVoiceCommandExecutedSuccessfully, nil];
}
/*
 * Toggles the device
 */
- (NSDictionary*)makeDark {
  bool success = true;
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:[self toggleFade:success]],
          KeyVoiceCommandExecutedSuccessfully, nil];
}

/*
 * Returns the standard voice commands of the device.
 */
-(NSArray *)standardVoiceCommands {
  VoiceCommand *ambOnCommand = [[VoiceCommand alloc] init];
  [ambOnCommand setName:VOICE_COMMAND_ON];
  [ambOnCommand setCommand:VOICE_COMMAND_ON];
  [ambOnCommand setSelector:@"ambilightOn"];
  [ambOnCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_AMB_ON, nil]];
  VoiceCommand *ambOffCommand = [[VoiceCommand alloc] init];
  [ambOffCommand setName:VOICE_COMMAND_OFF];
  [ambOffCommand setCommand:VOICE_COMMAND_OFF];
  [ambOffCommand setSelector:@"makeDark"];
  [ambOffCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_OFF, nil]];
  VoiceCommand *fadeOnCommand = [[VoiceCommand alloc] init];
  [fadeOnCommand setName:VOICE_COMMAND_FADE];
  [fadeOnCommand setCommand:VOICE_COMMAND_FADE];
  [fadeOnCommand setSelector:@"fadeOn"];
  [fadeOnCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_FADE_ON, nil]];
  NSArray *commands = [[NSArray alloc] initWithObjects:ambOnCommand, ambOffCommand,fadeOnCommand, nil];
  return commands;
}

/*
 * Return the available selectors for voice commands.
 */
-(NSArray *)selectors {
  return [[NSArray alloc] initWithObjects:@"fadeOn", @"fadeOn", @"makeDark", nil];
}

/*
 * Returns the voice command extensions the device should be sensitive to.
 */
-(NSArray *)readableSelectors {
  return [[NSArray alloc] initWithObjects:@"Ambilight on","Fade on", @"Make dark", nil];
}

@end
