//
//  CalendarDayViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 26/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CalendarDayViewController;

// The Functions the delegate has to implement
@protocol CalendarDayViewControllerDelegate <NSObject>

// The delegate needs to do something on press
- (void)dayPressed:(CalendarDayViewController*)dayViewController;

@end


@interface CalendarDayViewController : NSViewController {
  BOOL event;
}

@property (weak) id<CalendarDayViewControllerDelegate> delegate;

// The date of this day
@property (strong) NSDate *date;
// The day label
@property (weak) IBOutlet NSTextField *dayLabel;
// A dot is displayed if an event is or was on this day
@property (weak) IBOutlet NSTextField *dotLabel;
// The complete view is a button
@property (weak) IBOutlet NSButton *button;

// Init this dayview with date and flag for event
-(id)initWithDay:(NSDate*)day hasEvent:(BOOL)hasEvent;

// Marks the day with the given color
- (void)markDay:(NSColor*)markColor;

// Function if the user presses this day
- (IBAction)dayPressed:(id)sender;

@end
