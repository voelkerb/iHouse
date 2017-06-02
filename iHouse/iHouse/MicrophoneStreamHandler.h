//
//  MicrophoneStreamHandler.h
//  iHouse
//
//  Created by Benjamin Völker on 11/09/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SerialConnectionHandler.h"

@interface MicrophoneStreamHandler : NSObject {
  NSInteger currentMic;
}

// The different possible errors as an ENUM
typedef NS_ENUM(NSUInteger, AudioStreamState) {
  audioStream_idle,
  audioStream_transmittingAudio,
  audioStream_receivingAudio
};

@property AudioStreamState state;

// The connection handler object
@property (strong) SerialConnectionHandler *connectionHandler;

// This class is singletone
+ (id)sharedMicrophoneStreamHandler;

// Stream to given mic or to all (micID = 0)
- (BOOL)streamToMicWithID:(NSInteger)micID;

// Strop streaming to any mic.
- (BOOL)stopStreaming;

@end
