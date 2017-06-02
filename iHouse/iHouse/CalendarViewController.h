//
//  CalendarViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 16/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Calendar.h"
#import "NSFlippedView.h"
#import "CalendarDayViewController.h"
#import <EventKit/EventKit.h>

@interface CalendarViewController : NSViewController <NSCopying, NSTableViewDataSource, NSTableViewDelegate, CalendarDayViewControllerDelegate> {
  NSColor *bgColor;
  NSMutableArray *dayViewControllers;
}

@property (strong) Calendar *calendar;

// The Sidebar with the list of calendar events
@property (weak) IBOutlet NSTableView *sideBarTableView;
@property (strong) NSColor *bgColor;
@property (strong) NSMutableArray *dayViewControllers;
// The view displaying all weekDays (Mo.-Su.)
@property (weak) IBOutlet NSView *weekDayView;
// The month calendar view displaying all days this month
@property (weak) IBOutlet NSFlippedView *monthCalendarView;
// The textfield diplaying current month
@property (weak) IBOutlet NSTextField *currentMonthLabel;
// The textview displaying the selected event from tableview
@property (unsafe_unretained) IBOutlet NSTextView *selecteEventTextView;
// Seperator lines
@property (weak) IBOutlet NSView *seperator1;
@property (weak) IBOutlet NSView *seperator2;
@property (weak) IBOutlet NSView *seperator3;
@property (weak) IBOutlet NSView *seperator4;

// Init this viewcontroller with a bg color
- (id)initWithBgColor:(NSColor *)theBGColor;

@end
