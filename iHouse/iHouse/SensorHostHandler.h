//
//  SensorHostHandler.h
//  iHouse
//
//  Created by Benjamin Völker on 16/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "TCPConnectionHandler.h"

// Posted when new sensor data is available
extern NSString * const SensorHostHasNewData;
extern NSString * const SensorHostHasNewSensor;

@interface SensorHostHandler : NSObject<TCPConnectionHandlerDelegate> {
}

// A connection handler object for the tcp connection
@property (strong) TCPConnectionHandler *tcpConnectionHandler;
@property (strong) NSMutableArray *unboundSensors;

// This class is singletone
+ (id)sharedSensorHostHandler;

// If the sensor device connected successfully
- (void)deviceConnected:(GCDAsyncSocket *)sock;

// Send command
- (BOOL)sendCommand:(NSString*)theCommand;
- (BOOL)sendData:(NSData*)theData;

// Retunrs if the device is connected
- (BOOL)isConnected;

// Free Socket if needed
- (void)freeSocket;

@end
