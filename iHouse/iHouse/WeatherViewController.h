//
//  WeatherViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 16/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "YQL.h"
#import <CoreLocation/CoreLocation.h>
#import "WeatherForecastDayView.h"
#import "NSFlippedView.h"
#import "Weather.h"

@interface WeatherViewController : NSViewController<CLLocationManagerDelegate, NSCopying> {
  NSColor *bgColor;
  CLLocationManager *locationManager;
}

// Weather object
@property (strong) Weather* weather;

// Current weather image
@property (weak) IBOutlet NSImageView *currentWeatherImage;

// Sunset and sunrise label
@property (weak) IBOutlet NSTextField *sunsetLabel;
@property (weak) IBOutlet NSTextField *sunriseLabel;

// Seperator (white line between current and forecast)
@property (weak) IBOutlet NSView *seperator;
// Current location label
@property (weak) IBOutlet NSTextField *currentLocationLabel;
// Current condition label
@property (weak) IBOutlet NSTextField *currentConditionLabel;
// Current temperature label
@property (weak) IBOutlet NSTextField *currentTempLabel;
// Forecast view containing all forecasts for the available days
@property (weak) IBOutlet NSFlippedView *forecastView;

// Init this view with the given bg color
- (id)initWithBgColor:(NSColor *)theBGColor;

@end
