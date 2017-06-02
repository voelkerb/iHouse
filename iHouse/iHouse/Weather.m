//
//  Weather.m
//  iHouse
//
//  Created by Benjamin Völker on 26/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "Weather.h"
#import "WeatherViewController.h"
#import "VoiceCommand.h"
#import "StringToSpeechFormatter.h"

// JSSON Dictionary requieres different null comparison
#define isNull(value) value == nil || [value isKindOfClass:[NSNull class]]

#define DEBUG_WEATHER false
// The weather is refreshed automatically every half hour
#define DEFINE_WEATHER_REFRESH_SECONDS 1800
#define DEFINE_WEATHER_REFRESH_ERROR_SECONDS 3
// The weather images
#define IMAGE_CLEAR @"weather_clear_night.png"
#define IMAGE_CLOUDS @"weather_clouds.png"
#define IMAGE_CLOUDY @"weather_cloudy.png"
#define IMAGE_CLOUDY_NIGHT @"weather_cloudy_night.png"
#define IMAGE_FOG @"weather_fog.png"
#define IMAGE_RAIN @"weather_rain.png"
#define IMAGE_SNOW @"weather_snow.png"
#define IMAGE_SUNNY @"weather_sunny.png"
#define IMAGE_WINDY @"weather_windy.png"
#define IMAGE_THUNDER @"weather_thunder.png"

// If condition is not available
#define CONDITIONS_NOT_AVAILABLE_STRING @"Not available"


#define VOICE_COMMAND_GET_TODAY_WEATHER @"Show todays weather"
#define VOICE_RESPONS_GET_WEATHER @"Here is the weather for %@"
#define VOICE_RESPONS_GET_WEATHER_WEEK @"Here is the weather forecast for this week:"
#define VOICE_RESPONS_GET_TODAY @"today, "
#define VOICE_RESPONS_GET_TOMORROW @"tomorrow, "


// New weather available
NSString * const WeatherNewWeatherAvailable = @"WeatherNewWeatherAvailable";

@implementation Weather

@synthesize forecast, lastUpdate, sunrise, sunset, humidity, pressure, currentTemp;
@synthesize currentCondition, currentWindDirection, currentWindSpeed, locationCity;
@synthesize locationCountry, locationRegion, unitPressure, unitSpeed, unitTemp;
@synthesize location, allConditions, allWeekDays;
@synthesize name;

/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedWeather {
  static Weather *sharedWeather = nil;
  @synchronized(self) {
    if (sharedWeather == nil) {
      sharedWeather = [[self alloc] init];
    }
  }
  return sharedWeather;
}

- (id)init {
  if (self = [super init]) {
    // Init global variables
    name = @"Calendar";
    hasInternet = false;
    yql = [[YQL alloc] init];
    lastUpdate = nil;
    sunrise = nil;
    sunset = nil;
    humidity = nil;
    pressure = nil;
    currentTemp = nil;
    currentCondition = nil;
    currentWindDirection = nil;
    currentWindSpeed = nil;
    locationCity = @"---";
    locationCountry = @"---";
    locationRegion = @"---";
    unitPressure = @"mb";
    unitSpeed = @"km/h";
    unitTemp = @"C";
    forecast = [[NSDictionary alloc] init];
    
    // Init all weekday dictionary with objects and keys
    allWeekDays = [[NSDictionary alloc] initWithObjectsAndKeys:
                   @"Mon", @"Mon",
                   @"Tue", @"Tue",
                   @"Wed", @"Wed",
                   @"Thu", @"Thu",
                   @"Fri", @"Fri",
                   @"Sat", @"Sat",
                   @"Sun", @"Sun",
                   nil];
    // All conditions as an nsarray
    allConditions = [NSArray arrayWithObjects:
                     @"Tornado",
                     @"Tropical storm",
                     @"Hurricane",
                     @"Severe thunderstorms",
                     @"Thunderstorms",
                     @"Mixed rain and snow",
                     @"Mixed rain and sleet",
                     @"Mixed snow and sleet",
                     @"Freezing drizzle",
                     @"Drizzle",
                     @"Freezing rain",
                     @"Showers",
                     @"Showers",
                     @"Snow flurries",
                     @"Light snow shower",
                     @"Blowing snow",
                     @"Snow",
                     @"Hail",
                     @"Sleet",
                     @"Dust",
                     @"Foggy",
                     @"Smoky",
                     @"Blustery",
                     @"Windy",
                     @"Cold",
                     @"Mostly cloudy",
                     @"Mostly cloudy",
                     @"Partly cloudy",
                     @"Partly cloudy",
                     @"Clear",
                     @"Sunny",
                     @"Fair",
                     @"Fair",
                     @"Mixed rain and hail",
                     @"Hot",
                     @"Isolated thunderstorms",
                     @"Scattered thunderstorms",
                     @"Scattered thunderstorms",
                     @"Scattered showers",
                     @"Heavy snow",
                     @"Partly cloudy",
                     @"Thundershowers",
                     @"Snow showers",
                     @"isolated thundershowers",
                     nil];
        
    // Update the weather 3 seconds after init
    [self performSelector:@selector(updateWeather) withObject:nil afterDelay:3];
  }
  return self;
}

// Coding needed since voice commands store the handler and the handler is us
- (void)encodeWithCoder:(NSCoder *)aCoder {
}

// For init just init us properly
-(id)initWithCoder:(NSCoder *)aDecoder {
  return [Weather sharedWeather];
}


/*
 * Updates weather data from yahoo.com for the set location.
 */
-(void) updateWeather {
  // If the location was not yet set, we can not retrieve weather data
  // Instead recall this function after reasonable short time to be aware when
  // the current location is finally available
  if (!location) {
    [self performSelector:@selector(updateWeather) withObject:nil afterDelay:2];
    if (DEBUG_WEATHER) NSLog(@"Can not update weather: Location not available");
    return;
  }
  if (DEBUG_WEATHER) NSLog(@"Current location %@", location);

  // Prevent view from being stuck if no internet connection is available
  // Check for internet connection and if not availbale, stop retrieving weather data here
  // Instead call this methode again after reasonable short time to be aware if when internet is
  // finally available and can be used
  if (![self connectedToInternet]) {
    hasInternet = false;
    [self performSelector:@selector(updateWeather) withObject:nil afterDelay:DEFINE_WEATHER_REFRESH_ERROR_SECONDS];
    if (DEBUG_WEATHER) NSLog(@"Can not update weather: Internet not available");
    return;
  }
  hasInternet = true;
  
  // Find locations woeid from latitude and longitude data
  //SELECT * FROM geo.placefinder WHERE text="{$seedLat}, {$seedLon}" and gflags="R"
  NSString *queryLocationBased = @"SELECT * FROM weather.forecast WHERE woeid IN (SELECT woeid FROM geo.places(1) WHERE text=\"(";
  //NSLog(@"Location %f, %f ", location.coordinate.latitude, location.coordinate.longitude);
  queryLocationBased = [NSString stringWithFormat:@"%@%f, %f)", queryLocationBased, location.coordinate.latitude, location.coordinate.longitude];
  // Add Flag for celsius
  queryLocationBased = [NSString stringWithFormat:@"%@\") AND u='c'", queryLocationBased];
  
  
  //queryLocationBased = @"SELECT * FROM weather.forecast WHERE woeid IN (SELECT woeid FROM geo.places(1) WHERE text=\"(17.4186947,78.5425238)\")";
  NSDictionary *results = [yql query:queryLocationBased];
  // Decode the results
  [self decodeWeatherResult:results];
  
  // Recall this methode after given time
  [self performSelector:@selector(updateWeather) withObject:nil afterDelay:DEFINE_WEATHER_REFRESH_SECONDS];
  //[self performSelector:@selector(updateWeather) withObject:nil afterDelay:2];
}

/*
 * Checks the connection to the internet by waiting for a response of
 * www.googe.com
 */
- (BOOL) connectedToInternet {
  NSString *URLString = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://www.google.com"]];
  if (DEBUG_WEATHER) NSLog(@"Internet: %i", URLString != NULL );
  return ( URLString != NULL ) ? YES : NO;
}

/*
 * Decodes the weather dictionary to update member variables.
 */
-(void)decodeWeatherResult:(NSDictionary*)results {
  
  // If Something went wrong while retrieving weather data
  if (isNull( results[@"query"][@"results"])) {
    NSLog(@"Error while retrieving weather data");
    
    //[self performSelector:@selector(updateWeather) withObject:nil afterDelay:1];
    return;
  }
  
  NSDictionary *astronomy = results[@"query"][@"results"][@"channel"][@"astronomy"];
  NSDictionary *atmosphere = results[@"query"][@"results"][@"channel"][@"atmosphere"];
  NSDictionary *theLocation = results[@"query"][@"results"][@"channel"][@"location"];
  NSDictionary *units = results[@"query"][@"results"][@"channel"][@"units"];
  NSDictionary *currentWind = results[@"query"][@"results"][@"channel"][@"wind"];
  NSDictionary *currentWeather = results[@"query"][@"results"][@"channel"][@"item"][@"condition"];
  forecast = results[@"query"][@"results"][@"channel"][@"item"][@"forecast"];
  
  // Get sunrise and sunset time
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
  [formatter setDateFormat:@"hh:mm a"];
  sunrise = [formatter dateFromString:astronomy[@"sunrise"]];
  sunset = [formatter dateFromString:astronomy[@"sunset"]];
  formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
  [formatter setDateFormat:@"HH:mm"];
  if (DEBUG_WEATHER) NSLog(@"SunRise: %@ UHR", [formatter stringFromDate:sunrise] );
  if (DEBUG_WEATHER) NSLog(@"SunSet: %@ UHR", [formatter stringFromDate:sunset]  );
  
  // Get humidity, pressure temp and condition
  humidity = [NSNumber numberWithInteger:[atmosphere[@"humidity"] integerValue]];
  if (DEBUG_WEATHER) NSLog(@"Humidity: %@",humidity);
  pressure = [NSNumber numberWithDouble:[atmosphere[@"pressure"] doubleValue]];
  if (DEBUG_WEATHER) NSLog(@"Pressure: %@",pressure);
  currentTemp = [NSNumber numberWithDouble:[currentWeather[@"temp"] doubleValue]];
  if (DEBUG_WEATHER) NSLog(@"Temp: %@",currentTemp);
  currentCondition = [NSNumber numberWithDouble:[currentWeather[@"code"] doubleValue]];
  if (DEBUG_WEATHER) NSLog(@"Cond: %@",currentCondition);
  
  // Get location data
  locationCity = theLocation[@"city"];
  if (DEBUG_WEATHER) NSLog(@"city: %@",locationCity);
  locationCountry = theLocation[@"country"];
  if (DEBUG_WEATHER) NSLog(@"country: %@",locationCountry);
  locationRegion = theLocation[@"region"];
  if (DEBUG_WEATHER) NSLog(@"region: %@",locationRegion);
  
  // Get wind data
  currentWindSpeed = currentWind[@"speed"];
  if (DEBUG_WEATHER) NSLog(@"WindSpeed: %@",currentWindSpeed);
  currentWindDirection = currentWind[@"direction"];
  if (DEBUG_WEATHER) NSLog(@"Winddirection: %@",currentWindDirection);
  
  // Get units
  unitPressure = units[@"pressure"];
  if (DEBUG_WEATHER) NSLog(@"Unit Presure: %@",unitPressure);
  unitTemp = units[@"temperature"];
  if (DEBUG_WEATHER) NSLog(@"Unit temp: %@",unitTemp);
  unitSpeed = units[@"speed"];
  if (DEBUG_WEATHER) NSLog(@"Unit speed: %@",unitSpeed);
  
  
  // Get update time
  NSString *currentDate = currentWeather[@"date"];
  NSArray *array = [[NSArray alloc] init];
  array= [currentDate componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  //Tue, 04 Mar 2014 11:00 am/pm +TIMEZONE
  //day = index 1, month = 2, year = 3, time = 4, timePosix = 5, Timezone = 6
  if ([array count] > 5) {
    NSString *ttimePosix = [array objectAtIndex:5];
    NSString *ttime = [array objectAtIndex:4];
    NSString *yyear = [array objectAtIndex:3];
    NSString *mmonth = [array objectAtIndex:2];
    NSString *dday = [array objectAtIndex:1];
    NSDateFormatter *dateFormatterGMTAware = [[NSDateFormatter alloc] init];
    [dateFormatterGMTAware setDateFormat:@"yyyy-MMM-dd-hh:mm-a"];
    NSString *dateString = [NSString stringWithFormat:@"%@-%@-%@-%@-%@",yyear,mmonth,dday, ttime, ttimePosix];
    if (![lastUpdate isEqualToDate:[dateFormatterGMTAware dateFromString:dateString]]) {
      if (DEBUG_WEATHER) NSLog(@"new weather data");
      // Post notification
      [[NSNotificationCenter defaultCenter] postNotificationName:WeatherNewWeatherAvailable object:self];
    }
    lastUpdate = [dateFormatterGMTAware dateFromString:dateString];
  }
  formatter.locale = [NSLocale currentLocale];
  [formatter setDateFormat:@"EEE dd MMM yyy HH:mm"];
  if (DEBUG_WEATHER) NSLog(@"Date: %@",[formatter stringFromDate:lastUpdate]);
  
  
}

/*
 * Returns an image corresponding to the given weather conditions
 */
-(NSImage*)imageFromCondition:(NSInteger)condition {
  NSImage *image = [[NSImage alloc] init];
  if (condition <= 4) {
    image = [NSImage imageNamed:IMAGE_THUNDER];
  } else if (condition <= 12) {
    image = [NSImage imageNamed:IMAGE_RAIN];
  } else if (condition <= 16) {
    image = [NSImage imageNamed:IMAGE_SNOW];
  } else if (condition <= 22) {
    image = [NSImage imageNamed:IMAGE_FOG];
  } else if (condition <= 25) {
    image = [NSImage imageNamed:IMAGE_WINDY];
  } else if (condition <= 28) {
    image = [NSImage imageNamed:IMAGE_CLOUDS];
  } else if (condition <= 29) {
    image = [NSImage imageNamed:IMAGE_CLOUDY_NIGHT];
  } else if (condition <= 30) {
    image = [NSImage imageNamed:IMAGE_CLOUDY];
  } else if (condition <= 31) {
    image = [NSImage imageNamed:IMAGE_CLEAR];
  } else if (condition <= 32) {
    image = [NSImage imageNamed:IMAGE_SUNNY];
  } else if (condition <= 33) {
    image = [NSImage imageNamed:IMAGE_CLOUDY_NIGHT];
  } else if (condition <= 34) {
    image = [NSImage imageNamed:IMAGE_CLOUDY];
  } else if (condition <= 35) {
    image = [NSImage imageNamed:IMAGE_RAIN];
  } else if (condition <= 36) {
    image = [NSImage imageNamed:IMAGE_SUNNY];
  } else if (condition <= 39) {
    image = [NSImage imageNamed:IMAGE_THUNDER];
  } else if (condition <= 40) {
    image = [NSImage imageNamed:IMAGE_RAIN];
  } else if (condition <= 43) {
    image = [NSImage imageNamed:IMAGE_SNOW];
  } else if (condition <= 44) {
    image = [NSImage imageNamed:IMAGE_CLOUDY];
  } else if (condition <= 45) {
    image = [NSImage imageNamed:IMAGE_THUNDER];
  } else if (condition <= 46) {
    image = [NSImage imageNamed:IMAGE_SNOW];
  } else {
    image = [NSImage imageNamed:IMAGE_THUNDER];
  }
  return image;
}



#pragma mark voice command functions
/*
 * Retunr the viewcontroller for this class
 */
-(NSViewController*) deviceView {
  return [[WeatherViewController alloc] init];
}

/*
 * Returns the weather for today.
 */
-(NSDictionary*)todayWeather {
  // Create response strings
  NSString *responseString = [NSString stringWithFormat:VOICE_RESPONS_GET_WEATHER, VOICE_RESPONS_GET_TODAY];
  NSString *responseStringReadable = [NSString stringWithFormat:VOICE_RESPONS_GET_WEATHER, VOICE_RESPONS_GET_TODAY];
  // Append the date to the information
  NSDateFormatter *df = [[NSDateFormatter alloc] init];
  [df setLocale:[NSLocale currentLocale]];
  [df setDateFormat:@"dd.MM."];
  responseString = [NSString stringWithFormat:@"%@%@: ", responseString, [df stringFromDate:[NSDate date]]];
  // Append date readable
  StringToSpeechFormatter *speechFormatter = [StringToSpeechFormatter sharedSpeechFormatter];
  responseStringReadable = [NSString stringWithFormat:@"%@%@:\n", responseStringReadable, [speechFormatter dateInWords:[NSDate date] :NSCalendarUnitMonth|NSCalendarUnitDay]];
  
  // If current condition exist append them, else append condition not available
  if (allConditions[[currentCondition integerValue]]) {
    responseString = [NSString stringWithFormat:@"%@%@", responseString, allConditions[[currentCondition integerValue]]];
    responseStringReadable = [NSString stringWithFormat:@"%@%@", responseStringReadable, allConditions[[currentCondition integerValue]]];
  } else {
    responseString = [NSString stringWithFormat:@"%@%@", responseString, CONDITIONS_NOT_AVAILABLE_STRING];
    responseStringReadable = [NSString stringWithFormat:@"%@%@", responseStringReadable, CONDITIONS_NOT_AVAILABLE_STRING];
  }
  // Append current temperature readable
  if (currentTemp) {
    responseString = [NSString stringWithFormat:@"%@, %.1f°C", responseString, [currentTemp doubleValue]];
    StringToSpeechFormatter *speechFormatter = [StringToSpeechFormatter sharedSpeechFormatter];
    responseStringReadable = [NSString stringWithFormat:@"%@, %@", responseStringReadable,
                              [speechFormatter temperatureInWords:[currentTemp doubleValue]]];
  }
  
  responseString = [NSString stringWithFormat:@"%@.", responseString];
  responseStringReadable = [NSString stringWithFormat:@"%@.", responseStringReadable];
  // Create response dict and return
  NSMutableDictionary *responseDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                       responseString, KeyVoiceCommandResponseString,
                                       responseStringReadable, KeyVoiceCommandResponseSpeechString,
                                       [NSNumber numberWithBool:true], KeyVoiceCommandExecutedSuccessfully , nil];
  return responseDict;
}


/*
 * Returns the weather for tomorrow.
 */
-(NSDictionary*)tomorrowWeather {
  // Create response strings
  NSString *responseString = [NSString stringWithFormat:VOICE_RESPONS_GET_WEATHER, VOICE_RESPONS_GET_TOMORROW];
  NSString *responseStringReadable = [NSString stringWithFormat:VOICE_RESPONS_GET_WEATHER, VOICE_RESPONS_GET_TOMORROW];
  // Append the date to the information
  NSDateFormatter *df = [[NSDateFormatter alloc] init];
  [df setLocale:[NSLocale currentLocale]];
  [df setDateFormat:@"dd.MM"];
  
  // Get date of tomorrow
  NSDateComponents *components = [[NSDateComponents alloc] init];
  [components setDay:1];
  // create a calendar
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSDate *tomorrow = [gregorian dateByAddingComponents:components toDate:[NSDate date] options:0];
  responseString = [NSString stringWithFormat:@"%@%@: ", responseString, [df stringFromDate:tomorrow]];
  
  // Append date readable
  StringToSpeechFormatter *speechFormatter = [StringToSpeechFormatter sharedSpeechFormatter];
  responseStringReadable = [NSString stringWithFormat:@"%@%@:\n", responseStringReadable, [speechFormatter dateInWords:tomorrow :NSCalendarUnitMonth|NSCalendarUnitDay]];
  // Get first object of forecast
  NSDictionary *tomorrowForecast = nil;
  for(NSDictionary *theForecast in forecast) {
    tomorrowForecast = theForecast;
    break;
  }
  // If it is non nil start adding informations
  if (tomorrowForecast) {
    // Append condition
    if (allConditions[[tomorrowForecast[@"code"] integerValue]]) {
      responseString = [NSString stringWithFormat:@"%@%@", responseString, allConditions[[tomorrowForecast[@"code"] integerValue]]];
      responseStringReadable = [NSString stringWithFormat:@"%@%@", responseStringReadable, allConditions[[tomorrowForecast[@"code"] integerValue]]];
    } else {
      responseString = [NSString stringWithFormat:@"%@%@", responseString, CONDITIONS_NOT_AVAILABLE_STRING];
      responseStringReadable = [NSString stringWithFormat:@"%@%@", responseStringReadable, CONDITIONS_NOT_AVAILABLE_STRING];
    }
    // Append high and low values
    if (tomorrowForecast[@"high"] && tomorrowForecast[@"low"]) {
      responseString = [NSString stringWithFormat:@"%@, High: %li°C, Low: %li°C", responseString, [tomorrowForecast[@"high"] integerValue],
                        [tomorrowForecast[@"low"] integerValue]];
      // Append the temperatures readable for the spoken string
      StringToSpeechFormatter *speechFormatter = [StringToSpeechFormatter sharedSpeechFormatter];
      responseStringReadable = [NSString stringWithFormat:@"%@, the heigh will be %@, the low will be %@",
                                responseStringReadable, [speechFormatter temperatureInWords:[tomorrowForecast[@"high"] doubleValue]],
                                [speechFormatter temperatureInWords:[tomorrowForecast[@"low"] doubleValue]]];
    }
  // If no information is available, display this
  } else {
    responseString = [NSString stringWithFormat:@"%@%@", responseString, CONDITIONS_NOT_AVAILABLE_STRING];
  }
  responseString = [NSString stringWithFormat:@"%@.", responseString];
  responseStringReadable = [NSString stringWithFormat:@"%@.", responseStringReadable];
  
  // Create return dictionary and return it
  NSMutableDictionary *responseDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                       responseString, KeyVoiceCommandResponseString,
                                       responseStringReadable, KeyVoiceCommandResponseSpeechString,
                                       [NSNumber numberWithBool:true], KeyVoiceCommandExecutedSuccessfully , nil];
  return responseDict;
}

/*
 * Returns the weather forecast.
 */
-(NSDictionary*)forecastWeather {
  // Create response string
  NSString *responseString = [NSString stringWithFormat:VOICE_RESPONS_GET_WEATHER_WEEK];
  // Create return dictionary with forecast view and return
  NSMutableDictionary *responseDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                       responseString, KeyVoiceCommandResponseString,
                                       [self deviceView], KeyVoiceCommandResponseViewController,
                                       [NSNumber numberWithBool:true], KeyVoiceCommandExecutedSuccessfully , nil];
  return responseDict;
}



/*
 * Returns the standard voice commands of the device.
 */
-(NSArray *)standardVoiceCommands {
  VoiceCommand *todayEvents = [[VoiceCommand alloc] init];
  [todayEvents setName:VOICE_COMMAND_GET_TODAY_WEATHER];
  [todayEvents setCommand:VOICE_COMMAND_GET_TODAY_WEATHER];
  [todayEvents setSelector:@"todayWeather"];
  //[todayEvents setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_TODAY_EVENTS, nil]];
  NSArray *commands = [[NSArray alloc] initWithObjects:todayEvents, nil];
  return commands;
}

/*
 * Return the available selectors for voice commands.
 */
-(NSArray *)voiceCommandSelectors {
  return [[NSArray alloc] initWithObjects:@"todayWeather", @"tomorrowWeather", @"forecastWeather", nil];
}

/*
 * Returns the voice command extensions the device should be sensitive to.
 */
-(NSArray *)voiceCommandSelectorsReadable {
  return [[NSArray alloc] initWithObjects:@"Weather today", @"Weather tomorrow", @"Weather forecast", nil];
}

/*
 * Executes a given selector on the device.
 */
-(NSDictionary*)executeSelector:(NSString *)selector {
  //[self updateWeather];
  // Look for selector delimiter
  NSRange range = [selector rangeOfString:@":"];
  // If a delimiter is found, the selector has an object attached as string
  if (range.location != NSNotFound) {
    // Get the real selector and the object
    NSString *realSelector = [selector substringToIndex:range.location + range.length];
    NSString *object = @"";
    if ([selector length] > range.length + range.location) {
      object = [selector substringFromIndex:range.location + range.length];
    }
    // If the Device does not respond to the selector, return error
    if (![self respondsToSelector:NSSelectorFromString(realSelector)]) {
      return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:false], KeyVoiceCommandExecutedSuccessfully, nil];
    }
    // If the device responds to selector, perform it and store result in dictionary and return it
    NSDictionary *result = [self performSelector:NSSelectorFromString(realSelector) withObject:object];
    return result;
  }
  // No object is attached
  // If the Device does not respond to the selector, return error
  if (![self respondsToSelector:NSSelectorFromString(selector)]) {
    return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:false], KeyVoiceCommandExecutedSuccessfully, nil];
  }
  // If the device responds to selector, perform it and store result in dictionary and return it
  NSDictionary *result = [self performSelector:NSSelectorFromString(selector) withObject:nil];
  return result;
}


@end
