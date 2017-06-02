//
//  Display.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "Display.h"
#import "TCPServer.h"

#define DEBUG_DISPLAY false

#define DISCOVER_COMMAND_RESPONSE @"iHouseDisplay"
#define COMMAND_PREFIX @"/"
#define COMMAND_SEPERATOR @","
#define COMMAND_RESET @"0"
#define COMMAND_TEXT @"1"
#define COMMAND_WARNING @"2"
#define COMMAND_IMAGE @"3"
#define COMMAND_BEEP @"4"
#define DISPLAY_TYPE_NAME @"Display"

@implementation Display
@synthesize host;
@synthesize tcpConnectionHandler;

- (id)init {
  self = [super init];
  if (self) {
    // Init stuff goes here
    host = @"";//@"192.168.178.21"; //@"";
    [self codingIndependentInits];
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  // Coding stuff goes here
  [encoder encodeObject:self.host forKey:@"host"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    // decoding stuff goes here
    self.host = [decoder decodeObjectForKey:@"host"];
    [self codingIndependentInits];
  }
  return self;
}

// Inits that must be done either if this object is newly inited or inted from file
- (void)codingIndependentInits {
  tcpConnectionHandler = [[TCPConnectionHandler alloc] init];
  tcpConnectionHandler.delegate = self;
}

/*
 * If the device connected successfully.
 */
-(void)deviceConnected:(GCDAsyncSocket *)sock {
  tcpConnectionHandler = [[TCPConnectionHandler alloc] initWithSocket:sock];
  tcpConnectionHandler.delegate = self;
}

/*
 * Returns if the Coffe mashine is connected over tcp or not.
 */
- (BOOL)isConnected {
  return [tcpConnectionHandler isConnected];
}

/*
 * If the display sent a command to us.
 */
-(void)receivedCommand:(NSString *)theCommand {
  NSLog(@"Received Display Command: %@", theCommand);
}

/*
 * To play a beep sound on the display.
 */
- (BOOL)beep {
  NSString *command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_BEEP];
  return [tcpConnectionHandler sendCommand:command];
}

/*
 * To reset the display to a given background color.
 */
- (BOOL)reset:(DisplayColor)theColor {
  NSString *command = [NSString stringWithFormat:@"%@%@%@%li\n", COMMAND_PREFIX, COMMAND_RESET, COMMAND_SEPERATOR, theColor];
  return [tcpConnectionHandler sendCommand:command];
}

/*
 * To set a warning message.
 */
- (BOOL)setWarning:(NSString *)theWarning {
  NSString *command = [NSString stringWithFormat:@"%@%@%@%@\n", COMMAND_PREFIX, COMMAND_WARNING, COMMAND_SEPERATOR, theWarning];
  return [tcpConnectionHandler sendCommand:command];
}

/*
 * To set an image with the given name + ending on the display.
 */
- (BOOL)setImageNamed:(NSString *)theImageName {
  NSString *command = [NSString stringWithFormat:@"%@%@%@%i%@%i%@%@\n", COMMAND_PREFIX, COMMAND_IMAGE, COMMAND_SEPERATOR,
                       0, COMMAND_SEPERATOR, 0, COMMAND_SEPERATOR, theImageName];
  return [tcpConnectionHandler sendCommand:command];
}

/*
 * To set the headline on the display in a given color.
 */
- (BOOL)setHeadline:(NSString *)theHeadline :(DisplayColor)theColor {
  NSString *command = [NSString stringWithFormat:@"%@%@%@%i%@%i%@%li%@%@\n", COMMAND_PREFIX, COMMAND_TEXT, COMMAND_SEPERATOR,
                       1, COMMAND_SEPERATOR, 6, COMMAND_SEPERATOR, theColor, COMMAND_SEPERATOR, theHeadline];
  return [tcpConnectionHandler sendCommand:command];
}

/*
 * Returns the discovering command response for discovering displays.
 */
-(NSString *)discoverCommandResponse {
  return DISCOVER_COMMAND_RESPONSE;
}

/*
 * the socket needs to be freed
 */
- (void) freeSocket {
  // Free the socket again
  if (DEBUG_DISPLAY) NSLog(@"Free socket of display");
  if (!tcpConnectionHandler.socket) return;
  TCPServer *tcpServer = [TCPServer sharedTCPServer];
  [tcpServer freeSocket:tcpConnectionHandler.socket];
}

@end
