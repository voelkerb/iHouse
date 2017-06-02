//
//  Microphone.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "TCPConnectionHandler.h"
#import "MicrophoneStreamHandler.h"

@interface Microphone : NSObject <NSCoding>

// The different possible errors as an ENUM
typedef NS_ENUM(NSUInteger, MicrophoneState) {
  micro_idle,
  micro_transmittingMic,
  micro_receivingAudio
};

// The state of this microphone
@property MicrophoneState state;

@property MicrophoneStreamHandler *microphoneStreamHandler;

// The host ip adress of the display
@property NSInteger micID;

// If the micro is connected
- (BOOL)isConnected;

// Turn audio on/off
- (BOOL) audioOn;
- (BOOL) audioOff;

@end
