//
//  AppDelegate.h
//  iHouse
//
//  Created by Benjamin Völker on 06/07/15.
//  Copyright © 2015 Benjamin Völker.
//  eMail:      voelkerb@me.com.
//  Company:    University of Freiburg.
//  Education:  Master of Science, Embedded Systems Engineering.
//

#import <Cocoa/Cocoa.h>
#import "House.h"
#import "SerialConnectionHandler.h"
#import "MicrophoneStreamHandler.h"
#import "TCPServer.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) SerialConnectionHandler *serialConnectionHandler;
@property (strong) MicrophoneStreamHandler *microphoneStreamHandler;
@property (strong) TCPServer *tcpServer;

@end

