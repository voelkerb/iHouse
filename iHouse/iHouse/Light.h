//
//  Light.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SerialConnectionHandler.h"
#import "VoiceCommand.h"


// Posted when a sniff exited succesfully
extern NSString * const LightSniffedSuccessfully;
extern NSString * const LightSwitched;

@interface Light : NSObject <NSCoding>

// The different possible devices as an ENUM
typedef NS_ENUM(NSUInteger, LightType) {
  freeTec_light,
  cmi_light,
  conrad_light
};


// The socket type (see enums from above)
@property LightType type;

@property (strong) SerialConnectionHandler *connectionHandler;

// The group and number if conrad socket
@property NSInteger conradGroup;
@property NSInteger conradNumber;

// The CMI tristate code
@property NSString *cmiTristate;

// The Freetec tristate code
@property NSInteger freetecCode1;
@property NSInteger freetecCode2;
@property NSInteger freetecCode3;

// The current state
@property BOOL state;

// Return if device is connected over serial
- (BOOL)isConnected;
// Learn a new freetec device
- (void)learnFreetec;
// Learn a new CMI device
- (void)sniffCMI;
- (void)sniffCMIDismissed;
// Send toggle command
- (BOOL)toggle:(BOOL) theState;

// Return the standard voice commands
- (NSArray*)standardVoiceCommands;
// Return the available selectors for voice commands
- (NSArray*)selectors;
// Return the available voice actions
- (NSArray*)readableSelectors;

@end