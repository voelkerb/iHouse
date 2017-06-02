//
//  SynthesizedSpeechHandler.h
//  iHouse
//
//  Created by Benjamin Völker on 05/04/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>


// Notification for speech start and finished
extern NSString* const SpeechSynthesizerStartsSpeaking;
extern NSString* const SpeechSynthesizerFinishedSpeaking;

@interface SynthesizedSpeechHandler : NSObject {
  // The speech synthesizer object
  NSSpeechSynthesizer *speechSynth;
  // A text buffer in which the text to speech is inserted
  NSMutableArray *textBuffer;
}

@property (readonly) BOOL isSpeaking;

+ (id)sharedSynthesizedSpeechHandler;

- (void)speakStringDiscardOther:(NSString*)speechString;
- (void)speakStringIfReady:(NSString*)speechString;

@end
