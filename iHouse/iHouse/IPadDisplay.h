//
//  TV.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "TCPConnectionHandler.h"

@interface IPadDisplay : NSObject <NSCoding, TCPConnectionHandlerDelegate>

// The host ip adress of the hoover
@property NSString *host;

// A connection handler object for the tcp connection
@property (strong) TCPConnectionHandler *tcpConnectionHandler;
// If the ipad display can autosync itself
@property BOOL autoSync;


// Let the remote show some identifying things
- (void)identify;

// If the device is connected
- (BOOL)isConnected;

// If the device connected successfully
- (void)deviceConnected:(GCDAsyncSocket *)sock;

// Get the discovering response
- (NSString*)discoverCommandResponse;
- (void) freeSocket;


@end
