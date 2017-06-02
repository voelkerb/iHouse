//
//  Socket.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SerialConnectionHandler.h"

// Posted when a sniff exited succesfully
extern NSString * const SocketSniffedSuccessfully;
extern NSString * const SocketSwitched;

@interface Socket : NSObject <NSCoding>

// The different possible devices as an ENUM
typedef NS_ENUM(NSUInteger, SocketType) {
  freeTec_socket,
  cmi_socket,
  conrad_socket
};


// The socket type (see enums from above)
@property SocketType type;

// The connection handler object
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
@property (nonatomic) BOOL state;

// Return if device is connected over serial
- (BOOL)isConnected;
// Learn a new freetec device
- (void)learnFreetec;
// Learn a new CMI device
- (void)sniffCMI;
// If sniffing was dismissed
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
