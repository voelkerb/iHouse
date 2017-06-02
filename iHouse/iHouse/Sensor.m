//
//  Sensor.m
//  iHouse
//
//  Created by Benjamin Völker on 16/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "Sensor.h"
#import "Settings.h"
#import "VoiceCommand.h"

#define DEBUG_SENSOR false

#define SENSOR_STORE_FILE_NAME @"sensorData"

#define KEY_MONTH @"month"
#define KEY_DAY_WEEK @"day_week"
#define KEY_HOUR_MINUTE @"hour_minute"

#define MAX_STORED_OBJECTS 2000
#define THRESHOLD_LAST_UPDATE_WARNING 1000
#define DAY_WEEK_STORE_INTERVAL 1300
#define MONTH_STORE_INTERVAL 31550


#define SENSOR_DISCOVER_COMMAND @"iHouseSensor"

#define COMMAND_SEPERATOR @";"
#define COMMAND_PREFIX @"/"
#define COMMAND_DATA @"all;"

#define VOICE_COMMAND_TEMP @"Temperature"
#define VOICE_RESPONSES_TEMP @"The current temperature is %@ degrees."
#define VOICE_COMMAND_MOVEMENT @"Any movement in"
#define VOICE_RESPONSES_MOVEMENT_TRUE @"Yes, someone is moving."
#define VOICE_RESPONSES_MOVEMENT_FALSE @"NO, I can not detect anyone."
#define VOICE_COMMAND_BRIGHTNESS @"Brightness"
#define VOICE_RESPONSES_BRIGHTNESS @"The current brightness level is %@ lux."
#define VOICE_COMMAND_HUMIDITY @"Humidity"
#define VOICE_RESPONSES_HUMIDITY @"The current humidity level is %@ percent."
#define VOICE_COMMAND_PRESSURE @"Air pressure"
#define VOICE_RESPONSES_PRESSURE @"The current air pressure level is %@ hecto Pascal."

#define VOICE_RESPONSES_LAST_UPDATE @"But the last update was on "
#define VOICE_RESPONSES_WENT_WRONG @"Something went wrong.", @"Connection problem."

// Movement key for dictionary
NSString * const SensorKeyMovement = @"SensorKeyMovement";
// Humidity key for dictionary
NSString * const SensorKeyHumidity = @"SensorKeyHumidity";
// Temperature key for dictionary
NSString * const SensorKeyTemperature = @"SensorKeyTemperature";
// Pressure key for dictionary
NSString * const SensorKeyPressure = @"SensorKeyPressure";
// Brightnes key for dictionary
NSString * const SensorKeyBrightness = @"SensorKeyBrightness";
// TimeStamp key for dictionary
NSString * const SensorKeyTimeStamp = @"SensorKeyTimeStamp";
// If new data was stored, a notification is spread
NSString * const SensorHasNewData = @"SensorHasNewData";


@implementation Sensor
@synthesize timeInterval, sensorID, storedDataMonth, storedDataDayWeek, storedDataHourMinute, host, sensorHostHandler;
- (id)init {
  self = [super init];
  if (self) {
    // Default init for global variables
    timeInterval = sensor_day;
    sensorID = 0;
    host = @"";
    storedDataHourMinute = [[NSMutableArray alloc] init];
    storedDataDayWeek = [[NSMutableArray alloc] init];
    storedDataMonth = [[NSMutableArray alloc] init];
    [self addDummyData];
    // Coding indepentend inits
    [self codingIndependentInits];
  }
  return self;
}


// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeInteger:self.timeInterval forKey:@"timeInterval"];
  [encoder encodeInteger:self.sensorID forKey:@"sensorID"];
  [encoder encodeObject:self.host forKey:@"host"];
  // Data is stored in seperate file so that the house file does not get too big
  [self storeData];
}


// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    self.timeInterval = [decoder decodeIntegerForKey:@"timeInterval"];
    self.sensorID = [decoder decodeIntegerForKey:@"sensorID"];
    self.host = [decoder decodeObjectForKey:@"host"];
    // Coding independent inits
    [self codingIndependentInits];
  }
  return self;
}

/*
 * Inits that have to be done independent if the device is inited with decoder or inited traditional.
 */
- (void)codingIndependentInits {
  // Restore data from seperate file
  [self restoreData];
  sensorHostHandler = [SensorHostHandler sharedSensorHostHandler];
  // Add an observer to get sensor data
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(checkSensorData:)
                                               name:SensorHostHasNewData
                                             object:nil];
  
}

/*
 * Returns if the device is connected over serial.
 */
- (BOOL)isConnected {
  return [sensorHostHandler isConnected];
}

/*
 * If the device connected successfully.
 */
-(void)deviceConnected:(GCDAsyncSocket *)sock {
  // Give the host to the sensorHostHandler
  if (![sensorHostHandler isConnected]) [sensorHostHandler deviceConnected:sock];
}

/*
 * Add dummy data to the array
 */
- (void) addDummyData {
  [self addDataPoint:@"20.0;50;1;1013;100"];
}

/*
 * Return the command for discovering Sensor Devices
 */
-(NSString *)discoverCommandResponse {
  return SENSOR_DISCOVER_COMMAND;
}

/*
 * Let the sensor host handler free itself if needed
 */
- (void)freeSocket {
  [sensorHostHandler freeSocket];
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
                       [NSString stringWithFormat:@"%@%li%@", SENSOR_STORE_FILE_NAME, sensorID, [setting fileEnding]]];
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
                       [NSString stringWithFormat:@"%@%li%@", SENSOR_STORE_FILE_NAME, sensorID, [setting fileEnding]]];
  
  // Encode object into a dictionary
  NSDictionary *storedDataDict = [NSDictionary dictionaryWithObjectsAndKeys:storedDataMonth, KEY_MONTH,
                                  storedDataDayWeek, KEY_DAY_WEEK, storedDataHourMinute, KEY_HOUR_MINUTE, nil];
  
  // Archive object in file
  return [NSKeyedArchiver archiveRootObject:storedDataDict toFile:appFile];
}

/*
 * New data from serial is available. Check if it is meter data of this meter device.
 */
- (void)checkSensorData:(NSNotification*)notification {
 // Get command from notification and build the command string
  NSString *theCommand = [notification object];
  NSString *cmdPrefix = [NSString stringWithFormat:@"%@%@%li%@", COMMAND_PREFIX, COMMAND_DATA, sensorID, COMMAND_SEPERATOR];
  // If the string is less the command string or does not contain it, return
  if ([theCommand length] < [cmdPrefix length]) return;
  // If the beginning of the string contains the the meter command and the meter id
  if ([[theCommand substringToIndex:[cmdPrefix length]] containsString:cmdPrefix]) {
    // Add the new data point
    [self addDataPoint:[theCommand substringFromIndex:[cmdPrefix length]]];
  }
}


- (void)addDataPoint:(NSString *)dataAsString {
  // Get the data from the string. All Values are 0 by default
  NSNumber *temperature = [NSNumber numberWithInt:0];
  NSNumber *humidity = [NSNumber numberWithInt:0];
  NSNumber *movement = [NSNumber numberWithInt:0];
  NSNumber *brightness = [NSNumber numberWithInt:0];
  NSNumber *pressure = [NSNumber numberWithInt:0];
  // Reconstruct data from string
  if ([dataAsString rangeOfString:COMMAND_SEPERATOR].location != NSNotFound) {
    temperature = [NSNumber numberWithInteger:[[dataAsString substringToIndex:[dataAsString rangeOfString:COMMAND_SEPERATOR].location] doubleValue]];
    dataAsString = [dataAsString substringFromIndex:[dataAsString rangeOfString:COMMAND_SEPERATOR].location+[COMMAND_SEPERATOR length]];
    humidity = [NSNumber numberWithInteger:[dataAsString doubleValue]];
  }
  if ([dataAsString rangeOfString:COMMAND_SEPERATOR].location != NSNotFound) {
    dataAsString = [dataAsString substringFromIndex:[dataAsString rangeOfString:COMMAND_SEPERATOR].location+[COMMAND_SEPERATOR length]];
  }
  if ([dataAsString rangeOfString:COMMAND_SEPERATOR].location != NSNotFound) {
    movement = [NSNumber numberWithInteger:[[dataAsString substringToIndex:[dataAsString rangeOfString:COMMAND_SEPERATOR].location] integerValue]];
    dataAsString = [dataAsString substringFromIndex:[dataAsString rangeOfString:COMMAND_SEPERATOR].location+[COMMAND_SEPERATOR length]];
  }
  if ([dataAsString rangeOfString:COMMAND_SEPERATOR].location != NSNotFound) {
    pressure = [NSNumber numberWithInteger:[[dataAsString substringToIndex:[dataAsString rangeOfString:COMMAND_SEPERATOR].location] doubleValue]];
    dataAsString = [dataAsString substringFromIndex:[dataAsString rangeOfString:COMMAND_SEPERATOR].location+[COMMAND_SEPERATOR length]];
    brightness = [NSNumber numberWithDouble:[dataAsString doubleValue]];
  }
  
  if (DEBUG_SENSOR) NSLog(@"New Sensor Data: ID:%li Mov: %@, temp:%@°C, bright:%@lux, hum:%@$, pres:%@Pa", sensorID, movement, temperature, brightness, humidity, pressure);
  
  // Encode data into a dictionary
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:movement, SensorKeyMovement,
                        temperature, SensorKeyTemperature,
                        brightness, SensorKeyBrightness,
                        humidity, SensorKeyHumidity,
                        pressure, SensorKeyPressure,
                        [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]], SensorKeyTimeStamp, nil];
  
  // Store the data at least in the hour minute array
  // Remove oldest object if array gets out of bounds
  if ([storedDataHourMinute count] > MAX_STORED_OBJECTS) [storedDataHourMinute removeObjectAtIndex:0];
  [storedDataHourMinute addObject:dict];
  
  // Calculate time since last day and month update
  double timeSinceLastDayWeek = [[NSDate date] timeIntervalSince1970] - [[[storedDataDayWeek lastObject] objectForKey:SensorKeyTimeStamp] doubleValue];
  double timeSinceLastMonth = [[NSDate date] timeIntervalSince1970] - [[[storedDataMonth lastObject] objectForKey:SensorKeyTimeStamp] doubleValue];
  if (DEBUG_SENSOR) NSLog(@"Time since last DayWeekUpdate: %f, Time since last MonthUpdate %f: ", timeSinceLastDayWeek, timeSinceLastMonth);
  
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
  [[NSNotificationCenter defaultCenter] postNotificationName:SensorHasNewData object:self];
}



/*
 * Returns the time data for a given time interval.
 */
- (NSArray *)getTimeData:(SensorTimeInterval)theTimeInterval {
  // Time data is raw time while array holds information about time and all values
  NSMutableArray *timeData = [[NSMutableArray alloc] init];
  NSArray *array;
  // Get correct array for data
  switch (theTimeInterval) {
    case sensor_month:
      array = storedDataMonth;
      break;
    case sensor_week:
      array = storedDataDayWeek;
      break;
    case sensor_day:
      array = [self lastTime:60*60*24*1 ofArray:storedDataDayWeek];
      break;
    case sensor_hour:
      array = storedDataHourMinute;
      break;
    case sensor_minute:
      array = storedDataHourMinute;
      array = [self lastTime:60*10 ofArray:storedDataHourMinute];
      break;
    default:
      break;
  }
  
  // Copy only time data
  for (NSDictionary *dataDict in array) {
    [timeData addObject:[dataDict objectForKey:SensorKeyTimeStamp]];
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
  if (![[array lastObject] objectForKey:SensorKeyTimeStamp]) return nil;
  NSTimeInterval startTime = [[[array lastObject] objectForKey:SensorKeyTimeStamp] doubleValue];
  //NSLog(@"Start: %.2f, interval: %.2f", startTime, time);
  for (NSDictionary *dict in [array reverseObjectEnumerator]) {
    //NSLog(@"interval: %.2f, current: %.2f", time, startTime - [[dict objectForKey:MeterKeyTimeStamp] doubleValue]);
    if ((startTime - [[dict objectForKey:SensorKeyTimeStamp] doubleValue]) > time) break;
    [theArray addObject:dict];
  }
  return theArray;
}

/*
 * Returns data of a given tim interval and of a given data type
 */
-(NSArray *)getData:(SensorTimeInterval)theTimeInterval :(NSString *)dataType {
  NSMutableArray *data = [[NSMutableArray alloc] init];
  NSArray *array;
  switch (theTimeInterval) {
    case sensor_month:
      array = storedDataMonth;
      break;
    case sensor_week:
      array = storedDataDayWeek;
      break;
    case sensor_day:
      array = [self lastTime:60*60*24*1 ofArray:storedDataDayWeek];
      break;
    case sensor_hour:
      array = storedDataHourMinute;
      break;
    case sensor_minute:
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
- (NSString*)timeIntervalToString:(SensorTimeInterval)theTimeInterval {
  NSString *str = @"";
  switch (theTimeInterval) {
    case sensor_month:
      str = @"Month";
      break;
    case sensor_week:
      str = @"Week";
      break;
    case sensor_day:
      str = @"Day";
      break;
    case sensor_hour:
      str = @"Hour";
      break;
    case sensor_minute:
      str = @"Minute";
      break;
  }
  return str;
}

/*
 * Returns the currently set time interval.
 */
- (NSTimeInterval)getTimeIntervalForPlot:(SensorTimeInterval)theInterval {
  NSTimeInterval theTimeInterval = [self getTimeInterval:theInterval];;
  switch (theInterval) {
    case sensor_month: {
      theTimeInterval /= 10;
      break;
    }
      break;
    case sensor_week: {
      theTimeInterval /= 2;
      break;
    }
      break;
    case sensor_day: {
      theTimeInterval /= 5;
      break;
    }
    case sensor_hour: {
      break;
    }
    case sensor_minute: {
      theTimeInterval *= 2;
      break;
    }
  }
  return theTimeInterval;
}
/*
 * Returns the currently set time interval.
 */
- (NSTimeInterval)getTimeInterval:(SensorTimeInterval)theInterval {
  NSTimeInterval theTimeInterval;
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"dd/MM HH:mm"];
  [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
  switch (theInterval) {
    case sensor_month: {
      NSTimeInterval x1  = [[dateFormatter dateFromString:@"10/03 9:30"] timeIntervalSince1970];
      NSTimeInterval x2  = [[dateFormatter dateFromString:@"10/04 9:30"] timeIntervalSince1970];
      theTimeInterval = x2-x1;
      break;
    }
      break;
    case sensor_week: {
      NSTimeInterval x1  = [[dateFormatter dateFromString:@"10/03 9:30"] timeIntervalSince1970];
      NSTimeInterval x2  = [[dateFormatter dateFromString:@"17/03 9:30"] timeIntervalSince1970];
      theTimeInterval = x2-x1;
      break;
    }
      break;
    case sensor_day: {
      NSTimeInterval x1  = [[dateFormatter dateFromString:@"10/03 9:30"] timeIntervalSince1970];
      NSTimeInterval x2  = [[dateFormatter dateFromString:@"11/03 9:30"] timeIntervalSince1970];
      theTimeInterval = x2-x1;
      break;
    }
    case sensor_hour: {
      NSTimeInterval x1  = [[dateFormatter dateFromString:@"10/03 8:30"] timeIntervalSince1970];
      NSTimeInterval x2  = [[dateFormatter dateFromString:@"10/03 9:30"] timeIntervalSince1970];
      theTimeInterval = x2-x1;
      break;
    }
    case sensor_minute: {
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
 * Returns the movement.
 */
- (NSDictionary*)getMovement {
  NSString *response = [NSString stringWithFormat:@"%@", [self respondToCommand:VOICE_COMMAND_MOVEMENT]];
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:true],
          KeyVoiceCommandExecutedSuccessfully, response, KeyVoiceCommandResponseString, nil];
}

/*
 * Returns the temperature.
 */
- (NSDictionary*)getTemp {
  NSString *response = [NSString stringWithFormat:@"%@", [self respondToCommand:VOICE_COMMAND_TEMP]];
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:true],
          KeyVoiceCommandExecutedSuccessfully, response, KeyVoiceCommandResponseString, nil];
}

/*
 * Returns the brightness.
 */
- (NSDictionary*)getBrightness {
  NSString *response = [NSString stringWithFormat:@"%@", [self respondToCommand:VOICE_COMMAND_BRIGHTNESS]];
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:true],
          KeyVoiceCommandExecutedSuccessfully, response, KeyVoiceCommandResponseString, nil];
}

/*
 * Returns the pressure.
 */
- (NSDictionary*)getPressure {
  NSString *response = [NSString stringWithFormat:@"%@", [self respondToCommand:VOICE_COMMAND_PRESSURE]];
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:true],
          KeyVoiceCommandExecutedSuccessfully, response, KeyVoiceCommandResponseString, nil];
}

/*
  * Returns the humidity.
  */
- (NSDictionary*)getHumidity {
  NSString *response = [NSString stringWithFormat:@"%@", [self respondToCommand:VOICE_COMMAND_HUMIDITY]];
  return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:true],
          KeyVoiceCommandExecutedSuccessfully, response, KeyVoiceCommandResponseString, nil];
}

/*
 * Returns the standard voice commands of the device.
 */
-(NSArray *)standardVoiceCommands {
 
  VoiceCommand *movementCommand = [[VoiceCommand alloc] init];
  [movementCommand setName:VOICE_COMMAND_MOVEMENT];
  [movementCommand setCommand:VOICE_COMMAND_MOVEMENT];
  [movementCommand setSelector:@"getMovement"];
  VoiceCommand *tempCommand = [[VoiceCommand alloc] init];
  [tempCommand setName:VOICE_COMMAND_TEMP];
  [tempCommand setCommand:VOICE_COMMAND_TEMP];
  [tempCommand setSelector:@"getTemp"];
  VoiceCommand *brightnessCommand = [[VoiceCommand alloc] init];
  [brightnessCommand setName:VOICE_COMMAND_BRIGHTNESS];
  [brightnessCommand setCommand:VOICE_COMMAND_BRIGHTNESS];
  [brightnessCommand setSelector:@"getBrightness"];
  VoiceCommand *pressureCommand = [[VoiceCommand alloc] init];
  [pressureCommand setName:VOICE_COMMAND_PRESSURE];
  [pressureCommand setCommand:VOICE_COMMAND_PRESSURE];
  [pressureCommand setSelector:@"getPressure"];
  VoiceCommand *humidityCommand = [[VoiceCommand alloc] init];
  [humidityCommand setName:VOICE_COMMAND_HUMIDITY];
  [humidityCommand setCommand:VOICE_COMMAND_HUMIDITY];
  [humidityCommand setSelector:@"getHumidity"];
  
  NSArray *commands = [[NSArray alloc] initWithObjects:movementCommand, tempCommand, brightnessCommand,
                       pressureCommand, humidityCommand, nil];
  return commands;
}

/*
 * Return the available selectors for voice commands.
 */
-(NSArray *)selectors {
  return [[NSArray alloc] initWithObjects:@"getMovement", @"getTemp", @"getBrightness", @"getPressure", @"getHumidity",  nil];
}

/*
 * Returns the voice command extensions the device should be sensitive to.
 */
-(NSArray *)readableSelectors {
  return [[NSArray alloc] initWithObjects:@"Return Movement", @"Return Temperature", @"Return Brightness Level",
          @"Return Air-Pressure Level", @"Return Humidity Level", nil];
}

/*
 * Responses to a recognized voice command.
 */
-(NSString *)respondToCommand:(NSString *)command {
  NSString *response = @"";
  
  // Make a formatter to return the values
  NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
  // Minimum 0 decimals and maximum 2 decimals
  [numberFormatter setMaximumFractionDigits:2];
  [numberFormatter setMinimumFractionDigits:0];
  
  // Look what type of information you want
  // If command was a movement command
  if ([command containsString:VOICE_COMMAND_MOVEMENT]) {
    if ([[[storedDataHourMinute lastObject] objectForKey:SensorKeyMovement] intValue] == 0) {
      response = VOICE_RESPONSES_MOVEMENT_FALSE;
    } else {
      response = VOICE_RESPONSES_MOVEMENT_TRUE;
    }
  // If command was a get temperature command
  } else if ([command containsString:VOICE_COMMAND_TEMP]) {
    response = [NSString stringWithFormat:VOICE_RESPONSES_TEMP,
                [numberFormatter stringFromNumber:[[storedDataHourMinute lastObject] objectForKey:SensorKeyTemperature]]];
  // If command was a get humidity command
  } else if ([command containsString:VOICE_COMMAND_HUMIDITY]) {
    response = [NSString stringWithFormat:VOICE_RESPONSES_HUMIDITY,
                [numberFormatter stringFromNumber:[[storedDataHourMinute lastObject] objectForKey:SensorKeyHumidity]]];
  // If command was a get pressure command, this command is converted to hecto pascal
  } else if ([command containsString:VOICE_COMMAND_PRESSURE]) {
    response = [NSString stringWithFormat:VOICE_RESPONSES_PRESSURE,
                [numberFormatter stringFromNumber:
                 [NSNumber numberWithInteger:[[[storedDataHourMinute lastObject] objectForKey:SensorKeyPressure] integerValue]/100]]];
  // If command was a get brightness command
  } else if ([command containsString:VOICE_COMMAND_BRIGHTNESS]) {
    response = [NSString stringWithFormat:VOICE_RESPONSES_BRIGHTNESS,
                [numberFormatter stringFromNumber:[[storedDataHourMinute lastObject] objectForKey:SensorKeyBrightness]]];
  }
  
  // If time since last update is high, display warning with text
  double timeSinceLastUpdate = [[NSDate date] timeIntervalSince1970] - [[[storedDataHourMinute lastObject] objectForKey:SensorKeyTimeStamp] doubleValue];
  if (timeSinceLastUpdate > THRESHOLD_LAST_UPDATE_WARNING) { // Restore time from time interval
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[[storedDataHourMinute lastObject] objectForKey:SensorKeyTimeStamp] doubleValue]];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    // Format the time nicely
    [format setDateFormat:@"MMMM dd, HH:mm"];
    response = [NSString stringWithFormat:@"%@ %@%@", response, VOICE_RESPONSES_LAST_UPDATE, [format stringFromDate:date]];
  }
  // Repsonse dictionary should be a text and a view, but no view here
 return response;
}

@end
