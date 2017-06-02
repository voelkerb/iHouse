//
//  MainAppGeneralViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 15/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "MainAppGeneralViewController.h"

@interface MainAppGeneralViewController ()

@end

@implementation MainAppGeneralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  // Do view setup here.
  
  viewArray = [[NSMutableArray alloc] init];
  
  // Insert Dummy objects
  WeatherView *weatherView = [[WeatherView alloc] init];
  TemperatureView *tempView = [[TemperatureView alloc] init];
  NSString *weatherRect = NSStringFromRect(NSMakeRect(0, 0, 200, 200));
  NSString *tempRect = NSStringFromRect(NSMakeRect(300, 0, 200, 200));
  NSDictionary *obj = @{@"view" : weatherView,
                        @"name" : @"weather",
                        @"rect" : weatherRect};
  [viewArray addObject:obj];
  obj = @{@"view" : tempView,
          @"name" : @"temp",
          @"rect" : tempRect};
  [viewArray addObject:obj];
  [self insertAllSubviews];
}

- (void) insertAllSubviews {
  for (NSDictionary *viewDict in viewArray) {
    NSView *theView = [viewDict objectForKey:@"view"];
    NSString *theName = [viewDict objectForKey:@"name"];
    
    
    NSRect theRect = NSRectFromString([viewDict objectForKey:@"rect"]);
    
    NSLog(@"View: %@, Name: %@, Rect: %f, %f, %f, %f", theView, theName, theRect.origin.x, theRect.origin.y, theRect.size.width, theRect.size.height);
    [theView setFrame:theRect];
    [self.view addSubview:theView];
  }
  
}

@end
