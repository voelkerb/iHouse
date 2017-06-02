//
//  MicrophoneStreamHandler.m
//  iHouse
//
//  Created by Benjamin Völker on 11/09/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "MicrophoneStreamHandler.h"
#import "VoiceCommand.h"
#define DEBUG_MICRO_STREAM_HANDLER true
#define COMMAND_RESPONSE @"/"
#define COMMAND_MICRO @"e"
#define COMMAND_OK_HOUSE @"okayHouse"


#define COMMAND_START_STREAM @"q"
#define COMMAND_STOP_STREAM @"w"
#define COMMAND_STOP_MICRO @"n"
#define START_VOICE_RECOGNITION_DELAY 0.1


@implementation MicrophoneStreamHandler
@synthesize state, connectionHandler;

/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedMicrophoneStreamHandler {
  static MicrophoneStreamHandler *sharedMicrophoneStreamHandler = nil;
  @synchronized(self) {
    if (sharedMicrophoneStreamHandler == nil) {
      sharedMicrophoneStreamHandler = [[self alloc] init];
    }
  }
  return sharedMicrophoneStreamHandler;
}


/*
 * Init funciton
 */
- (id)init {
  if((self = [super init])) {
    state = audioStream_idle;
    currentMic = 0;
    // Init the connectionHandler object
    connectionHandler = [SerialConnectionHandler sharedSerialConnectionHandler];
    // Add an observer to get microphone data
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkMicroData:)
                                                 name:SerialConnectionHandlerSerialResponse
                                               object:nil];
  }
  return self;
}


/*
 * Stream to a given mic, if parameter passed is 0 we are streaming to all mics.
 */
- (BOOL)streamToMicWithID:(NSInteger)micID {
  // If the id is wrong just return here
  if (micID < 0 || micID > 10) return false;
  if (DEBUG_MICRO_STREAM_HANDLER) NSLog(@"Start streaming to: %li", micID);
  // If micID is 0 we are streaming to all mics
  NSString *command = [NSString stringWithFormat:@"%@%li", COMMAND_START_STREAM, micID];
  NSDictionary* commandDict = [NSDictionary dictionaryWithObjectsAndKeys:command , SerialConnectionHandlerCommand, nil];
  //[[NSNotificationCenter defaultCenter] postNotificationName:ConnectionHandlerSerialCommand object:commandDict];
  BOOL success = [connectionHandler sendSerialCommand:commandDict];
  if (success) {
    // Indicate audio tranmsmitting state to other microphones
    state = audioStream_transmittingAudio;
  }
  return success;
}

/*
 * Stop the stream of a given mic, if parameter passed is 0 we are stopping all.
 */
- (BOOL)stopMicWithID:(NSInteger)micID {
  // If the id is wrong just return here
  if (micID < 0 || micID > 10) return false;
  if (DEBUG_MICRO_STREAM_HANDLER) NSLog(@"Stop streaming of mic: %li", micID);
  // If micID is 0 we are streaming to all mics
  NSString *command = [NSString stringWithFormat:@"%@%li", COMMAND_STOP_MICRO, micID];
  NSDictionary* commandDict = [NSDictionary dictionaryWithObjectsAndKeys:command , SerialConnectionHandlerCommand, nil];
  //[[NSNotificationCenter defaultCenter] postNotificationName:ConnectionHandlerSerialCommand object:commandDict];
  BOOL success = [connectionHandler sendSerialCommand:commandDict];
  if (success) {
    // Indicate audio tranmsmitting state to other microphones
    state = audioStream_idle;
  }
  return success;
}

/*
 * Stop streaming to any mic.
 */
- (BOOL)stopStreaming {
  if (DEBUG_MICRO_STREAM_HANDLER) NSLog(@"Stop Streaming");
  NSString *command = [NSString stringWithFormat:@"%@", COMMAND_STOP_STREAM];
  NSDictionary* commandDict = [NSDictionary dictionaryWithObjectsAndKeys:command , SerialConnectionHandlerCommand, nil];
  //[[NSNotificationCenter defaultCenter] postNotificationName:ConnectionHandlerSerialCommand object:commandDict];
  BOOL success = [connectionHandler sendSerialCommand:commandDict];
  if (success) {
    // Indicate idle state to other microphones
    state = audioStream_idle;
  }
  return success;
}

/*
 * New data from serial is available. Check if it is micro data.
 */
- (void)checkMicroData:(NSNotification*)notification {
  NSString *theCommand = [notification object];
  NSString *cmdPrefix = [NSString stringWithFormat:@"%@%@", COMMAND_RESPONSE, COMMAND_MICRO];
  if ([theCommand length] < [cmdPrefix length]) return;
  // If the beginning of the string contains the the meter command and the meter id
  if ([[theCommand substringToIndex:[cmdPrefix length]] containsString:cmdPrefix]) {
    // Store the data
    [self handleCommand:[theCommand substringFromIndex:[cmdPrefix length]]];
  }
}

/*
 * New command from serial.
 */
- (void)handleCommand:(NSString*)command {
  if (DEBUG_MICRO_STREAM_HANDLER) NSLog(@"Received Mic: %@", command);
  if ([command containsString:COMMAND_OK_HOUSE]) {
    NSRange range = [command rangeOfString:COMMAND_OK_HOUSE];
    currentMic = [[command substringFromIndex:range.location + range.length] integerValue];
    if (DEBUG_MICRO_STREAM_HANDLER) NSLog(@"MicID: %li", currentMic);
    if (DEBUG_MICRO_STREAM_HANDLER) NSLog(@"Post notification to start voice command detection");
    // Post notification to start voice command recognition after delay
    // to avoid pop sounds of the yet incoming audio data
    [self performSelector:@selector(delayedStart) withObject:nil afterDelay:START_VOICE_RECOGNITION_DELAY];
    //[[NSNotificationCenter defaultCenter] postNotificationName:StartVoiceCommandDetection object:self];
    // Add observer to get notified if voice command recognition was successfully or discarded
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceCommandDetected:) name:VoiceCommandDetectedSuccesfully object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceCommandDiscarded:) name:VoiceCommandDetectionDiscarded object:nil];
  }
}

/*
 * Delayed start of speech recognition module is used, so that pop sounds are not feed into
 * the recognizer.
 */
-(void)delayedStart {
  [[NSNotificationCenter defaultCenter] postNotificationName:StartVoiceCommandDetection object:self];
}

/*
 * If a voice response was succesfully spoken, stop audio streaming.
 * Remove previous observers.
 */
- (void)voiceResponseFinished:(NSNotification*)notification {
  if (DEBUG_MICRO_STREAM_HANDLER) NSLog(@"Voice command finished, stop audio");
  // Stop streaming
  [self stopStreaming];
  // Remove all observers
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(checkMicroData:)
                                               name:SerialConnectionHandlerSerialResponse
                                             object:nil];
}


/*
 * If a voice command was detected, stop micro and start audio.
 * Remove previous observers and add an observer for audio finish.
 */
- (void)voiceCommandDetected:(NSNotification*)notification {
  if (DEBUG_MICRO_STREAM_HANDLER) NSLog(@"Voice command detected, stop micro and start streaming audio");
  
  // Stream to room from which the microphone data was streamed
  [self streamToMicWithID:currentMic];
  
  // Remove all observers
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(checkMicroData:)
                                                name:SerialConnectionHandlerSerialResponse
                                              object:nil];
  // Add observer for audio finish
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceResponseFinished:) name:VoiceCommandResponseFinished object:nil];
}


/*
 * If a voice command was discarded, stop micro
 * Remove previous observers.
 */
- (void)voiceCommandDiscarded:(NSNotification*)notification {
  if (DEBUG_MICRO_STREAM_HANDLER) NSLog(@"Voice command discarded, stop micro");
  // Stop streaming
  [self stopMicWithID:currentMic];
  //[self stopStreaming];
  // Remove all observers
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(checkMicroData:)
                                               name:SerialConnectionHandlerSerialResponse
                                             object:nil];
}


@end
