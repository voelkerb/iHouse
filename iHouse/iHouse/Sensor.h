//
//  Sensor.h
//  iHouse
//
//  Created by Benjamin Völker on 16/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SensorHostHandler.h"
#import "GCDAsyncSocket.h"

// Movement key for dictionary
extern NSString * const SensorKeyMovement;
// Humidity key for dictionary
extern NSString * const SensorKeyHumidity;
// Temperature key for dictionary
extern NSString * const SensorKeyTemperature;
// Pressure key for dictionary
extern NSString * const SensorKeyPressure;
// Brightnes key for dictionary
extern NSString * const SensorKeyBrightness;
// TimeStamp key for dictionary
extern NSString * const SensorKeyTimeStamp;
// If new data was stored, a notification is spread
extern NSString * const SensorHasNewData;

@interface Sensor : NSObject


// The different possible time intervals
typedef NS_ENUM(NSUInteger, SensorTimeInterval) {
  sensor_month,
  sensor_week,
  sensor_day,
  sensor_hour,
  sensor_minute
};

// The meter time interval (see enums from above)
@property SensorTimeInterval timeInterval;

// A handler for the sensor host
@property SensorHostHandler* sensorHostHandler;

// The ID of the meter device
@property NSInteger sensorID;

// The stored data for the different time intervals (bound by MAX value)
@property NSMutableArray *storedDataMonth;
@property NSMutableArray *storedDataDayWeek;
@property NSMutableArray *storedDataHourMinute;

// The host ip adress of the display
@property NSString *host;

// If the display device connected successfully
- (void)deviceConnected:(GCDAsyncSocket *)sock;

// Learn a new freetec device
- (void)addDataPoint:(NSString*)dataAsString;

// Get the time date and the data of a given type
- (NSArray*)getTimeData:(SensorTimeInterval)timeInterval;
- (NSArray*)getData:(SensorTimeInterval)timeInterval :(NSString*)dataType;

// Get the current time interval
- (NSTimeInterval)getTimeInterval:(SensorTimeInterval)theTimeInterval;
- (NSTimeInterval)getTimeIntervalForPlot:(SensorTimeInterval)theTimeInterval;
// Return the name of the time interval
- (NSString*)timeIntervalToString:(SensorTimeInterval)theTimeInterval;

// Return if device is connected over serial
- (BOOL)isConnected;

// Get the discovering response of displays
- (NSString*)discoverCommandResponse;
- (void) freeSocket;

// Respond to detected voice commands
- (NSDictionary*)respondToCommand:(NSString*) command;

// Return the standard voice commands
- (NSArray*)standardVoiceCommands;
// Return the available selectors for voice commands
- (NSArray*)selectors;
// Return the available voice actions
- (NSArray*)readableSelectors;
@end
