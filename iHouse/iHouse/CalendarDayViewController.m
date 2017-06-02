//
//  CalendarDayViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 26/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "CalendarDayViewController.h"

@interface CalendarDayViewController ()

@end

@implementation CalendarDayViewController
@synthesize date, button, dayLabel, dotLabel, delegate;

/*
 * If not inited correctly init with current date and no event.
 */
-(id) init {
  return [self initWithDay:[NSDate date] hasEvent:false];
}

/*
 * Init correctly with day and flag for event.
 */
-(id)initWithDay:(NSDate *)day hasEvent:(BOOL)hasEvent {
  if (self = [super init]) {
    date = day;
    event = hasEvent;
  }
  return self;
}

- (void)viewDidLoad {
  // If has event set the button to enabled and the flaglabel with a dot
  if (event) {
    [button setEnabled:YES];
    [dotLabel setStringValue:@"⚉"];
  // Else disable button and set empty text
  } else {
    [button setEnabled:NO];
    [dotLabel setStringValue:@""];
  }
  
  // Get only the date of this day and set the daylabel
  NSCalendar* calendar = [NSCalendar currentCalendar];
  NSDateComponents* components = [calendar components:NSCalendarUnitDay fromDate:date];
  [dayLabel setStringValue:[NSString stringWithFormat:@"%li", [components day]]];
  
  [super viewDidLoad];
  // Do view setup here.
}

/*
 * Marks the day with the given color by setting the views bg color.
 */
-(void)markDay:(NSColor *)markColor {
  CALayer *layer = [[CALayer alloc] init];
  [layer setBackgroundColor:[markColor CGColor]];
  [self.view setWantsLayer:YES];
  [self.view setLayer:layer];
}

/*
 * If the day was pressed, the delegate can do sth.
 */
- (IBAction)dayPressed:(id)sender {
  [delegate dayPressed:self];
}
@end
