//
//  WeatherViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 16/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "WeatherViewController.h"
#define DEBUG_WEATHER_VIEW 0
// The maximum days of forecast to display
#define MAX_FORECAST_DAYS 7

// If the current condition is not available
#define CONDITIONS_NOT_AVAILABLE_STRING @"Not available"
#define CONDITIONS_NOT_AVAILABLE_INTERNET_STRING @"Internet Connection not available"

// String Prefix for sunrise and sunset
#define SUNRISE_STRING @"Sunrise: "
#define SUNSET_STRING @"Sunset: "

@interface WeatherViewController ()

@end

@implementation WeatherViewController
@synthesize currentConditionLabel, currentLocationLabel, currentTempLabel;
@synthesize forecastView, seperator, sunriseLabel, sunsetLabel, currentWeatherImage;
@synthesize weather;

// If not called with BG color
- (id)init {
  return [self initWithBgColor:[NSColor clearColor]];
}

// If called with BG color
- (id)initWithBgColor:(NSColor *)theBGColor {
  self = [super init];
  
  if (self) {
    // Init all variables
    bgColor = theBGColor;
    
    // Init the location manager
    [self initLocationManager];
    
    // Get the weather variable
    weather = [Weather sharedWeather];
    
    
    // Get observer for new weather data
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(weatherDataChanged:) name:WeatherNewWeatherAvailable object:nil];
  }
  
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Set The bgColor
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[bgColor CGColor]];
  [self.view setWantsLayer:YES];
  [self.view setLayer:viewLayer];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    
  // Init the location manager
  [self initView];
}

/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  WeatherViewController *copy = [[WeatherViewController allocWithZone: zone] init];
  return copy;
}

/*
 * Inits the view to the standard strings because currently no weather data is available.
 */
-(void)initView {
  
  // Set The bgColor
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[[NSColor whiteColor] CGColor]];
  [seperator setWantsLayer:YES];
  [seperator setLayer:viewLayer];
  
  // Update view
  [self updateView];
}

/*
 * If weather changed (called from notification) we should switch to the main thread to update the view.
 */
-(void)weatherDataChanged:(NSNotification*)notification {
    if ([[notification object] isEqualTo:weather]) {
      if (DEBUG_WEATHER_VIEW) NSLog(@"Weather changed");
      dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
          // Do this in main queue to prevent crashes due to autolayout
          [self updateView];
        }
      });
    }
  }

/*
 * Updates the weather view, whenever new data is available.
 */
-(void)updateView {
  if (!weather->hasInternet) {
    [currentConditionLabel setStringValue:CONDITIONS_NOT_AVAILABLE_INTERNET_STRING];
    return;
  }
  // Look if current condition exist
  if ([weather currentCondition]) {
    // If it is no known condition, set label to condition not available
    if ([[weather currentCondition] intValue] >= [[weather allConditions] count]) {
      [currentConditionLabel setStringValue:CONDITIONS_NOT_AVAILABLE_STRING];
    // If condition is known set condition and update the weather icon
    } else {
      [currentConditionLabel setStringValue:[[weather allConditions] objectAtIndex:
                                             [[weather currentCondition] integerValue]]];
      [currentWeatherImage setAutoresizingMask:NSViewNotSizable];
      [currentWeatherImage setImage:[weather imageFromCondition:[[weather currentCondition] integerValue]]];
    }
  } else {
    [currentWeatherImage setImage:nil];
    [currentConditionLabel setStringValue:@""];
  }
  // If location City and temperature are available set the labels
  if ([weather locationCity]) {
    [currentLocationLabel setStringValue:[weather locationCity]];
  } else {
    [currentLocationLabel setStringValue:@"---"];
  }
  if ([weather currentTemp]) {
    [currentTempLabel setStringValue:[NSString stringWithFormat:@"%.1f°", [[weather currentTemp] doubleValue]]];
  } else {
    [currentTempLabel setStringValue:@""];
  }
  
  // Set the sunset and surise label in format Hour:Minute 24h format
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.locale = [NSLocale currentLocale];
  [formatter setDateFormat:@"H:mm"];
  if ([weather sunset]) {
    [sunsetLabel setStringValue:[NSString stringWithFormat:@"%@%@", SUNSET_STRING,
                                                     [formatter stringFromDate:[weather sunset]]]];
  } else {
    [sunsetLabel setStringValue:@""];
  }
  if ([weather sunrise]) {
    [sunriseLabel setStringValue:[NSString stringWithFormat:@"%@%@", SUNRISE_STRING,
                                                       [formatter stringFromDate:[weather sunrise]]]];
  } else {
    [sunriseLabel setStringValue:@""];
  }
  // Remove previous forecasts
  NSArray *subviews = [[NSArray alloc] initWithArray:[forecastView subviews]];
  for (NSView *subview in subviews) [subview removeFromSuperview];
  // If no weather forecast available return
  if (![weather forecast]) return;
  // Get the number of forecast days to display which is either the available number of days or a maximum
  NSInteger forecastMax = [[weather forecast] count];
  if (forecastMax > MAX_FORECAST_DAYS) forecastMax = MAX_FORECAST_DAYS;
  // Update forecast
  NSRect frame = NSMakeRect(0, 0, self.view.frame.size.width/forecastMax, 0);
  int forecastCount = 0;
  // Go through existing forecasts
  for (NSDictionary *theForecast in [weather forecast]) {
    // Make view for one day
    WeatherForecastDayView *dayView = [[WeatherForecastDayView alloc] init];
    // Set the height
    frame.size.height = dayView.view.frame.size.height;
    // Set the frame
    [dayView.view setFrame:frame];
    // Add to subviews
    [forecastView addSubview:dayView.view];
    // Set all parameters
    [dayView setDay:[[weather allWeekDays] objectForKey:theForecast[@"day"]]
            lowTemp:[NSString stringWithFormat:@"%@", theForecast[@"low"]]
           highTemp:[NSString stringWithFormat:@"%@", theForecast[@"high"]]
              image:[weather imageFromCondition:[theForecast[@"code"] integerValue]]];
    // Increment frame
    frame.origin.x += frame.size.width;
    if (DEBUG_WEATHER_VIEW) NSLog(@"%@", theForecast);
    forecastCount++;
    if (forecastCount > forecastMax) break;
  }
}

/*
 * Inits the location manager. Sets the delegate to us and the accuracy
 */
-(void)initLocationManager {
  // Init location manager
  locationManager = [[CLLocationManager alloc] init];
  locationManager.distanceFilter = kCLDistanceFilterNone;
  locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
  locationManager.delegate = self;
  // Start location tracking
  [locationManager startUpdatingLocation];
  if (DEBUG_WEATHER_VIEW) NSLog(@"Location: %f, %f", locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude);
}

/*
 * Update weather if location changes.
 */
-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
  // Get new location distance
  CLLocationDistance distance = [newLocation distanceFromLocation:oldLocation];
  if (DEBUG_WEATHER_VIEW) NSLog(@"Distance: %f", distance);
  // Set new location
  [weather setLocation:newLocation];
}

/*
 * Get the current location.
 */
-(CLLocationCoordinate2D) getLocation {
  CLLocation *location = [locationManager location];
  CLLocationCoordinate2D coordinate = [location coordinate];
  return coordinate;
}

@end
