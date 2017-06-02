//
//  Microphone.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "Microphone.h"
#import "TCPServer.h"
#import "VoiceCommand.h"
#import "MicrophoneStreamHandler.h"

#define DEBUG_MICRO true

#define DISCOVER_COMMAND_RESPONSE @"iHouseMicro"
#define COMMAND_PREFIX @"/"
#define COMMAND_AUDIO_ON @"a"
#define COMMAND_AUDIO_OFF @"o"
#define COMMAND_MICRO_ON @"m"
#define COMMAND_MICRO_OFF @"n"
#define COMMAND_OK_HOUSE_DETECTED @"/okHouse"

@implementation Microphone
@synthesize microphoneStreamHandler, micID, state;

- (id)init {
  self = [super init];
  if (self) {
    // Init stuff goes here
    micID = -1;
    [self codingIndependentInits];
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  // Coding stuff goes here
  [encoder encodeInteger:self.micID forKey:@"micID"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    // decoding stuff goes here
    self.micID = [decoder decodeIntegerForKey:@"micID"];
    [self codingIndependentInits];
  }
  return self;
}

// Inits that must be done either if this object is newly inited or inted from file
- (void)codingIndependentInits {
  microphoneStreamHandler = [MicrophoneStreamHandler sharedMicrophoneStreamHandler];
  state = micro_idle;
  // Stop audio and mic streaming on init
  //[self audioOff];
}

/*
 * Returns if the MicroStation is connected over USB or not.
 */
- (BOOL)isConnected {
  return [[microphoneStreamHandler connectionHandler] serialPortIsOpen];
}

/*
 * Let the micro start playing audio.
 */
- (BOOL)audioOn {
  // Indicate transmitting state to other microphones
  if (microphoneStreamHandler.state != audioStream_idle) return false;
  state = micro_receivingAudio;
  return [microphoneStreamHandler streamToMicWithID:micID];
}

/*
 * Let the micro stop playing audio.
 */
- (BOOL)audioOff {
  // Indicate idle state to other microphones
  state = micro_idle;
  return [microphoneStreamHandler stopStreaming];
}
 
@end
