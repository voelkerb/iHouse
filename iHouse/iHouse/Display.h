//
//  Display.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "TCPConnectionHandler.h"

@interface Display : NSObject <NSCoding, TCPConnectionHandlerDelegate>

// The different possible colors as an ENUM
typedef NS_ENUM(NSUInteger, DisplayColor) {
  display_black,
  display_blue,
  display_green,
  display_yellow,
  display_red,
  display_white
};

// The host ip adress of the display
@property NSString *host;
// A connection handler object for the tcp connection
@property (strong) TCPConnectionHandler *tcpConnectionHandler;
// Return if device is connected over tcp
- (BOOL)isConnected;
// If the display device connected successfully
- (void)deviceConnected:(GCDAsyncSocket *)sock;
// To play a beep sound
- (BOOL)beep;
// To reset the display with a given background color
- (BOOL)reset :(DisplayColor)theColor;
// To set a warning message
- (BOOL)setWarning:(NSString*)theWarning;
// To set a headline on the display
- (BOOL)setHeadline:(NSString*)theHeadline :(DisplayColor)theColor;
// To set an image stored on the displays sd card
- (BOOL)setImageNamed:(NSString*)theImageName;

// Get the discovering response of displays
- (NSString*)discoverCommandResponse;
- (void) freeSocket;
@end
