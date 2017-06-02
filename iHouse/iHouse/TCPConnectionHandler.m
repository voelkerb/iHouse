//
//  TCPConnectionHandler.m
//  iHouse
//
//  Created by Benjamin Völker on 07/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "TCPConnectionHandler.h"
#define DEBUG_CONNECTION_HANDLER false

@implementation TCPConnectionHandler
@synthesize delegate, socket, isConnected;

/*
 * Init funciton
 */
- (id)initWithSocket:(GCDAsyncSocket*) theSocket {
  if((self = [super init])) {
    socket = theSocket;
    socket.delegate = self;
    isConnected = true;
  }
  return self;
}

/*
 * Init funciton
 */
- (id)init {
  if((self = [super init])) {
     isConnected = false;
  }
  return self;
}

/*
 * Send data to the socket client, called from delegate.
 */
- (BOOL)sendCommandWithNL:(NSString*) theCommand {
  // Reset delegate to us, so that multiple connectioknHandlers can be used with one socket
  socket.delegate = self;
  // If we are not connected just return
  if (!isConnected) return false;
  NSString *command = [NSString stringWithFormat:@"%@\n", theCommand];
  // Decode string into data and send it to all available socket connections
  NSData *data = [command dataUsingEncoding:NSUTF8StringEncoding];
  // Send the decoded string as data to the socket
  [socket writeData:data withTimeout:-1 tag:0];
  return true;
}

/*
 * Send data to the socket client, called from delegate.
 */
- (BOOL)sendCommand:(NSString*) theCommand {
  // Reset delegate to us, so that multiple connectioknHandlers can be used with one socket
  socket.delegate = self;
  // If we are not connected just return
  if (!isConnected) return false;
  // Decode string into data and send it to all available socket connections
  NSData *data = [theCommand dataUsingEncoding:NSUTF8StringEncoding];
  // Send the decoded string as data to the socket
  [socket writeData:data withTimeout:-1 tag:0];
  return true;
}

/*
 * Send data to the socket client, called from delegate.
 */
- (BOOL)sendData:(NSData*) theData {
  // Reset delegate to us, so that multiple connectioknHandlers can be used with one socket
  socket.delegate = self;
  // If we are not connected just return
  if (!isConnected) return false;
  // Write the data immidiately to the socket
  [socket writeData:theData withTimeout:-1 tag:0];
  return true;
}

/*
 * Is called if data from a socket is read.
 */
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
  // This method is executed on the socketQueue (not the main thread)
  dispatch_async(dispatch_get_main_queue(), ^{
    @autoreleasepool {
      NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
      NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
      if (msg) {
        if (DEBUG_CONNECTION_HANDLER) NSLog(@"Socket Data: %@", msg);
        // Let the delegate do something with the message
        [delegate receivedCommand:msg];
      } else {
        if (DEBUG_CONNECTION_HANDLER) NSLog(@"Error converting received Display data into UTF-8 String");
      }
    }
  });
  // Allow new data comming in
  [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
}


/*
 * If a socket disconnected, remove it from the list of sockets.
 */
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
  // If the socket is not equal to the listening sockets
  if (sock == socket) {
    if (DEBUG_CONNECTION_HANDLER) NSLog(@"Socket Disconnected");
    socket.delegate = nil;
    socket = nil;
    isConnected = false;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    @autoreleasepool {
      if (DEBUG_CONNECTION_HANDLER) NSLog(@"Socket Disconnected");
    }
  });
}





@end
