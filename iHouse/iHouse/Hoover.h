//
//  Hoover.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "TCPConnectionHandler.h"

#define ROOMBA_MAX_SPEED 2000

// The different possible time intervals
typedef NS_ENUM(NSUInteger, RoombaDriveMode) {
  roomba_stop,
  roomba_forward,
  roomba_backward,
  roomba_left,
  roomba_right,
  roomba_left_hard,
  roomba_right_hard
};

@interface Hoover : NSObject <NSCoding, TCPConnectionHandlerDelegate>

// The host ip adress of the hoover
@property NSString *host;
@property NSInteger speed;

// A connection handler object for the tcp connection
@property (strong) TCPConnectionHandler *tcpConnectionHandler;

// Stores the current state of the hoover
@property BOOL isCleaning;

// Simulates a start cleaning press on the roomba
- (BOOL)startCleaning;
// Simulates a stop cleaning press on the roomba
- (BOOL)stopCleaning;
// Simulates a comeToDock press on the roomba
- (BOOL)comeToDock;
// Identifies roomba by blinking LED
- (BOOL)identify;
// Simulates a comeToDock press on the roomba
- (BOOL)drive:(RoombaDriveMode)mode : (NSInteger)theSpeed;

// If the device is connected
- (BOOL)isConnected;

// If the device connected successfully
- (void)deviceConnected:(GCDAsyncSocket *)sock;

// Get the discovering response
- (NSString*)discoverCommandResponse;
- (void) freeSocket;

// Return the standard voice commands
- (NSArray*)standardVoiceCommands;
// Return the available selectors for voice commands
- (NSArray*)selectors;
// Return the available voice actions
- (NSArray*)readableSelectors;
@end
