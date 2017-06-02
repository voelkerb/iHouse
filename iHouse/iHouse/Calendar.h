//
//  Calendar.h
//  iHouse
//
//  Created by Benjamin Völker on 26/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

// New Calendar data available
extern NSString * const CalendarNewCalendarDataAvailable;

@interface Calendar : NSObject<NSCoding>

// The name of the calendar
@property (strong) NSString *name;
// All calendar events in an array
@property (strong) NSArray *calendarEvents;

// The Eventkit object
@property (strong) EKEventStore *eventStore;

// This class is singletone
+ (id)sharedCalendar;

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

- (void)updateAuthorizationStatusToAccessEventStore;
@end
