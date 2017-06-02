//
//  VoiceCommandHandler.m
//  iHouse
//
//  Created by Benjamin Völker on 09/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "VoiceCommandHandler.h"
#import "Settings.h"
#import "VoiceCommand.h"
#import "House.h"

#define DEBUG_VOICE 1

#define RESET_RECOGNIZER_OBJECT 1

// The sound file names and extension
#define SPEECH_STOP_SOUND @"SiriStop"
#define SPEECH_START_SOUND @"SiriStart"
#define SPEECH_DISCARD_SOUND @"SiriDiscard"
#define SOUND_EXTENSION @"mov"

// Delay to look if sound is playing
#define DELAY_SOUND_PLAYING 0.2
// Discard delay for speech recognition
#define DELAY_SPEECH_DISCARD 7


@implementation VoiceCommandHandler
@synthesize delegate;

-(id)init {
  if (self = [super init]) {
    // Init the Speech recognizer and the commandArray
    speechRecog = [[NSSpeechRecognizer alloc] init];
    [self initVoiceCommands];
    
    // Init the Speech Recognizer and set its delegate
    [speechRecog setListensInForegroundOnly:false];
    [speechRecog setDelegate:self];
    [speechRecog stopListening];
    
    // Init the Speech Synthesizer with the correct voice
    [self initVoice:nil];
    
    
    // Add an observer to get notified if the voice changed or the voice commands changed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initVoice:) name:SettingsVoiceChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addVoiceCommand:) name:VoiceCommandAdded object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeVoiceCommand:) name:VoiceCommandRemoved object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initVoiceCommands) name:VoiceCommandChanged object:nil];
    
    
    // Init global variables
    speechWasRecognized = false;
    soundIsPlaying = false;
    
    // Init the listening room to any room
    listeningRoom = [[Room alloc] init];
    listeningRoom.name = VoiceCommandAnyRoom;
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
  if (DEBUG_VOICE) NSLog(@"Set voice to: %@", [settings voice]);
}


/*
 * If the speech recognizer recognized a command.
 */
-(void)speechRecognizer:(NSSpeechRecognizer *)sender didRecognizeCommand:(id)command {
  // Set the recognied variable to true, so that no discard sound is played
  speechWasRecognized = true;
  // Stop listening immediately
  [self stopListening];
  // Inform delegate for command recognize
  [delegate didRecognizeCommand:command];
  
   // Loop over all commands
  for (VoiceCommand *theVoiceCommand in [[House sharedHouse] voiceCommands]) {
    // Match the command
    if ([command isEqualToString:[theVoiceCommand command]]) {
      if (DEBUG_VOICE) NSLog(@"%@", theVoiceCommand);
      
      // The dict now holds the response for the command (views, viewController, string)
      NSDictionary *responseDict = [theVoiceCommand execute];
      NSString *response = [responseDict objectForKey:KeyVoiceCommandResponseString];
      NSString *responseSpeech = [responseDict objectForKey:KeyVoiceCommandResponseSpeechString];
      NSView *responseView = [responseDict objectForKey:KeyVoiceCommandResponseView];
      NSViewController *responseViewController = [responseDict objectForKey:KeyVoiceCommandResponseViewController];
      if (DEBUG_VOICE) NSLog(@"Command response %@", responseDict);
      
      // If the response text exist, inform delegate what will be spoken and speak the text
      if (response) {
        [delegate willSpeakResponse:response];
      }
      if (responseSpeech) {
        [self speakStringIfPossible:responseSpeech];
      } else if (response) {
        [self speakStringIfPossible:response];
      }
      // If the response view exist, inform the delegate to display it
      if (responseView) [delegate displayResponseView:responseView];
      // If the response view exist, inform the delegate to display it
      if (responseViewController) [delegate displayResponseViewWithController:responseViewController];
      
      // Post notification that voice command was succesfully detected
      [[NSNotificationCenter defaultCenter] postNotificationName:VoiceCommandDetectedSuccesfully object:nil];
      
      // TODO: maybe commands with further commands what to do there?
    }
  }
}

/*
 * Speaks a string if this is possible.
 */
- (void)speakStringIfPossible:(NSString*)theString {
  // Wait if sth is playing
  if ([speechSynth isSpeaking] || [audioPlayer isPlaying] || soundIsPlaying) {
    [self performSelector:@selector(speakStringIfPossible:) withObject:theString afterDelay:DELAY_SOUND_PLAYING];
    return;
  }
  // If nothing is playing, begin playing
  soundIsPlaying = true;
  [speechSynth startSpeakingString:theString];
  // Check playing will reset the soundIsPlaying variable
  [self performSelector:@selector(checkPlaying) withObject:nil afterDelay:DELAY_SOUND_PLAYING];
  // Inform delegate that we finished with the command
  [self performSelector:@selector(checkPlayingAndInformFinish) withObject:nil afterDelay:DELAY_SOUND_PLAYING];
}

/*
 * Checks if something is playing, if not, a bool is reseted so that the next item in the playing queue can be played
 */
-(void)checkPlayingAndInformFinish {
  if ([speechSynth isSpeaking]) {
    [self performSelector:@selector(checkPlayingAndInformFinish) withObject:nil afterDelay:DELAY_SOUND_PLAYING];
    return;
  }
  // Inform delegate that response was spoken
  [delegate finishSpeakResponse];
  // Post notification that response was spoken
  [[NSNotificationCenter defaultCenter] postNotificationName:VoiceCommandResponseFinished object:nil];
}

/*
 * Checks if something is playing, if not, a bool is reseted so that the next item in the playing queue can be played
 */
-(void)checkPlaying {
  if ([speechSynth isSpeaking] || [audioPlayer isPlaying]) {
    [self performSelector:@selector(checkPlaying) withObject:nil afterDelay:DELAY_SOUND_PLAYING];
    return;
  }
  soundIsPlaying = false;
}

/*
 * Starts the SpeechRecognizer and plays a sound showing that speech recognizer is recognizing speech now.
 * If some audio is currently playing, it waits till audio is not playing any more.
 * If called withDiscard=true the speech recognizer automatically discards after specific delay if nothing was recognized.
 */
- (void)startListening:(BOOL)withDiscard {
  // Start listening and play sound for start listening
  [self playSound:SPEECH_START_SOUND];
  
  // Start listening with or without resetting the recognizer object
  if (RESET_RECOGNIZER_OBJECT) {
    speechRecog = [[NSSpeechRecognizer alloc] init];
    [self initVoiceCommands];
  
    // Init the Speech Recognizer and set its delegate
    [speechRecog setListensInForegroundOnly:false];
  }
  [speechRecog setDelegate:self];
  [speechRecog startListening];
  
  // Reset recognized variable
  speechWasRecognized = false;
  // Play discard sound and stop listening after some time if the speech recognized variable was not set to true
  if (withDiscard) [self performSelector:@selector(discardListening) withObject:nil afterDelay:DELAY_SPEECH_DISCARD];
  // Set listening Room to any room
  listeningRoom = [[Room alloc] init];
  listeningRoom.name = VoiceCommandAnyRoom;
}

/*
 * Starts the SpeechRecognizer and plays a sound showing that speech recognizer is recognizing speech now.
 *
 */
- (void)startListeningInRoom:(Room *)theRoom withDiscard:(BOOL)withDiscard {
  [self startListening:withDiscard];
  listeningRoom = theRoom;
}

/*
 * Plays a discard listening sound and stops the speech recognizer if nothing was recognized.
 */
-(void)discardListening {
  if (speechWasRecognized) return;
  // Stop listening and play sound for discard listening
  [speechRecog stopListening];
  // Dealloc recognizer objhect if wanted
  if (RESET_RECOGNIZER_OBJECT) {
    speechRecog = nil;
  }
  [self playSound:SPEECH_DISCARD_SOUND];
  // Let delegate do something
  [delegate noCommandRecognized];
  // Post notification for unsuccessfull voice command detection
  [[NSNotificationCenter defaultCenter] postNotificationName:VoiceCommandDetectionDiscarded object:nil];
}

/*
 * Plays a stop listening sound and stops the speech recognizer.
 */
-(void)stopListening {
  // Stop listening and play sound for stop listening
  [speechRecog stopListening];
  // Dealloc recognizer objhect if wanted
  if (RESET_RECOGNIZER_OBJECT) {
    speechRecog = nil;
  }
  [self playSound:SPEECH_STOP_SOUND];
}

/*
 * Forces everything to stop.
 */
-(void) forceStopListening {
  // Remove all prending performSelectors
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  // Stop speech recognizer and synthesizer and sounds playing
  [speechRecog stopListening];
  // Dealloc recognizer objhect if wanted
  if (RESET_RECOGNIZER_OBJECT) {
    speechRecog = nil;
  }
  [speechSynth stopSpeaking];
  [audioPlayer stop];
  // Play the stop sound
  NSString* path = [[NSBundle mainBundle] pathForResource:SPEECH_DISCARD_SOUND ofType:SOUND_EXTENSION];
  NSURL* file = [NSURL fileURLWithPath:path];
  audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:file error:nil];
  [audioPlayer prepareToPlay];
  [audioPlayer play];
  // Reset global variables
  speechWasRecognized = false;
  soundIsPlaying = false;
}

/*
 * Plays a soundfile with the fiven name.
 */
-(void)playSound:(NSString*)soundName {
  // Wait if sth is currently speaking
  if ([speechSynth isSpeaking] || [audioPlayer isPlaying] || soundIsPlaying) {
    [self performSelector:@selector(playSound:) withObject:soundName afterDelay:DELAY_SOUND_PLAYING];
    return;
  }
  soundIsPlaying = true;
  NSString* path = [[NSBundle mainBundle] pathForResource:soundName ofType:SOUND_EXTENSION];
  NSURL* file = [NSURL fileURLWithPath:path];
  audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:file error:nil];
  [audioPlayer prepareToPlay];
  [audioPlayer play];
  [self performSelector:@selector(checkPlaying) withObject:nil afterDelay:DELAY_SOUND_PLAYING];
}

/*
 * Inits all voice commands
 */
-(void)initVoiceCommands {
  House* theHouse = [House sharedHouse];
  NSMutableArray *newVoiceCommands = [[NSMutableArray alloc] init];
  for (VoiceCommand* theVoiceCommand in [theHouse voiceCommands]) {
    [newVoiceCommands addObject:[theVoiceCommand command]];
  }
  [speechRecog setCommands:newVoiceCommands];
  if (DEBUG_VOICE) NSLog(@"Inited all voice Commands %@", newVoiceCommands);
}

/*
 * Add one single voice command.
 */
-(void)addVoiceCommand:(NSNotification*)notification {
  VoiceCommand *theVoiceCommand = [notification object];
  NSMutableArray *newVoiceCommands = [[NSMutableArray alloc] initWithArray:[speechRecog commands]];
  [newVoiceCommands addObject:[theVoiceCommand command]];
  [speechRecog setCommands:newVoiceCommands];
  if (DEBUG_VOICE) NSLog(@"Added voice command: %@", [theVoiceCommand command]);
}

/*
 * Remove one single voice command.
 */
-(void)removeVoiceCommand:(NSNotification*)notification {
  VoiceCommand *theVoiceCommand = [notification object];
  NSMutableArray *newVoiceCommands = [[NSMutableArray alloc] init];
  for (NSString *cmd in [speechRecog commands]) {
    if (![cmd isEqualToString:[theVoiceCommand command]]) [newVoiceCommands addObject:cmd];
  }
  [speechRecog setCommands:newVoiceCommands];
  if (DEBUG_VOICE) NSLog(@"Removed voice command: %@", [theVoiceCommand command]);
}


@end
