//
//  Meter.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SerialConnectionHandler.h"
#import <CorePlot/CorePlot.h>

// Voltage key for dictionary
extern NSString * const MeterKeyVoltage;
// Current key for dictionary
extern NSString * const MeterKeyCurrent;
// Power key for dictionary
extern NSString * const MeterKeyPower;
// Enegery key for dictionary
extern NSString * const MeterKeyEnergy;
// TimeStamp key for dictionary
extern NSString * const MeterKeyTimeStamp;
// If new data was stored, a notification is spread
extern NSString * const MeterHasNewData;

@interface Meter : NSObject <NSCoding>

// The different possible devices as an ENUM
typedef NS_ENUM(NSUInteger, MeterType) {
  EMT7110
};

// The different possible time intervals
typedef NS_ENUM(NSUInteger, MeterTimeInterval) {
  meter_month,
  meter_week,
  meter_day,
  meter_hour,
  meter_minute
};

// The meter type (see enums from above)
@property MeterType type;

// The meter time interval (see enums from above)
@property MeterTimeInterval timeInterval;

// The connection handler object
@property (strong) SerialConnectionHandler *connectionHandler;

// The ID of the meter device
@property NSInteger meterID;

// The stored data for the different time intervals (bound by MAX value)
@property NSMutableArray *storedDataMonth;
@property NSMutableArray *storedDataDayWeek;
@property NSMutableArray *storedDataHourMinute;

// Adding a new datapoint
- (void)addDataPoint:(NSString*)dataAsString;

// Get the time date and the data of a given type
- (NSArray*)getTimeData:(MeterTimeInterval)timeInterval;
- (NSArray*)getData:(MeterTimeInterval)timeInterval :(NSString*)dataType;

// Get the current time interval
- (NSTimeInterval)getTimeInterval:(MeterTimeInterval)theTimeInterval;
- (NSTimeInterval)getTimeIntervalForPlot:(MeterTimeInterval)theTimeInterval;
// Return the name of the time interval
- (NSString*)timeIntervalToString:(MeterTimeInterval)theTimeInterval;

// Return if device is connected over serial
- (BOOL)isConnected;

// Respond to detected voice commands
- (NSDictionary*)respondToCommand:(NSString*) command;

// Return the standard voice commands
- (NSArray*)standardVoiceCommands;
// Return the available selectors for voice commands
- (NSArray*)selectors;
// Return the available voice actions
- (NSArray*)readableSelectors;
@end
