//
//  WeatherForecastDayView.h
//  iHouse
//
//  Created by Benjamin Völker on 25/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WeatherForecastDayView : NSViewController

// The weekDay of the forecast
@property (weak) IBOutlet NSTextField *forecastDay;
// The forecast image
@property (weak) IBOutlet NSImageView *forecastImage;
// The forecast low temperature of the day
@property (weak) IBOutlet NSTextField *forecastLow;
// The forecast heigh temperature of the day
@property (weak) IBOutlet NSTextField *forecastHigh;

// Set the variables properly
-(void)setDay:(NSString*)theDay lowTemp:(NSString*)theLowTemp highTemp:(NSString*)highTemp image:(NSImage*)image;

@end
