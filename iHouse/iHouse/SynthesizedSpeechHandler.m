//
//  SynthesizedSpeechHandler.m
//  iHouse
//
//  Created by Benjamin Völker on 05/04/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "SynthesizedSpeechHandler.h"
#import "Settings.h"


#define DEBUG_SYNTH_SPEECH_HANDLER 1
#define DELAY_CHECK_SPEAKING 0.3


// Notification for speech start and finished
NSString* const SpeechSynthesizerStartsSpeaking = @"SpeechSynthesizerStartsSpeaking";
NSString* const SpeechSynthesizerFinishedSpeaking = @"SpeechSynthesizerFinishedSpeaking";


@implementation SynthesizedSpeechHandler
@synthesize isSpeaking;

// This class is singleton, so everyone could use the speech sysnthesizer
+(id)sharedSynthesizedSpeechHandler {
  static SynthesizedSpeechHandler *sharedSynthesizedSpeechHandler = nil;
  @synchronized(self) {
    if (sharedSynthesizedSpeechHandler == nil) {
      sharedSynthesizedSpeechHandler = [[self alloc] init];
    }
  }
  return sharedSynthesizedSpeechHandler;
}

/*
 * Inits variables and setup notifications for voice type changed
 */
-(id)init {
  if (self = [super init]) {
    // Not speaking at beginning
    isSpeaking = false;
    textBuffer = [[NSMutableArray alloc] init];
    // Init the Speech Synthesizer with the correct voice
    [self initVoice:nil];
    // Add an observer to get notified if the voice changed or the voice commands changed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initVoice:) name:SettingsVoiceChanged object:nil];
  }
  return self;
}


/*
 * Sets the voice to the currently stored voice in settings.
 */
- (void)initVoice:(NSNotification*)notification {
  // Init the Speech Synthesizer with the correct voice
  Settings *settings = [Settings sharedSettings];
  speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:[NSSpeechSynthesizer defaultVoice]];
  for (NSString *voiceIdentifier in [NSSpeechSynthesizer availableVoices]) {
    if ([[[NSSpeechSynthesizer attributesForVoice:voiceIdentifier] valueForKey:NSVoiceName] isEqualToString:[settings voice]]) {
      [speechSynth setVoice:voiceIdentifier];
    }
  }
  if (DEBUG_SYNTH_SPEECH_HANDLER) NSLog(@"Set voice to: %@", [settings voice]);
}


/*
 * Adds a speech string to the play queue, will speak it if ready.
 */
-(void)speakStringIfReady:(NSString *)speechString {
  // Add the speech to the queue
  [textBuffer addObject:speechString];
  // If the speech sysnthesizer is idle atm, start speaking
  // The local variable isSpeaking is needed since, the speechSynth isSpeaking variable is not
  // set immidiately, if we now trigger this methode fast enough twice, the first call to start speaking is
  // overwritten and the text second text will be spoken twice
  if (![speechSynth isSpeaking] && !isSpeaking) {
    [speechSynth startSpeakingString:speechString];
    isSpeaking = true;
    // Trigger playqueue check again after delay, so speaking started
    [self performSelector:@selector(checkSpeakingQueue) withObject:nil afterDelay:DELAY_CHECK_SPEAKING];
    // Post notification to show that speech started
    [[NSNotificationCenter defaultCenter] postNotificationName:SpeechSynthesizerStartsSpeaking object:nil];
  }
}

/*
 * Speaks a string immidiately by discarding any ongoing speech in the queue.
 */
-(void)speakStringDiscardOther:(NSString *)speechString {
  // If the speech synth is currently speaking, stop it
  if ([speechSynth isSpeaking]) [speechSynth stopSpeaking];
  // Remove everything in the speech queue
  [textBuffer removeAllObjects];
  // Add this string to the queue and start speaking it
  [textBuffer addObject:speechString];
  [speechSynth startSpeakingString:speechString];
  isSpeaking = true;
  // Trigger playqueue check again after delay, so speaking started
  [self performSelector:@selector(checkSpeakingQueue) withObject:nil afterDelay:DELAY_CHECK_SPEAKING];
  // Post notification to show that speech started
  [[NSNotificationCenter defaultCenter] postNotificationName:SpeechSynthesizerStartsSpeaking object:nil];
}


/*
 * Checks if the speech synthesizer is currently speaking, sets the isSpeaking variable accordingly
 * and will trigger other texts to start beeing spoken if in the queue.
 */
-(void)checkSpeakingQueue {
  // If the speech synthesizer is speaking, recall this method immidiately
  if ([speechSynth isSpeaking]) {
    isSpeaking = true;
    [self performSelector:@selector(checkSpeakingQueue) withObject:nil afterDelay:DELAY_CHECK_SPEAKING];
    return;
  }
  // If there is sth in the text buffer, remove it since it was already spoken
  if ([textBuffer count]) {
    [textBuffer removeObjectAtIndex:0];
  }
  // If there is now again sth in the buffer, we need to trigger speaking this
  if ([textBuffer count]) {
    [speechSynth startSpeakingString:[textBuffer firstObject]];
    isSpeaking = true;
  } else {
    // Set variable to idle
    isSpeaking = false;
    // Post notification that we finished speaking
    [[NSNotificationCenter defaultCenter] postNotificationName:SpeechSynthesizerFinishedSpeaking object:nil];
    [self performSelector:@selector(checkSpeakingQueue) withObject:nil afterDelay:DELAY_CHECK_SPEAKING];
  }
}

@end
