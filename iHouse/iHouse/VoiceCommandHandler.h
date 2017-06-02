//
//  VoiceCommandHandler.h
//  iHouse
//
//  Created by Benjamin Völker on 09/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "House.h"

// The Functions the delegate has to implement
@protocol VoiceCommandHandlerDelegate <NSObject>

// The delegate needs to display the response text
- (void) willSpeakResponse:(NSString*)response;

// The delegate needs to do after successfull command
- (void) finishSpeakResponse;

// The delegate needs to display a response view
- (void) displayResponseView:(NSView*)responseView;

// The delegate needs to display a response view with controller
- (void) displayResponseViewWithController:(NSViewController*)responseViewController;

// The delegate needs to display a recognized command
- (void) didRecognizeCommand:(NSString *)command;

// The delegate is informed that no command was recognized
- (void) noCommandRecognized;

// The delegate is informed that a command is recognized that needs further commands
- (void) commandNeedsFurtherCommands;

@end


@interface VoiceCommandHandler : NSObject<NSSpeechRecognizerDelegate> {
  // The speech recognizer object
  NSSpeechRecognizer *speechRecog;
  // The speech synthesizer object
  NSSpeechSynthesizer *speechSynth;
  // The audio player, to play .wav files
  AVAudioPlayer* audioPlayer;
  // If speech was recognized other sounds need to be played
  BOOL speechWasRecognized;
  // If (any) sound is currently playing
  BOOL soundIsPlaying;
  // The Room from which we are listening
  Room* listeningRoom;
}

// The delegate variable
@property (weak) id<VoiceCommandHandlerDelegate> delegate;

// The Recognition process is startet forever or for a defined time
-(void)startListening:(BOOL)withDiscard;

// The Recognition process is startet forever or for a defined time
-(void)startListeningInRoom:(Room*)theRoom withDiscard:(BOOL)withDiscard;

// The Recognition process is forced to stop
-(void)forceStopListening;


@end
