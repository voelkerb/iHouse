//
//  AVBufferdPlayer.h
//  SpeechRecognitionWithAudioQueue
//
//  Created by Benjamin Völker on 15/12/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>


@interface AVBufferedPlayer : NSObject<AVAudioPlayerDelegate>{
  // Tone unit object where output is created
  AudioComponentInstance toneUnit;
  
@public
  // Members for size of buffer and sampling rate
  NSInteger blockSize;
  NSInteger samplingRate;
}

// This class is singletone
+ (id)sharedAVBufferedPlayer;

/*
 * Init with a given sampling rate and blocksize.
 */
-(id)initWithSamplingRate:(NSInteger)sr andBlockSize:(NSInteger)bs;

/*
 * Plays the sound.
 */
- (void)play;

/*
 * Stops the sound.
 */
- (void)stop;


/*
 * Adding PCM Samples to the Queue
 */
- (void)addToQueue:(float*)samples :(int)size;

@end
