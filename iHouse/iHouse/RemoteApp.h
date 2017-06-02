//
//  RemoteApp.h
//  iHouse
//
//  Created by Benjamin Völker on 24/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "TCPConnectionHandler.h"

#define REMOTE_DISCOVER_COMMAND_RESPONSE @"iHouseRemote"

@interface RemoteApp : NSObject <TCPConnectionHandlerDelegate>

// The host ip adress of the hoover
@property NSString *host;

// A connection handler object for the tcp connection
@property (strong) TCPConnectionHandler *tcpConnectionHandler;


// If the device is connected
- (BOOL)isConnected;

// If the device connected successfully
- (void)deviceConnected:(GCDAsyncSocket *)sock;


@end
