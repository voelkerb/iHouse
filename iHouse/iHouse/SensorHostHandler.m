//
//  SensorHostHandler.m
//  iHouse
//
//  Created by Benjamin Völker on 16/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "SensorHostHandler.h"
#import "TCPServer.h"
#import "House.h"

#define REFRESH_INTERVAL 5

#define COMMAND_PREFIX @"/"
#define COMMAND_GET_DATA @"a"
#define COMMAND_DATA @"all;"

#define DEBUG_SENSOR_HOST_HANDLER true

// Posted when a new sensor data is available
NSString * const SensorHostHasNewData = @"SensorHostHasNewData";
NSString * const SensorHostHasNewSensor = @"SensorHostHasNewSensor";

@implementation SensorHostHandler
@synthesize tcpConnectionHandler, unboundSensors;

/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedSensorHostHandler {
  static SensorHostHandler *sharedSensorHostHandler = nil;
  @synchronized(self) {
    if (sharedSensorHostHandler == nil) {
      sharedSensorHostHandler = [[self alloc] init];
    }
  }
  return sharedSensorHostHandler;
}


/*
 * Init funciton
 */
- (id)init {
  if((self = [super init])) {
    tcpConnectionHandler = [[TCPConnectionHandler alloc] init];
    unboundSensors = [[NSMutableArray alloc] init];
  }
  return self;
}

/*
 * If a device connected successfully over TCP.
 */
-(void)deviceConnected:(GCDAsyncSocket *)sock {
  // If already connected return
  if ([tcpConnectionHandler isConnected]) return;
  tcpConnectionHandler = [[TCPConnectionHandler alloc] initWithSocket:sock];
  tcpConnectionHandler.delegate = self;
  if (DEBUG_SENSOR_HOST_HANDLER) NSLog(@"Sensor device connected");
  [self askForData];
}

/*
 * Ask the main Hub for new data.
 */
-(void)askForData {
  // If not connected return
  if (![tcpConnectionHandler isConnected]) return;
  NSString *command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, COMMAND_GET_DATA];
  [tcpConnectionHandler sendCommand:command];
  // Recall this function on every refresh interval
  [self performSelector:@selector(askForData) withObject:nil afterDelay:REFRESH_INTERVAL];
}


/*
 * If the tcp device received a command
 */
-(void)receivedCommand:(NSString *)theCommand {
  // Get the command string
  NSString *cmdPrefix = [NSString stringWithFormat:@"%@%@", COMMAND_PREFIX, COMMAND_DATA];
  if (DEBUG_SENSOR_HOST_HANDLER) NSLog(@"New Sensor String: %@", theCommand);
  // If string shorter than command or not beginning with the command prefix return
  if ([theCommand length] < [cmdPrefix length]) return;
  if (![[theCommand substringToIndex:[cmdPrefix length]] containsString:cmdPrefix]) return;
  
  // Post notification that new data is available
  [[NSNotificationCenter defaultCenter] postNotificationName:SensorHostHasNewData object:theCommand];
  
  // Get the id of the sensor
  NSString *idPrefix = [theCommand substringFromIndex:([theCommand rangeOfString:COMMAND_DATA].location + [COMMAND_DATA length])];
  NSInteger theID = [idPrefix intValue];
  
  // Look if the id from the sensor is already bound to a sensor IDevice
  BOOL isBound = false;
  House *theHouse = [House sharedHouse];
  for (Room *theRoom in [theHouse rooms]) {
    for (IDevice *theDevice in [theRoom devices]) {
      if (theDevice.type == sensor) {
        if ([(Sensor*)[theDevice theDevice] sensorID] == theID) isBound = true;
      }
    }
  }
  // If it is not bound yet, store it in a list of unbound sensors if not already exist in there
  if (!isBound) {
    BOOL exists = false;
    for (NSNumber *num in unboundSensors) {
      if ([num integerValue] == theID) {
        exists = true;
      }
    }
    // Item with Id does not exist yet
    if (!exists) {
      [unboundSensors addObject:[NSNumber numberWithInteger:theID]];
      // Post notification for new sensor available
      [[NSNotificationCenter defaultCenter] postNotificationName:SensorHostHasNewSensor object:theCommand];
    }
  }
}

/*
 * Send data to the socket client, called from delegate.
 */
- (BOOL)sendCommand:(NSString*) theCommand {
  return [tcpConnectionHandler sendCommand:theCommand];
}

/*
 * Send data to the socket client, called from delegate.
 */
- (BOOL)sendData:(NSData*) theData {
  return [tcpConnectionHandler sendData:theData];
}


/*
 * Returns if connected.
 */
-(BOOL)isConnected {
  return [tcpConnectionHandler isConnected];
}

/*
 * To make the socket free if all sensor devices are deleted
 */
- (void)freeSocket {
  // If only one sensor is left and this sensors called freeSocket, than no more sensor
  // will be left, and the tcp device needs to be freed
  int sensorsLeft = 0;
  House *theHouse = [House sharedHouse];
  for (Room *theRoom in [theHouse rooms]) {
    for (IDevice *theDevice in [theRoom devices]) {
      if (theDevice.type == sensor) sensorsLeft++;
    }
  }
  if (sensorsLeft > 1) return;
  // Free the socket again
  if (DEBUG_SENSOR_HOST_HANDLER) NSLog(@"Free socket of sensor");
  if (!tcpConnectionHandler.socket) return;
  TCPServer *tcpServer = [TCPServer sharedTCPServer];
  [tcpServer freeSocket:tcpConnectionHandler.socket];
}

@end
