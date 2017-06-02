//
//  CalendarViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 16/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "CalendarViewController.h"
#define DEBUG_CALENDAR_VIEW false
@interface CalendarViewController ()

@end

@implementation CalendarViewController
@synthesize sideBarTableView, calendar, weekDayView, monthCalendarView, currentMonthLabel;
@synthesize selecteEventTextView, seperator1, seperator2, seperator3, seperator4, bgColor;
@synthesize dayViewControllers;

/*
 * If called without bg color, init properly with bg color.
 */
-(id)init {
  return [self initWithBgColor:[NSColor clearColor]];
}


/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  CalendarViewController *copy = [[CalendarViewController allocWithZone: zone] init];
  copy.bgColor = bgColor;
  copy.calendar = calendar;
  copy.dayViewControllers = dayViewControllers;
  return copy;
}

/*
 * Class inited with bg color.
 */
- (id)initWithBgColor:(NSColor *)theBGColor {
  self = [super init];
  if (self) {
    // Store bgcolor for further processing
    bgColor = theBGColor;
    // Get calendar object
    calendar = [Calendar sharedCalendar];
    // Init members
    dayViewControllers = [[NSMutableArray alloc] init];
    
    // Get observer for new calendar data
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calendarChanged:) name:CalendarNewCalendarDataAvailable object:nil];
  }
  return self;
}

/*
 * Called if the calendar has new date. The update is than done in the main queue to prevent crashes.
 */
- (void)calendarChanged:(NSNotification*)notification {
  if ([[notification object] isEqualTo:calendar]) {
    if (DEBUG_CALENDAR_VIEW) NSLog(@"Calendar changed");
    dispatch_async(dispatch_get_main_queue(), ^{
      @autoreleasepool {
        // Do this in main queue to prevent crashes due to autolayout
        // The tableview needs to be updated
        [sideBarTableView reloadData];
        // The view also maybe for new events and new month
        [self updateView];
      }
    });
  }
}


- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)viewDidAppear {
  [super viewDidAppear];

  // Set the BG Color
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[bgColor CGColor]];
  [self.view setWantsLayer:YES];
  [self.view setLayer:viewLayer];
  
  // Set all views to autoresize
  [self.view setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [self.weekDayView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [self.monthCalendarView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  
  // Set seperaor to white color
  CALayer *seperatorLayer1 = [CALayer layer];
  [seperatorLayer1 setBackgroundColor:[[NSColor whiteColor] CGColor]];
  CALayer *seperatorLayer2 = [CALayer layer];
  [seperatorLayer2 setBackgroundColor:[[NSColor whiteColor] CGColor]];
  CALayer *seperatorLayer3 = [CALayer layer];
  [seperatorLayer3 setBackgroundColor:[[NSColor whiteColor] CGColor]];
  CALayer *seperatorLayer4 = [CALayer layer];
  [seperatorLayer4 setBackgroundColor:[[NSColor whiteColor] CGColor]];
  [seperator1 setWantsLayer:YES];
  [seperator1 setLayer:seperatorLayer1];
  [seperator2 setWantsLayer:YES];
  [seperator2 setLayer:seperatorLayer2];
  [seperator3 setWantsLayer:YES];
  [seperator3 setLayer:seperatorLayer3];
  [seperator4 setWantsLayer:YES];
  [seperator4 setLayer:seperatorLayer4];
  
  // Set label of selected event to none
  NSString *paragraph = @"";
  NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:0];
  NSAttributedString *as = [[NSAttributedString alloc] initWithString:paragraph attributes:attributes];
  [[selecteEventTextView textStorage] appendAttributedString:as];

  
  // Remove all weekdays if ther eexist any
  NSArray *subviews = [[NSArray alloc] initWithArray:[weekDayView subviews]];
  for (NSView *subview in subviews) [subview removeFromSuperview];
  
  
  // Get the current calendar
  NSCalendar *theCalendar =  [[NSLocale currentLocale] objectForKey:NSLocaleCalendar];
  
  // Frame iterating over
  NSRect frame = NSMakeRect(0, 0, weekDayView.frame.size.width/theCalendar.shortWeekdaySymbols.count,
                            weekDayView.frame.size.height);
  
  
  // Iterate over all weekdays. starting from Monday (thats why there is a -1)
  // And thats why we have twofor loops here (one from Mo. to Sat. one for Sunday
  for (NSInteger i = theCalendar.firstWeekday-1; i < [theCalendar.shortWeekdaySymbols count];  i++) {
    // Get weekdayString and put it inside a nstextview
    NSString *weekDay = [theCalendar.shortWeekdaySymbols objectAtIndex:i];
    // Set the textview to not editable and autoresize, bg color and font accordingly and centered
    NSTextField *theTextView = [[NSTextField alloc] initWithFrame:frame];
    [theTextView setAutoresizingMask:NSViewWidthSizable];
    [theTextView setBordered:NO];
    [theTextView setStringValue:weekDay];
    [theTextView setEditable:NO];
    [theTextView setDrawsBackground:YES];
    [theTextView setBackgroundColor:[NSColor clearColor]];
    [theTextView setLineBreakMode:NSLineBreakByWordWrapping];
    [theTextView setFont:[NSFont fontWithName:@"HelveticaNeue-Thin" size:15]];
    [theTextView setAlignment:NSTextAlignmentCenter];
    // Add to the weekview
    [weekDayView addSubview:theTextView];
    frame.origin.x += frame.size.width;
  }
  for (NSInteger i = 0; i < theCalendar.firstWeekday - 1;  i++) {
    // Get weekdayString and put it inside a nstextview
    NSString *weekDay = [theCalendar.shortWeekdaySymbols objectAtIndex:i];
    // Set the textview to not editable and autoresize, bg color and font accordingly and centered
    NSTextField *theTextView = [[NSTextField alloc] initWithFrame:frame];
    [theTextView setAutoresizingMask:NSViewWidthSizable];
    [theTextView setBordered:NO];
    [theTextView setStringValue:weekDay];
    [theTextView setEditable:NO];
    [theTextView setDrawsBackground:YES];
    [theTextView setBackgroundColor:[NSColor clearColor]];
    [theTextView setLineBreakMode:NSLineBreakByWordWrapping];
    [theTextView setFont:[NSFont fontWithName:@"HelveticaNeue-Thin" size:15]];
    [theTextView setAlignment:NSTextAlignmentCenter];
    [weekDayView addSubview:theTextView];
    frame.origin.x += frame.size.width;
  }
  
  // Set the view
  [self updateView];
}

/*
 * Updates the view to display the current Month.
 */
-(void)updateView {
  // Set the current month label
  NSDate *currentDate = [NSDate date];
  NSDateFormatter *df = [[NSDateFormatter alloc] init];
  [df setLocale:[NSLocale currentLocale]];
  [df setDateFormat:@"MMMM YYYY"];
  [currentMonthLabel setStringValue:[NSString stringWithFormat:@"%@", [df stringFromDate:currentDate]]];
  
  
  // Get the current calendar
  NSCalendar *theCalendar =  [[NSLocale currentLocale] objectForKey:NSLocaleCalendar];
  // The date components should be day month year (no hour minute)
  NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                                 fromDate:[NSDate date]];
  // Set day to 1 to get first day of month
  components.day = 1;
  NSDate *firstDayOfMonthDate = [[NSCalendar currentCalendar] dateFromComponents: components];
 
  // Get start weekday
  NSDateComponents *comps = [theCalendar components:NSCalendarUnitWeekday fromDate:firstDayOfMonthDate];
  // -1 must be added, because firstday starts with 1 not 0
  NSInteger startWeekday = [comps weekday] - (theCalendar.firstWeekday - 1);
  // If the first day is sunday 1-1 will return 0 but must be 7 for sunday
  if (startWeekday == 0) startWeekday = 7;
  if (DEBUG_CALENDAR_VIEW) NSLog(@"Start Date: %li", startWeekday);
  
  // Days of the current month (1-27/28/30/31)
  NSRange days = [theCalendar rangeOfUnit:NSCalendarUnitDay
                         inUnit:NSCalendarUnitMonth
                        forDate:[NSDate date]];
  if (DEBUG_CALENDAR_VIEW) NSLog(@"Month ranges from: %li to %li", days.location, days.length );
  
  // Add flags for year year month day
  unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
  // Get today date without hour minute
  NSDateComponents* todayComp = [theCalendar components:flags fromDate:[NSDate date]];
  NSDate* today = [theCalendar dateFromComponents:todayComp];
  // Remove all views in monthcalendarview and in the viewcontroller array
  [dayViewControllers removeAllObjects];
  NSArray *subviews = [[NSArray alloc] initWithArray:[monthCalendarView subviews]];
  for (NSView *subview in subviews) [subview removeFromSuperview];
  
  // Iterate frame
  NSRect frame = NSMakeRect(0, 0, monthCalendarView.frame.size.width/theCalendar.shortWeekdaySymbols.count, 0);
  // Start from position of startweekday (1-7) -> (0-6)
  frame.origin.x = (startWeekday-1)*monthCalendarView.frame.size.width/theCalendar.shortWeekdaySymbols.count;
  // Start from the first day till the last day
  for (NSInteger day = days.location; day <= days.length; day++) {
    // Set the day ang get its date
    components.day = day;
    NSDate *dayOfMonthDate = [[NSCalendar currentCalendar] dateFromComponents: components];
    // Look through all events if there is a event, if so mark with bool
    BOOL hasEvent = false;
    for (EKEvent *event in [calendar calendarEvents]) {
      // Get the Date of the calendar event
      components = [theCalendar components:flags fromDate:[event startDate]];
      // If the dates are equal this day has an event
      NSDate* dateOnly = [theCalendar dateFromComponents:components];
      if ([dateOnly isEqualToDate:dayOfMonthDate]) {
        hasEvent = true;
      }
    }
    // Init a dayview with date and bool for hasevent
    CalendarDayViewController *dayViewController = [[CalendarDayViewController alloc]
                                                    initWithDay:dayOfMonthDate hasEvent:hasEvent];
    // Set its delegate so we get notified on click
    dayViewController.delegate = self;
    
    // Set height and frame and autorizing mask
    frame.size.height = dayViewController.view.frame.size.height;
    [dayViewController.view setFrame:frame];
    [dayViewController.view setAutoresizingMask:NSViewWidthSizable];
    // Add to viewcontroller array and to the monthview
    [dayViewControllers addObject:dayViewController];
    [monthCalendarView addSubview:dayViewController.view];
    
    // Mark the current day with red color
    if ([today isEqualToDate:dayOfMonthDate]) {
      [dayViewController markDay:[NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.2]];
    }
    // increment x position
    frame.origin.x += dayViewController.view.frame.size.width;
    // if we get beyond bounds, increment y position and reset x position
    if (frame.origin.x >= monthCalendarView.frame.size.width-1) {
      frame.origin.x = 0;
      frame.origin.y += frame.size.height;
    }
  }
}

#pragma mark CalendarDayView delagtes

/*
 * If a day was pressed mark all events on this date and show the first event.
 */
- (void)dayPressed:(CalendarDayViewController *)dayViewController {
  
  // Get the calendar
  NSCalendar *theCalendar =  [[NSLocale currentLocale] objectForKey:NSLocaleCalendar];
  // Falgs for no hour minute
  unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
  // Get an index set
  NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
  // Go through all calendar ebents
  for (NSUInteger i = 0; i < [[calendar calendarEvents] count]; i++) {
    EKEvent *event = [[calendar calendarEvents] objectAtIndex:i];
    // Get date of calendar event
    NSDateComponents* components = [theCalendar components:flags fromDate:[event startDate]];
    NSDate* dateOnly = [theCalendar dateFromComponents:components];
    // If date is equal to the date of the selected day add to index set
    if ([dateOnly isEqualToDate:[dayViewController date]]) {
      [indexSet addIndex:i];
    }
  }
  // Select all indices and scroll to the lastone
  [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
  [sideBarTableView scrollRowToVisible:[indexSet lastIndex]];
  // And set the first one into the eventview
  [self changedSideBarTableToIndex:[indexSet firstIndex]];
  // Get today date without hour minute
  NSDateComponents* todayComp = [theCalendar components:flags fromDate:[NSDate date]];
  NSDate* today = [theCalendar dateFromComponents:todayComp];
  // Mark selected day in blue // others don't mark
  for (CalendarDayViewController *dayController in dayViewControllers) {
    // Mark the current day with red color
    if ([today isEqualToDate:[dayController date]]) {
      [dayController markDay:[NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.2]];
      if (DEBUG_CALENDAR_VIEW) NSLog(@"Found today, mark red");
    // Else no color
    } else {
      [dayController markDay:[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.0]];
    }
  }
  [dayViewController markDay:[NSColor colorWithCalibratedRed:0 green:0 blue:1 alpha:0.2]];
}


/*
 * Action performed by clicking row in sidebar table view
 */
- (IBAction)changedSideBarTable:(id)sender {
  // Changes the eventview to the selecte event
  [self changedSideBarTableToIndex:[sender selectedRow]];
  
  // Highlight the selected day blue in the calendar view
  // Get event
  EKEvent *event = [[calendar calendarEvents] objectAtIndex:[sender selectedRow]];
  // Get the calendar
  NSCalendar *theCalendar =  [[NSLocale currentLocale] objectForKey:NSLocaleCalendar];
  // Falgs for no hour minute
  unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
  // Get today and the day of the event
  NSDateComponents* todayComp = [theCalendar components:flags fromDate:[NSDate date]];
  NSDateComponents* eventComp = [theCalendar components:flags fromDate:[event startDate]];
  NSDate* today = [theCalendar dateFromComponents:todayComp];
  NSDate* eventDate = [theCalendar dateFromComponents:eventComp];
  
  // Mark selected day in blue // others don't mark
  for (CalendarDayViewController *dayController in dayViewControllers) {
    // Mark the current day with red color
    if ([today isEqualToDate:[dayController date]]) {
      [dayController markDay:[NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.2]];
    // Mark the event date in blue
    } else if ([eventDate isEqualToDate:[dayController date]]) {
      [dayController markDay:[NSColor colorWithCalibratedRed:0 green:0 blue:1 alpha:0.2]];
    // Else no color
    } else {
      [dayController markDay:[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.0]];
    }
  }
}

/*
 * Sets all information into the event text view. (Name, calendar, location and time)
 */
- (void)changedSideBarTableToIndex:(NSInteger)index {
  // Text attributes for seperator
  NSMutableDictionary *sepAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
  [sepAttributes setObject:[NSFont fontWithName:@"HelveticaNeue" size:5] forKey:NSFontAttributeName];
  NSAttributedString *seperator = [[NSAttributedString alloc] initWithString:@"  \n"
                                                           attributes:sepAttributes];
  // Text attributes for eventname
  NSMutableDictionary *nameAttributes = [NSMutableDictionary dictionaryWithCapacity:2];
  NSFont *font = [NSFont fontWithName:@"HelveticaNeue-Light" size:18];
  [nameAttributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
  [nameAttributes setObject:font forKey:NSFontAttributeName];
  
  // Text attributes for headlines (Location:, Time:, Calendar:)
  NSMutableDictionary *headlineAttributes = [NSMutableDictionary dictionaryWithCapacity:2];
  font = [NSFont fontWithName:@"HelveticaNeue-Bold" size:13];
  [headlineAttributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
  [headlineAttributes setObject:font forKey:NSFontAttributeName];
  
  // Text attributes for normal text (location, time, calendar)
  NSMutableDictionary *textAttributes = [NSMutableDictionary dictionaryWithCapacity:2];
  font = [NSFont fontWithName:@"HelveticaNeue" size:13];
  [textAttributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
  [textAttributes setObject:font forKey:NSFontAttributeName];
  
  // Clear text view
  [selecteEventTextView.textStorage.mutableString setString:@""];
  
  // Get event
  EKEvent *event = [[calendar calendarEvents] objectAtIndex:index];
  
  // Set event name and append seperator
  NSAttributedString *as = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", [event title]]
                                                           attributes:nameAttributes];
  [[selecteEventTextView textStorage] appendAttributedString:as];
  [[selecteEventTextView textStorage] appendAttributedString:seperator];
  
  // Set Calendar headline
  as = [[NSAttributedString alloc] initWithString:@"Calendar: " attributes:headlineAttributes];
  [[selecteEventTextView textStorage] appendAttributedString:as];
  // Set Calendar and append seperator
  as = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", [[event calendar] title]]
                                       attributes:textAttributes];
  [[selecteEventTextView textStorage] appendAttributedString:as];
  [[selecteEventTextView textStorage] appendAttributedString:seperator];
  
  // Get date string formatted
  NSDateFormatter *df = [[NSDateFormatter alloc] init];
  [df setLocale:[NSLocale currentLocale]];
  [df setDateFormat:@"dd.MM. HH:mm"];
  // Get only the day
  NSDateComponents *componentsStartDay = [[NSCalendar currentCalendar] components:
                                          NSCalendarUnitDay fromDate:[event endDate]];
  NSDateComponents *componentsStopDay = [[NSCalendar currentCalendar] components:
                                          NSCalendarUnitDay fromDate:[event startDate]];
  // Set the date string
  NSString *dateString = [df stringFromDate:[event startDate]];
  // If the event is allday, just print allday
  if ([event isAllDay]) {
    dateString = @"all day";
  // If the event ends on other day print full dates seperated by newline
  } else if ([componentsStartDay day] != [componentsStopDay day]) {
    dateString = [NSString stringWithFormat:@"%@\n%@", dateString, [df stringFromDate:[event endDate]]];
  // If the event ends on startday than just print Day.Month. Hour:Minute-Hour:Minute
  } else {
    [df setDateFormat:@"HH:mm"];
    dateString = [NSString stringWithFormat:@"%@-%@", dateString, [df stringFromDate:[event endDate]]];
  }
  
  // Set time headline
  as = [[NSAttributedString alloc] initWithString:@"Time: " attributes:headlineAttributes];
  [[selecteEventTextView textStorage] appendAttributedString:as];
  // Set time and append seperator
  as = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", dateString]
                                       attributes:textAttributes];
  [[selecteEventTextView textStorage] appendAttributedString:as];
  [[selecteEventTextView textStorage] appendAttributedString:seperator];
  
  // If a location exist print it
  if ([event location]) {
    // Set location headline
    as = [[NSAttributedString alloc] initWithString:@"Location: " attributes:headlineAttributes];
    [[selecteEventTextView textStorage] appendAttributedString:as];
    // Set location
    as = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", [event location]]
                                         attributes:textAttributes];
    [[selecteEventTextView textStorage] appendAttributedString:as];
  }
}


#pragma TableView delegate methods

/*
 * Telling tableviews how many rows we have
 */
- (NSInteger)numberOfRowsInTableView:(nonnull NSTableView *)tableView {
  // Look for the selected filter
  return [[calendar calendarEvents] count];
}


/*
 * Fill information into table cell
 */
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  // Get the object inside the row
  EKEvent *event = [calendar calendarEvents][row];
  // Get the identifier of the table column (we have only 1 so basicly useless)
  NSString *identifier = [tableColumn identifier];
  // Compare if we are in right column
  if ([identifier isEqualToString:@"MainCell"]) {
    // Create the cell View and paste image and name into it
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
    // Set the day of the month together with the tile in the tableview
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:[NSLocale currentLocale]];
    [df setDateFormat:@"dd."];
    NSString *title = [NSString stringWithFormat:@"%@ %@", [df stringFromDate:[event startDate]], [event title]];
    [cellView.textField setStringValue:title];
    return cellView;
  }
  // Return nil if not matching or wrong row
  return nil;
}


@end
