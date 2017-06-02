//
//  WeatherForecastDayView.m
//  iHouse
//
//  Created by Benjamin Völker on 25/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "WeatherForecastDayView.h"

@interface WeatherForecastDayView ()

@end

@implementation WeatherForecastDayView
@synthesize forecastDay, forecastHigh, forecastLow, forecastImage;

/*
 * Sets all outlets. Must be called after viewDidLoad!
 */
-(void)setDay:(NSString *)theDay lowTemp:(NSString *)theLowTemp highTemp:(NSString *)highTemp image:(NSImage *)image {
  [forecastDay setStringValue:theDay];
  [forecastHigh setStringValue:highTemp];
  [forecastLow setStringValue:theLowTemp];
  [forecastImage setImage:image];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
