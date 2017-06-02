//
//  TCPConnectionHandler.h
//  iHouse
//
//  Created by Benjamin Völker on 07/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "GCDAsyncSocket.h"

// The Functions the delegate has to implement
@protocol TCPConnectionHandlerDelegate <NSObject>

// The delegate needs to change something
- (void)receivedCommand:(NSString*) theCommand;

@end

@interface TCPConnectionHandler : NSObject<GCDAsyncSocketDelegate> {
}

// The soocket object
@property (strong) GCDAsyncSocket *socket;

// The status of the socket, connected or not
@property BOOL isConnected;

// The delegate variable
@property (weak) id<TCPConnectionHandlerDelegate> delegate;

// Init this connectionhandler properly with a socket
- (id)initWithSocket:(GCDAsyncSocket*)theSocket;

// Sends the given data to the socket
- (BOOL)sendData:(NSData*)theData;

// Sends the given string as data to the socket
- (BOOL)sendCommandWithNL:(NSString*)theCommand;
// Sends the given string as data to the socket
- (BOOL)sendCommand:(NSString*)theCommand;

@end
