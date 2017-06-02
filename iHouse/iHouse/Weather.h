//
//  Weather.h
//  iHouse
//
//  Created by Benjamin Völker on 26/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "YQL.h"
#import <CoreLocation/CoreLocation.h>


// New weather available
extern NSString * const WeatherNewWeatherAvailable;

@interface Weather : NSObject<NSCoding> {
  // The Yahoo weather getter object
  YQL *yql;
@public
  bool hasInternet;
}

// The name of the calendar
@property (strong) NSString *name;
// Location of the weather
@property (strong) CLLocation* location;
// Last update time
@property (strong) NSDate* lastUpdate;
// Time of sunrise
@property (strong) NSDate* sunrise;
// Time of sunset
@property (strong) NSDate* sunset;
// Humidity level
@property (strong) NSNumber *humidity;
// Pressure level
@property (strong) NSNumber *pressure;
// Current temperature
@property (strong) NSNumber *currentTemp;
// The current condition (rainy, cloudy, etc.)
@property (strong) NSNumber *currentCondition;
// Current wind direction degrees north
@property (strong) NSNumber *currentWindDirection;
// Current wind speed in km/h
@property (strong) NSNumber *currentWindSpeed;
// Location City as string
@property (strong) NSString *locationCity;
// Location country as string
@property (strong) NSString *locationCountry;
// Location region (state)
@property (strong) NSString *locationRegion;
// The unit of the air pressure
@property (strong) NSString *unitPressure;
// The unit of speed
@property (strong) NSString *unitSpeed;
// The unit of the temperature
@property (strong) NSString *unitTemp;
// Forecast for 5 days in dictionary
@property (strong) NSDictionary *forecast;
// All conditions as string allConditions[currentCondition] will get the condition as string
@property (strong) NSArray *allConditions;
// All week days as string in dictionary, called e.g. [allWeekDays objectForKey:@"Mon"];
@property (strong) NSDictionary *allWeekDays;

// This class is singletone
+ (id)sharedWeather;

// Get an image of the current weather conditions
-(NSImage*)imageFromCondition:(NSInteger)condition;


// Return the viewcontroller of this class
- (NSViewController*)deviceView;
// Return the standard voice commands
- (NSArray*)standardVoiceCommands;
// Return the available selectors for voice commands
- (NSArray*)voiceCommandSelectors;
// Return the available voice actions
- (NSArray*)voiceCommandSelectorsReadable;
// Executes a given selector
-(NSDictionary*)executeSelector:(NSString*)selector;
@end
