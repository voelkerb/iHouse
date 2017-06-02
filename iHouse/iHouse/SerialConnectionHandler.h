//
//  SerialConnectionHandler.h
//  iHouse
//
//  Created by Benjamin Völker on 06/07/15.
//  Copyright © 2015 Benjamin Völker.
//  eMail:      voelkerb@me.com.
//  Company:    University of Freiburg.
//  Education:  Master of Science, Embedded Systems Engineering.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "ORSSerialPort.h"
#import "ORSSerialPortManager.h"
#import "Settings.h"
#define ENABLE_USB_AUDIO 0

// Posted when a new command should be send over serial
extern NSString * const SerialConnectionHandlerSerialCommand;
// Called when a new command was received over serial
extern NSString * const SerialConnectionHandlerSerialResponse;
// Coding for the command dictionary
extern NSString * const SerialConnectionHandlerCommand;
extern NSString * const SerialConnectionHandlerData;

@interface SerialConnectionHandler : NSObject <ORSSerialPortDelegate, NSUserNotificationCenterDelegate> {
@private
  // Buffer object holding the received data
  NSString *buffer;
  // If the handler is currently discovering serialports for a valid iHouse device
  BOOL discoveringSerialPorts;
}

// A Serialport Manager together with the port
@property (nonatomic, strong) ORSSerialPortManager *serialPortManager;
@property (nonatomic, strong) ORSSerialPort *serialPort;
// The baudrate and portName of the serialPort
@property int baudrate;
@property (nonatomic, strong) NSString *portName;

// This class is singletone
+ (id)sharedSerialConnectionHandler;

// Open a specific port with the given baudrate
- (BOOL) openPort:(int)theBaudrate :(NSString *)thePortName;
// Close the port
- (void) closePort;
// Returns true if the serialport is opened
- (BOOL) serialPortIsOpen;
// Sends data with prefix
- (BOOL) sendDataWithPrefix:(NSData*) theData;
// Sends a string with prefix
- (BOOL) sendStringWithPrefix:(NSString*) theString;
// Sends a string without prefix
- (BOOL) sendString:(NSString*) theString;
// Sends one single byte without prefix
- (BOOL) sendByte:(int) integer;
// Sends one single byte with a prefix
- (BOOL) sendByteWithPrefix:(int) integer;
// Sends a complete command consisting of commandstring and data as data with prefix
- (BOOL) sendSerialCommand:(NSDictionary*) theDataAsDict;

@end
