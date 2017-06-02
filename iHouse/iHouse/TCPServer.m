//
//  TCPConnectionHandler.m
//  iHouse
//
//  Created by Benjamin Völker on 07/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "TCPServer.h"
#import "House.h"
#import "RemoteApp.h"

#define DEBUG_TCP 1
#define DEBUG_DISCOVER 1
#define DISCOVERING_COMMAND @"?\n"

NSString * const TCPServerNewSocketDiscovered = @"TCPServerNewSocketDiscovered";

@implementation TCPServer
@synthesize unboundSockets, bonjour;

/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedTCPServer {
  static TCPServer *sharedTCPServer = nil;
  @synchronized(self) {
    if (sharedTCPServer == nil) {
      sharedTCPServer = [[self alloc] init];
    }
  }
  return sharedTCPServer;
}


/*
 * Init funciton
 */
- (id)init {
  if((self = [super init])) {
    socketQueue = dispatch_queue_create("socketQueue", NULL);
    listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
    started = false;
    // Setup an array to store all accepted client connections
    connectedSockets = [[NSMutableArray alloc] init];
    connectedRemotes = [[NSMutableArray alloc] init];
    unboundSockets = [[NSMutableArray alloc] init];
    discovering = false;
    expectedReceiveCommand = @"";
    // Start broadcast service
    bonjour = [[BonjourServer alloc] init];
    //bonjour.delegate = self;
    [bonjour startServer];
  }
  return self;
}


/*
 * Start or stop the tcp server
 */
- (BOOL)startServer {
  if(started) {
    if (DEBUG_TCP) NSLog(@"Was running already");
    return true;
  }
  Settings *settings = [Settings sharedSettings];
  // Get desired port
  NSInteger port = [settings tcpPort];
  // if port is beyond bounds return
  if (port < 0 || port > 65535) {
    if (DEBUG_TCP) NSLog(@"Port beyond tcp-port bounds");
    return false;
  }
  // Try to open port
  NSError *error = nil;
  if(![listenSocket acceptOnPort:port error:&error]) {
    // If open fails
    if (DEBUG_TCP) NSLog(@"Error starting server: %@", error);
    return false;
  }
  // If open succeeded
  if (DEBUG_TCP) NSLog(@"TCP server started on local port %hu", [listenSocket localPort]);
  started = true;
  return true;
}

- (void)stopServer {
  // Stop accepting connections
  [listenSocket disconnect];
  // Stop any client connections
  NSUInteger i;
  for (i = 0; i < [connectedSockets count]; i++) {
    @synchronized(connectedSockets){
      [[connectedSockets objectAtIndex:i] disconnect];
    }
  }
  if (DEBUG_TCP) NSLog(@"Stopped server");
  started = false;
}

/*
 * Returns if the tcp server is running
 */
- (BOOL)isRunning {
  return [listenSocket isConnected];
}


/*
 * If a device was deletet the socket need to be freed
 */
-(void)freeSocket:(GCDAsyncSocket *)theSocket {
  if (![unboundSockets containsObject:theSocket])[unboundSockets addObject:theSocket];
}


/*
 * Return a socket with the given hostname if exist
 */
-(GCDAsyncSocket *)getSocketWithHost:(NSString *)theHost {
  for (GCDAsyncSocket *theSocket in connectedSockets) {
    if ([[theSocket connectedHost] isEqualToString:theHost]) {
      // Look if the socket is unbound and remove it from the list
      if ([unboundSockets containsObject:theSocket])[unboundSockets removeObject:theSocket];
      return theSocket;
    }
  }
  return nil;
}


/*
 * Searching for sockets that return the expected command on request.
 */
-(void)discoverSockets:(NSString *)theExpectedReceiveCommand {
  // Get the expected receive command
  if (DEBUG_DISCOVER) NSLog(@"Start discovering with response: %@", theExpectedReceiveCommand);
  expectedReceiveCommand = theExpectedReceiveCommand;
  // Enable global discovering
  if (DEBUG_DISCOVER) NSLog(@"Unbound devices a.t.m.: %@", unboundSockets);
  discovering = true;
  
  // Send discovering command to all yet unbound sockets
  for (GCDAsyncSocket *theSocket in unboundSockets) {
    // The delegate for receive must be this class
    theSocket.delegate = self;
    if (DEBUG_DISCOVER) NSLog(@"Sending: %@ to %@", DISCOVERING_COMMAND, [theSocket connectedHost]);
    NSData *data = [DISCOVERING_COMMAND dataUsingEncoding:NSUTF8StringEncoding];
    [theSocket writeData:data withTimeout:-1 tag:0];
    // Let the socket be able to write data to us
    [theSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
  }
}

/*
 * Stops discovering of sockets.
 */
-(void)stopDiscovering {
  discovering = false;
}

#pragma mark Socket delegate functions
/*
 * If a new client is connected to the server.
 */
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
  // This method is executed on the socketQueue (not the main thread)
  @synchronized(connectedSockets) {
    [connectedSockets addObject:newSocket];
  }
  
  // Get ip and port
  NSString *host = [newSocket connectedHost];
  UInt16 port = [newSocket connectedPort];
  dispatch_async(dispatch_get_main_queue(), ^{
    @autoreleasepool {
      if (DEBUG_TCP) NSLog(@"Accepted client %@:%hu", host, port);
      BOOL isUnbound = true;
      // Look if device with this host exist
      House *theHouse = [House sharedHouse];
      for (Room *theRoom in [theHouse rooms]) {
        for (IDevice *theIDevice in [theRoom devices]) {
          if ([[theIDevice theDevice] respondsToSelector:@selector(host)]) {
            SEL selector = NSSelectorFromString(@"host");
            //NSString *deviceHost = [[theIDevice theDevice] performSelector:selector withObject:nil];
            NSString *deviceHost = ((NSString* (*)(id, SEL))[[theIDevice theDevice] methodForSelector:selector])([theIDevice theDevice], selector);
            // If the host exist pass the socket to the device and inform the device that its socket
            // connected successfully
            if ([deviceHost isEqualToString:host]) {
              // So the socket is bound
              isUnbound = false;
              if (DEBUG_TCP) NSLog(@"TCP device with host: %@ connected", deviceHost);
              [[theIDevice theDevice] performSelector:@selector(deviceConnected:) withObject:newSocket];
              [self postUserNotificationForConnectedDevice:[theIDevice name] atAddress:deviceHost];
            }
          }
        }
      }
      // The socket does not belong to a device yet/Users/benny/Desktop/raspberrypi:0
      if (isUnbound) {
        // Add it to the list of unbound sockets
        [unboundSockets addObject:newSocket];
        // If we are currently discovering
        if (discovering) {
          [self postUserNotificationForConnectedDevice:@"New Device" atAddress:[newSocket connectedHost]];
          if (DEBUG_TCP) NSLog(@"New Socket for discovering connected: %@", [newSocket connectedHost]);
          // Send the discovering command after some delay to the sockets
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*1),
                         dispatch_get_current_queue(), ^(void){
                           newSocket.delegate = self;
                           if (DEBUG_TCP) NSLog(@"Sending %@ to: %@", DISCOVERING_COMMAND, [newSocket connectedHost]);
                           NSData *data = [DISCOVERING_COMMAND dataUsingEncoding:NSUTF8StringEncoding];
                           [newSocket writeData:data withTimeout:-1 tag:0];
                           // Let the socket be able to write data to us
                           [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
                         });
        }
      }
    }
  });
  
  // Let the socket be able to write data to us
  [newSocket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
  //[newSocket readDataToData:[GCDAsyncSocket CRData] withTimeout:-1 tag:0];
}

/*
 * If the socket did write data successfully, allow that data could be read again
 */
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
  // This method is executed on the socketQueue (not the main thread)
  [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
  if (DEBUG_DISCOVER) NSLog(@"Socket did write sth strange");
}

/*
 * Is called if data from a socket is read
 */
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
  // This method is executed on the socketQueue (not the main thread)
  dispatch_async(dispatch_get_main_queue(), ^{
    @autoreleasepool {
      NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
      NSString *msg = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
      if (DEBUG_DISCOVER) NSLog(@"Heurika: %@", msg);
      
      if (msg) {
        // If it is an ios remote
        if ([msg isEqualToString:REMOTE_DISCOVER_COMMAND_RESPONSE]) {
          RemoteApp *remote = [[RemoteApp alloc] init];
          [unboundSockets removeObject:sock];
          [remote deviceConnected:sock];
          [connectedRemotes addObject:remote];
          [self postUserNotificationForConnectedDevice:@"Remote" atAddress:sock.connectedHost];
        }
        
        if ([msg containsString:expectedReceiveCommand]) {
          if (DEBUG_DISCOVER) NSLog(@"Heurika: %@", msg);
          // If currently discovering and discovering command was recognized, post notification for new discovered socket with its name
          if (discovering) [[NSNotificationCenter defaultCenter] postNotificationName:TCPServerNewSocketDiscovered object:[sock connectedHost]];
        } else {
          if (DEBUG_DISCOVER) NSLog(@"Received %@ while discovering", msg);
        }
      } else {
        if (DEBUG_TCP) NSLog(@"Error converting received data into UTF-8 String");
      }
    }
  });
  // Allow new data comming in
  [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
}

/**
 * This method is called if a read has timed out.
 * It allows us to optionally extend the timeout.
 * We use this method to issue a warning to the user prior to disconnecting them.
 **//*
     - (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
     elapsed:(NSTimeInterval)elapsed
     bytesDone:(NSUInteger)length {
     if (elapsed <= READ_TIMEOUT) {
     NSString *warningMsg = @"Are you still there?\r\n";
     NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
     
     [sock writeData:warningData withTimeout:-1 tag:WARNING_MSG];
     
     return READ_TIMEOUT_EXTENSION;
     }
     
     return 0.0;
     }*/

/*
 * If a socket disconnected, remove it from the list of sockets
 */
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
  // If the socket is not equal to the listening sockets
  if (sock != listenSocket) {
    dispatch_async(dispatch_get_main_queue(), ^{
      @autoreleasepool {
        if (DEBUG_TCP) NSLog(@"Client Disconnected");
      }
    });
    // Remove from the list of sockets
    @synchronized(connectedSockets) {
      [connectedSockets removeObject:sock];
      [unboundSockets removeObject:sock];
    }
  }
}

/*
 * Post a notification if new serialports are connected
 */
- (void)postUserNotificationForConnectedDevice:(NSString *)device atAddress:(NSString*)address {
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
  if (!NSClassFromString(@"NSUserNotificationCenter")) return;
  NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
  NSUserNotification *userNote = [[NSUserNotification alloc] init];
  userNote.title = NSLocalizedString(@"Device Connected", @"Device Connected");
  NSString *informativeTextFormat = NSLocalizedString(@"Device %@ with iP Address %@ was connected to iHouse.", @"Device connected user notification informative text");
  userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, device, address];
  userNote.soundName = nil;
  [unc deliverNotification:userNote];
#endif
}

@end
