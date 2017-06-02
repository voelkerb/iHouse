//
//  Heating.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "TCPConnectionHandler.h"

#define HEATING_MIN_TEMP 5
#define HEATING_MAX_TEMP 30

// If new Temp was set on the device itself
extern NSString * const HeatingTempDidChange;
extern NSString * const HeatingSelectorSetTemp;

@interface Heating : NSObject <NSCoding, TCPConnectionHandlerDelegate>

// The host ip adress of the heating
@property NSString *host;
// A connection handler object for the tcp connection
@property (strong) TCPConnectionHandler *tcpConnectionHandler;

// The currently set temperature
@property NSNumber *currentTemperature;

// Make adaptation
- (BOOL)ada;
// Make reset
- (BOOL)reset;
// Lock device
- (BOOL)lock;
// Press boost on the heating
- (BOOL)boost;
// Set temperature
- (BOOL)setTemp:(NSNumber*)temp;

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
