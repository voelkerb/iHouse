//
//  Meter.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "Meter.h"
#import "Settings.h"
#import "VoiceCommand.h"

#define DEBUG_METER 0

#define COMMAND_RESPONSE @"/"
#define COMMAND_METER @"m"
#define COMMAND_SEPERATOR @";"
#define METER_STORE_FILE_NAME @"meterData"
#define KEY_MONTH @"month"
#define KEY_DAY_WEEK @"day_week"
#define KEY_HOUR_MINUTE @"hour_minute"
#define MAX_STORED_OBJECTS 1000
#define THRESHOLD_LAST_UPDATE_WARNING 1000
#define DAY_WEEK_STORE_INTERVAL 1300
#define MONTH_STORE_INTERVAL 31550

#define VOICE_COMMAND_VOLTAGE @"Voltage consumption"
#define VOICE_RESPONSES_VOLTAGE @"The device is consuming %@ Volt"
#define VOICE_COMMAND_CURRENT @"Current consumption"
#define VOICE_RESPONSES_CURRENT @"The device is consuming %@ milli Ampere"
#define VOICE_COMMAND_POWER @"Power consumption"
#define VOICE_RESPONSES_POWER @"The device is consuming %@ Watt"
#define VOICE_COMMAND_ENERGY @"Energy consumption"
#define VOICE_RESPONSES_ENERGY @"The device has consumed %@ kilo Watt hours"
#define VOICE_RESPONSES_LAST_UPDATE @", but the last update was on "
#define VOICE_RESPONSES_WENT_WRONG @"Something went wrong.", @"Connection problem."

NSString * const MeterKeyVoltage = @"MeterKeyVoltage";
NSString * const MeterKeyCurrent = @"MeterKeyCurrent";
NSString * const MeterKeyPower = @"MeterKeyPower";
NSString * const MeterKeyEnergy = @"MeterKeyEnergy";
NSString * const MeterKeyTimeStamp = @"MeterKeyTimeStamp";

// For notification when a meter has new data
NSString * const MeterHasNewData = @"MeterHasNewData";

@implementation Meter
@synthesize type, timeInterval, meterID, storedDataMonth, storedDataDayWeek, storedDataHourMinute, connectionHandler;
- (id)init {
  self = [super init];
  if (self) {
    // Default init for global variables
    type = EMT7110;
    timeInterval = meter_day;
    meterID = 0;
    storedDataHourMinute = [[NSMutableArray alloc] init];
    storedDataDayWeek = [[NSMutableArray alloc] init];
    storedDataMonth = [[NSMutableArray alloc] init];
    // TODO: Remove
    [self addDummyData];
    // Coding indepentend inits
    [self codingIndependentInits];
  }
  return self;
}

/*
 * Add dummy data to the array
 */
- (void) addDummyData {
  [self addDataPoint:@"240;50;10.5;0.14"];
}


// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeInteger:self.type forKey:@"type"];
  [encoder encodeInteger:self.timeInterval forKey:@"timeInterval"];
  [encoder encodeInteger:self.meterID forKey:@"meterID"];
  // Data is stored in seperate file so that the house file does not get too big
  [self storeData];
}


// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    self.type = [decoder decodeIntegerForKey:@"type"];
    self.timeInterval = [decoder decodeIntegerForKey:@"timeInterval"];
    self.meterID = [decoder decodeIntegerForKey:@"meterID"];
    // Coding independent inits
    [self codingIndependentInits];
  }
  return self;
}

/*
 * Inits that have to be done independent if the device is inited with decoder or inited traditional.
 */
- (void)codingIndependentInits {
  // Init the connectionHandler object
  connectionHandler = [SerialConnectionHandler sharedSerialConnectionHandler];
  // Restore data from seperate file
  [self restoreData];
  // Add an observer to get meter data
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(checkMeterData:)
                                               name:SerialConnectionHandlerSerialResponse
                                             object:nil];

}

/*
 * Returns if the energy sniffer is connected over serial.
 */
- (BOOL)isConnected {
  return [connectionHandler serialPortIsOpen];
}


/*
 * Restores the data of the meter from a seperate file.
 */
- (void)restoreData {
  // Get the file directory
  Settings *setting = [Settings sharedSettings];
  NSString *fileDirectory = [setting storePath];
  // Append the file name and ending
  NSString *appFile = [fileDirectory stringByAppendingPathComponent:
                       [NSString stringWithFormat:@"%@%li%@", METER_STORE_FILE_NAME, meterID, [setting fileEnding]]];
  // Unarchive object and store on success
  NSDictionary *storedDataDict = [NSKeyedUnarchiver unarchiveObjectWithFile:appFile];
  if ([storedDataDict objectForKey:KEY_MONTH]) storedDataMonth = [storedDataDict objectForKey:KEY_MONTH];
  if ([storedDataDict objectForKey:KEY_DAY_WEEK])  storedDataDayWeek = [storedDataDict objectForKey:KEY_DAY_WEEK];
  if ([storedDataDict objectForKey:KEY_HOUR_MINUTE])  storedDataHourMinute = [storedDataDict objectForKey:KEY_HOUR_MINUTE];
  // Look if data is unarchived correctly
  if (!storedDataMonth) storedDataMonth = [[NSMutableArray alloc] init];
  if (!storedDataDayWeek) storedDataDayWeek = [[NSMutableArray alloc] init];
  if (!storedDataHourMinute) storedDataHourMinute = [[NSMutableArray alloc] init];
}

/*
 * Stores the data of the meter into a seperate file
 */
- (BOOL)storeData {
  // Get the file directory
  Settings *setting = [Settings sharedSettings];
  NSString *fileDirectory = [setting storePath];
  // Append the file name and ending
  NSString *appFile = [fileDirectory stringByAppendingPathComponent:
                       [NSString stringWithFormat:@"%@%li%@", METER_STORE_FILE_NAME, meterID, [setting fileEnding]]];
  
  // Encode object into a dictionary
  NSDictionary *storedDataDict = [NSDictionary dictionaryWithObjectsAndKeys:storedDataMonth, KEY_MONTH,
                                  storedDataDayWeek, KEY_DAY_WEEK, storedDataHourMinute, KEY_HOUR_MINUTE, nil];
  
  // Archive object in file
  return [NSKeyedArchiver archiveRootObject:storedDataDict toFile:appFile];
}

/*
 * New data from serial is available. Check if it is meter data of this meter device.
 */
- (void)checkMeterData:(NSNotification*)notification {
  NSString *theCommand = [notification object];
  if (DEBUG_METER) NSLog(@"%@", theCommand);
  
  NSString *cmdPrefix = [NSString stringWithFormat:@"%@%@%li", COMMAND_RESPONSE, COMMAND_METER, meterID];
  if ([theCommand length] < [cmdPrefix length]) return;
  // If the beginning of the string contains the the meter command and the meter id
  if ([[theCommand substringToIndex:[cmdPrefix length]] containsString:cmdPrefix]) {
    // Store the data
    [self addDataPoint:[theCommand substringFromIndex:[cmdPrefix length]+[COMMAND_SEPERATOR length]]];
  }
}


- (void)addDataPoint:(NSString *)dataAsString {
  // Get the data from the string
  NSNumber *voltage = [NSNumber numberWithInteger:[[dataAsString substringToIndex:[dataAsString rangeOfString:COMMAND_SEPERATOR].location] integerValue]];
  dataAsString = [dataAsString substringFromIndex:[dataAsString rangeOfString:COMMAND_SEPERATOR].location+[COMMAND_SEPERATOR length]];
  NSNumber *current = [NSNumber numberWithInteger:[[dataAsString substringToIndex:[dataAsString rangeOfString:COMMAND_SEPERATOR].location] integerValue]];
  dataAsString = [dataAsString substringFromIndex:[dataAsString rangeOfString:COMMAND_SEPERATOR].location+[COMMAND_SEPERATOR length]];
  NSString *powerStr = [dataAsString substringToIndex:[dataAsString rangeOfString:COMMAND_SEPERATOR].location];
  NSNumber *power = [NSNumber numberWithDouble:[powerStr doubleValue]];
  dataAsString = [dataAsString substringFromIndex:[dataAsString rangeOfString:COMMAND_SEPERATOR].location+[COMMAND_SEPERATOR length]];
  NSNumber *energy = [NSNumber numberWithDouble:[dataAsString doubleValue]];
  if (DEBUG_METER) NSLog(@"Heurika: %@V, %@mA, %@W, %@kWh", voltage, current, power, energy);
  
  // Encode data into a dictionary
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:voltage, MeterKeyVoltage,
                        current, MeterKeyCurrent,
                        power, MeterKeyPower,
                        energy, MeterKeyEnergy,
                        [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]], MeterKeyTimeStamp, nil];
  
  // Store the data at least in the hour minute array
  // Remove oldest object if array gets out of bounds
  if ([storedDataHourMinute count] > MAX_STORED_OBJECTS) [storedDataHourMinute removeObjectAtIndex:0];
  [storedDataHourMinute addObject:dict];
  
  // Calculate time since last day and month update
  double timeSinceLastDayWeek = [[NSDate date] timeIntervalSince1970] - [[[storedDataDayWeek lastObject] objectForKey:MeterKeyTimeStamp] doubleValue];
  double timeSinceLastMonth = [[NSDate date] timeIntervalSince1970] - [[[storedDataMonth lastObject] objectForKey:MeterKeyTimeStamp] doubleValue];
  //NSLog(@"Time since last DayWeekUpdate: %f, Time since last MonthUpdate %f: ", timeSinceLastDayWeek, timeSinceLastMonth);

  // If time is greater than a threshold so that at least 2 weeks of data can be stored in array
  if (timeSinceLastDayWeek > DAY_WEEK_STORE_INTERVAL) {
    // Look if array is in given bounds
    if ([storedDataDayWeek count] > MAX_STORED_OBJECTS) [storedDataDayWeek removeObjectAtIndex:0];
    // Store data
    [storedDataDayWeek addObject:dict];
    //NSLog(@"New data for dayWeek array%@", storedDataDayWeek);
  }
  // If time is greater than a threshold so that at least 1 year of data can be stored in array
  if (timeSinceLastMonth > MONTH_STORE_INTERVAL) {
    // Look if array is in given bounds
    if ([storedDataMonth count] > MAX_STORED_OBJECTS) [storedDataMonth removeObjectAtIndex:0];
    // Store data
    [storedDataMonth addObject:dict];
    //NSLog(@"New data for month array");
  }
  
  // Send a notification that new data is available
  [[NSNotificationCenter defaultCenter] postNotificationName:MeterHasNewData object:nil];
}

/*
 * Returns the time data for a given time interval.
 */
- (NSArray *)getTimeData:(MeterTimeInterval)theTimeInterval {
  // Time data is raw time while array holds information about time and all values
  NSMutableArray *timeData = [[NSMutableArray alloc] init];
  NSArray *array;
  // Get correct array for data
  switch (theTimeInterval) {
    case meter_month:
      array = storedDataMonth;
      break;
    case meter_week:
      array = storedDataDayWeek;
      break;
    case meter_day:
      array = [self lastTime:60*60*24*1 ofArray:storedDataDayWeek];
      break;
    case meter_hour:
      array = storedDataHourMinute;
      break;
    case meter_minute:
      array = storedDataHourMinute;
      array = [self lastTime:60*10 ofArray:storedDataHourMinute];
      break;
    default:
      break;
  }
  
  // Copy only time data
  for (NSDictionary *dataDict in array) {
    [timeData addObject:[dataDict objectForKey:MeterKeyTimeStamp]];
  }
  
  return timeData;
}

/*
 * Get a given amount of data out of the given array.
 * Will handle if the given number is greater than array size.
 */
-(NSArray *)last:(NSInteger)values ofArray:(NSArray*)array {
  NSMutableArray *theArray = [[NSMutableArray alloc] init];
  for (NSObject *obj in [array reverseObjectEnumerator]) {
    [theArray addObject:obj];
    if ([theArray count] >= values) break;
  }
  return theArray;
}

/*
 * Get data out of the given array which lie in the last given time.
 * Will handle if the given number is greater than array size.
 */
-(NSArray *)lastTime:(NSTimeInterval)time ofArray:(NSArray*)array {
  NSMutableArray *theArray = [[NSMutableArray alloc] init];
  if (![[array lastObject] objectForKey:MeterKeyTimeStamp]) return nil;
  NSTimeInterval startTime = [[[array lastObject] objectForKey:MeterKeyTimeStamp] doubleValue];
  //NSLog(@"Start: %.2f, interval: %.2f", startTime, time);
  for (NSDictionary *dict in [array reverseObjectEnumerator]) {
    //NSLog(@"interval: %.2f, current: %.2f", time, startTime - [[dict objectForKey:MeterKeyTimeStamp] doubleValue]);
    if ((startTime - [[dict objectForKey:MeterKeyTimeStamp] doubleValue]) > time) break;
    [theArray addObject:dict];
  }
  return theArray;
}

/*
 * Returns data of a given tim interval and of a given data type
 */
-(NSArray *)getData:(MeterTimeInterval)theTimeInterval :(NSString *)dataType {
  NSMutableArray *data = [[NSMutableArray alloc] init];
  NSArray *array;
  switch (theTimeInterval) {
    case meter_month:
      array = storedDataMonth;
      break;
    case meter_week:
      array = storedDataDayWeek;
      break;
    case meter_day:
      array = [self lastTime:60*60*24*1 ofArray:storedDataDayWeek];
      break;
    case meter_hour:
      array = storedDataHourMinute;
      break;
    case meter_minute:
      //array = storedDataHourMinute;
      array = [self lastTime:60*10 ofArray:storedDataHourMinute];
      break;
    default:
      break;
  }
  for (NSDictionary *dataDict in array) {
    [data addObject:[dataDict objectForKey:dataType]];
  }
  return data;
}

/*
 * Time interval to string.
 */
- (NSString*)timeIntervalToString:(MeterTimeInterval)theTimeInterval {
  NSString *str = @"";
  switch (theTimeInterval) {
    case meter_month:
      str = @"Month";
      break;
    case meter_week:
      str = @"Week";
      break;
    case meter_day:
      str = @"Day";
      break;
    case meter_hour:
      str = @"Hour";
      break;
    case meter_minute:
      str = @"Minute";
      break;
  }
  return str;
}

/*
 * Returns the currently set time interval.
 */
- (NSTimeInterval)getTimeIntervalForPlot:(MeterTimeInterval)theInterval {
  NSTimeInterval theTimeInterval = [self getTimeInterval:theInterval];;
  switch (theInterval) {
    case meter_month: {
      theTimeInterval /= 10;
      break;
    }
      break;
    case meter_week: {
      theTimeInterval /= 2;
      break;
    }
      break;
    case meter_day: {
      theTimeInterval /= 5;
      break;
    }
    case meter_hour: {
      break;
    }
    case meter_minute: {
      theTimeInterval *= 2;
      break;
    }
  }
  return theTimeInterval;
}
/*
 * Returns the currently set time interval.
 */
- (NSTimeInterval)getTimeInterval:(MeterTimeInterval)theInterval {
  NSTimeInterval theTimeInterval;
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"dd/MM HH:mm"];
  [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
  switch (theInterval) {
    case meter_month: {
      NSTimeInterval x1  = [[dateFormatter dateFromString:@"10/03 9:30"] timeIntervalSince1970];
      NSTimeInterval x2  = [[dateFormatter dateFromString:@"10/04 9:30"] timeIntervalSince1970];
      theTimeInterval = x2-x1;
      break;
    }
      break;
    case meter_week: {
      NSTimeInterval x1  = [[dateFormatter dateFromString:@"10/03 9:30"] timeIntervalSince1970];
      NSTimeInterval x2  = [[dateFormatter dateFromString:@"17/03 9:30"] timeIntervalSince1970];
      theTimeInterval = x2-x1;
      break;
    }
      break;
    case meter_day: {
      NSTimeInterval x1  = [[dateFormatter dateFromString:@"10/03 9:30"] timeIntervalSince1970];
      NSTimeInterval x2  = [[dateFormatter dateFromString:@"11/03 9:30"] timeIntervalSince1970];
      theTimeInterval = x2-x1;
      break;
    }
    case meter_hour: {
      NSTimeInterval x1  = [[dateFormatter dateFromString:@"10/03 8:30"] timeIntervalSince1970];
      NSTimeInterval x2  = [[dateFormatter dateFromString:@"10/03 9:30"] timeIntervalSince1970];
      theTimeInterval = x2-x1;
      break;
    }
    case meter_minute: {
      NSTimeInterval x1  = [[dateFormatter dateFromString:@"10/03 8:30"] timeIntervalSince1970];
      NSTimeInterval x2  = [[dateFormatter dateFromString:@"10/03 8:31"] timeIntervalSince1970];
      theTimeInterval = x2-x1;
      break;
    }
  }
  return theTimeInterval;
}


#pragma mark voice command functions

/*
 * Returns the voltage.
 */
- (NSDictionary*)getVoltage {
  NSString *response = [NSString stringWithFormat:@"%@", [self respondToCommand:VOICE_COMMAND_VOLTAGE]];
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:true],
          KeyVoiceCommandExecutedSuccessfully, response, KeyVoiceCommandResponseString, nil];
}

/*
 * Returns the current.
 */
- (NSDictionary*)getCurrent {
  NSString *response = [NSString stringWithFormat:@"%@", [self respondToCommand:VOICE_COMMAND_CURRENT]];
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:true],
          KeyVoiceCommandExecutedSuccessfully, response, KeyVoiceCommandResponseString, nil];
}

/*
 * Returns the power.
 */
- (NSDictionary*)getPower {
  NSString *response = [NSString stringWithFormat:@"%@", [self respondToCommand:VOICE_COMMAND_POWER]];
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:true],
          KeyVoiceCommandExecutedSuccessfully, response, KeyVoiceCommandResponseString, nil];
}

/*
 * Returns the energy.
 */
- (NSDictionary*)getEnergy {
  NSString *response = [NSString stringWithFormat:@"%@", [self respondToCommand:VOICE_COMMAND_ENERGY]];
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:true],
          KeyVoiceCommandExecutedSuccessfully, response, KeyVoiceCommandResponseString, nil];
}

/*
 * Returns the standard voice commands of the device.
 */
-(NSArray *)standardVoiceCommands {
  VoiceCommand *voltageCommand = [[VoiceCommand alloc] init];
  [voltageCommand setName:VOICE_COMMAND_VOLTAGE];
  [voltageCommand setCommand:VOICE_COMMAND_VOLTAGE];
  [voltageCommand setSelector:@"getVoltage"];
  VoiceCommand *currentCommand = [[VoiceCommand alloc] init];
  [currentCommand setName:VOICE_COMMAND_CURRENT];
  [currentCommand setCommand:VOICE_COMMAND_CURRENT];
  [currentCommand setSelector:@"getCurrent"];
  VoiceCommand *powerCommand = [[VoiceCommand alloc] init];
  [powerCommand setName:VOICE_COMMAND_POWER];
  [powerCommand setCommand:VOICE_COMMAND_POWER];
  [powerCommand setSelector:@"getPower"];
  VoiceCommand *energyCommand = [[VoiceCommand alloc] init];
  [energyCommand setName:VOICE_COMMAND_ENERGY];
  [energyCommand setCommand:VOICE_COMMAND_ENERGY];
  [energyCommand setSelector:@"getEnergy"];
  
  NSArray *commands = [[NSArray alloc] initWithObjects:voltageCommand, currentCommand, powerCommand, energyCommand, nil];
  return commands;
}

/*
 * Return the available selectors for voice commands.
 */
-(NSArray *)selectors {
  return [[NSArray alloc] initWithObjects:@"getVoltage", @"getCurrent", @"getPower", @"getEnergy",  nil];
}

/*
 * Returns the voice command extensions the device should be sensitive to.
 */
-(NSArray *)readableSelectors {
  return [[NSArray alloc] initWithObjects:@"Return Voltage", @"Return Current", @"Return Power", @"Return Energy", nil];
}

/*
 * Responses to a recognized voice command.
 */
-(NSString *)respondToCommand:(NSString *)command {
  NSString *response = @"";
  
  // Make a formatter to return the values
  NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
  [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
  [numberFormatter setDecimalSeparator:@"."];
  // Minimum 0 decimals and maximum 2 decimals
  [numberFormatter setMaximumFractionDigits:2];
  [numberFormatter setMinimumFractionDigits:0];
  
  // Look what type of information you want
  if ([command containsString:VOICE_COMMAND_VOLTAGE]) {
    response = [NSString stringWithFormat:VOICE_RESPONSES_VOLTAGE,
                [numberFormatter stringFromNumber:[[storedDataHourMinute lastObject] objectForKey:MeterKeyVoltage]]];
  } else if ([command containsString:VOICE_COMMAND_CURRENT]) {
    response = [NSString stringWithFormat:VOICE_RESPONSES_CURRENT,
                [numberFormatter stringFromNumber:[[storedDataHourMinute lastObject] objectForKey:MeterKeyCurrent]]];
  } else if ([command containsString:VOICE_COMMAND_POWER]) {
    response = [NSString stringWithFormat:VOICE_RESPONSES_POWER,
                [numberFormatter stringFromNumber:[[storedDataHourMinute lastObject] objectForKey:MeterKeyPower]]];
  } else if ([command containsString:VOICE_COMMAND_ENERGY]) {
    response = [NSString stringWithFormat:VOICE_RESPONSES_ENERGY,
                [numberFormatter stringFromNumber:[[storedDataHourMinute lastObject] objectForKey:MeterKeyEnergy]]];
  }
  
  // If time since last update is high, display warning with text
  double timeSinceLastUpdate = [[NSDate date] timeIntervalSince1970] - [[[storedDataHourMinute lastObject] objectForKey:MeterKeyTimeStamp] doubleValue];
  if (timeSinceLastUpdate > THRESHOLD_LAST_UPDATE_WARNING) { // Restore time from time interval
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[[storedDataHourMinute lastObject] objectForKey:MeterKeyTimeStamp] doubleValue]];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    // Format the time nicely
    [format setDateFormat:@"MMM dd, HH:mm"];
    response = [NSString stringWithFormat:@"%@%@%@", response, VOICE_RESPONSES_LAST_UPDATE, [format stringFromDate:date]];
  }
  return response;
}

@end
