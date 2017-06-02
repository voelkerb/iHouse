//
//  InfraredDevice.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "TCPConnectionHandler.h"
#import "InfraredCommand.h"

extern NSString * const IRDeviceCountChanged;
extern NSString * const IRDeviceSelectorToggle;

@interface InfraredDevice : NSObject <NSCoding, TCPConnectionHandlerDelegate, InfraredCommandDelegate> {
  // the new learning command
  InfraredCommand *learnCommand;
  // If we are currently learning a ir command
  BOOL learning;
}

// The host ip adress of the hoover
@property NSString *host;

// A connection handler object for the tcp connection
@property (strong) TCPConnectionHandler *tcpConnectionHandler;

// An array holding the infrared commands
@property (strong) NSMutableArray *infraredCommands;

// Add an infrared command to the device
- (void)addIRCommand:(InfraredCommand*)theInfraredCommand;

// Remove an infrared command of the device
- (void)removeIRCommand:(InfraredCommand*)theInfraredCommand;

// Toggle IR command
- (BOOL)toggleIRCommand:(InfraredCommand*)theInfraredCommand;

// Learn IR command
- (BOOL)learnIRCommand:(InfraredCommand*)theInfraredCommand;

// Identify the box with blinking LED
- (BOOL)identify;

// If the device is connected
- (BOOL)isConnected;

// If the device connected successfully
- (void)deviceConnected:(GCDAsyncSocket *)sock;

// Get the discovering response
- (NSString*)discoverCommandResponse;
// Free the socket if the device gets deleted
- (void) freeSocket;

// Return the available selectors for voice commands
- (NSArray*)selectors;
// Return the available voice actions
- (NSArray*)readableSelectors;


@end
