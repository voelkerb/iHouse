//
//  Calendar.m
//  iHouse
//
//  Created by Benjamin Völker on 26/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "Calendar.h"
#import "VoiceCommand.h"
#import "StringToSpeechFormatter.h"
#import "CalendarViewController.h"

#define DEBUG_CALENDAR 0
#define VOICE_COMMAND_GET_TODAY_EVENTS @"Show todays events"
#define VOICE_RESPONS_GET_EVENT @"You have one event %@"
#define VOICE_RESPONS_GET_EVENTS @"You have %li events %@"
#define VOICE_RESPONS_GET_TODAY @"today."
#define VOICE_RESPONS_GET_TOMORROW @"tomorrow."
#define VOICE_RESPONS_GET_WEEK @"left this week."

NSString * const CalendarNewCalendarDataAvailable = @"CalendarNewCalendarDataAvailable";

@implementation Calendar
@synthesize calendarEvents, eventStore, name;

/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedCalendar {
  static Calendar *sharedCalendar = nil;
  @synchronized(self) {
    if (sharedCalendar == nil) {
      sharedCalendar = [[self alloc] init];
    }
  }
  return sharedCalendar;
}

- (id)init {
  if (self = [super init]) {
    // Init member variables
    name = @"Calendar";
    calendarEvents = [[NSArray alloc] init];
    eventStore = [[EKEventStore alloc] init];
    // Get all calendar events of the current month and store them in array
    [self getCalendarEvents];
    // Add observer for calendarchanges
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(getCalendarEvents)
                                                 name:EKEventStoreChangedNotification
                                               object:eventStore];
    
    // Add observer for daychanges
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dayChanged:)
                                                 name:NSCalendarDayChangedNotification
                                               object:nil];
    [self updateAuthorizationStatusToAccessEventStore];
    
    
    
  }
  return self;
}


- (void)updateAuthorizationStatusToAccessEventStore {
  // 2
  EKAuthorizationStatus authorizationStatus = [EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder];
  
  switch (authorizationStatus) {
      // 3
    case EKAuthorizationStatusDenied:
    case EKAuthorizationStatusRestricted: {
      break;
    }
      
      // 4
    case EKAuthorizationStatusAuthorized:
      break;
      
      // 5
    case EKAuthorizationStatusNotDetermined: {
      [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
        });
      }];
    }
  }
}


// Coding needed since voice commands store the handler and the handler is us
- (void)encodeWithCoder:(NSCoder *)aCoder {
}
// For init just init us properly
-(id)initWithCoder:(NSCoder *)aDecoder {
  return [Calendar sharedCalendar];
}


/*
 * On daychange update calendar (maybe it is a new month).
 */
-(void)dayChanged:(NSNotification*)notification {
  [self getCalendarEvents];
}

/*
 * Gets all calendar events
 */
- (void)getCalendarEvents {
  // Get the current calendar
  NSCalendar *calendar = [NSCalendar currentCalendar];
  
  NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear
                                                                 fromDate:[NSDate date]];
  // Get first day of this month
  components.day = 1;
  NSDate *firstDayOfMonthDate = [[NSCalendar currentCalendar] dateFromComponents: components];
  
  // Get last day of this month (increment month and go one day back)
  [components setMonth:[components month]+1];
  components.day = 1;
  NSDate *lastDayOfMonthDate = [calendar dateFromComponents:components];
  
  
  // Create the predicate from the event store's instance method
  NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:firstDayOfMonthDate
                                                          endDate:lastDayOfMonthDate
                                                        calendars:nil];
  
  // Fetch all events that match the predicate
  calendarEvents = [eventStore eventsMatchingPredicate:predicate];
  if (DEBUG_CALENDAR) {
    for (EKEvent *event in calendarEvents) {
      NSLog(@"Event name: %@, date: %@ - %@", event.title, event.startDate,  event.endDate);
    }
  }
  
  // Post notification that new events are available
  [[NSNotificationCenter defaultCenter] postNotificationName:CalendarNewCalendarDataAvailable object:self];
}


-(NSArray*)eventsForDate:(NSDate*)date {
  // Flags for comparison
  unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
  // Get day only from date
  NSDateComponents* dayComp = [[NSCalendar currentCalendar] components:flags fromDate:date];
  NSDate* dayOnly = [[NSCalendar currentCalendar] dateFromComponents:dayComp];
  NSMutableArray *events = [[NSMutableArray alloc] init];
  for (EKEvent *theEvent in calendarEvents) {
    NSDateComponents* dateComp = [[NSCalendar currentCalendar] components:flags fromDate:[theEvent startDate]];
    NSDate* eventDate = [[NSCalendar currentCalendar] dateFromComponents:dateComp];
    if ([dayOnly isEqualToDate:eventDate]) {
      [events addObject:theEvent];
      if (DEBUG_CALENDAR) NSLog(@"Found tomorrow event: %@", [theEvent title]);
    }
  }
  return events;
}

#pragma mark voice command functions

/*
 * Return the viewcontroller of this class
 */
-(NSViewController*) deviceView {
  return [[CalendarViewController alloc] init];
}

/*
 * Returns todays events.
 */
-(NSDictionary*)todayEvents {
  // Loop over all events and only store the events that are today
  NSArray *todayEvents = [self eventsForDate:[NSDate date]];
  
  //Construct response (handles event(s))
  NSString *response = [NSString stringWithFormat:VOICE_RESPONS_GET_EVENTS, [todayEvents count], VOICE_RESPONS_GET_TODAY];
  NSString *responseSpeech = [NSString stringWithFormat:VOICE_RESPONS_GET_EVENTS, [todayEvents count], VOICE_RESPONS_GET_TODAY];
  if ([todayEvents count] == 1) {
    response = [NSString stringWithFormat:VOICE_RESPONS_GET_EVENT, VOICE_RESPONS_GET_TODAY];
    responseSpeech = [NSString stringWithFormat:VOICE_RESPONS_GET_EVENT, VOICE_RESPONS_GET_TODAY];
  }
  
  // Speakable text builder object
  StringToSpeechFormatter *stringToSpeech = [StringToSpeechFormatter sharedSpeechFormatter];
  // For all events today, construct the response strings and append it to the response string
  for (EKEvent *theEvent in todayEvents) {
    NSDictionary *dict = [stringToSpeech calendarEventToText:theEvent];
    response = [NSString stringWithFormat:@"%@\n%@.", response, [dict objectForKey:KeyStringFormatterReadable]];
    responseSpeech = [NSString stringWithFormat:@"%@\n%@.", responseSpeech, [dict objectForKey:KeyStringFormatterSpeakable]];
  }
  
  // Return response string and speech
  NSMutableDictionary *responseDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:response,
                                       KeyVoiceCommandResponseString,
                                       responseSpeech, KeyVoiceCommandResponseSpeechString,
                                       [NSNumber numberWithBool:true], KeyVoiceCommandExecutedSuccessfully , nil];
  return responseDict;
}

/*
 * Returns tomorrow events.
 */
-(NSDictionary*)tomorowEvents {
  // Date components for one day
  NSDateComponents *components = [[NSDateComponents alloc] init];
  [components setDay:1];
  // Create a calendar and get date of tomorrow
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  NSDate *tomorrow = [gregorian dateByAddingComponents:components toDate:[NSDate date] options:0];
  // Get events of tomorrow
  NSArray *tomorrowEvents = [self eventsForDate:tomorrow];
  // Create responses
  NSString *response = [NSString stringWithFormat:VOICE_RESPONS_GET_EVENTS, [tomorrowEvents count], VOICE_RESPONS_GET_TOMORROW];
  NSString *responseSpeech = [NSString stringWithFormat:VOICE_RESPONS_GET_EVENTS, [tomorrowEvents count], VOICE_RESPONS_GET_TOMORROW];
  if ([tomorrowEvents count] == 1) {
    response = [NSString stringWithFormat:VOICE_RESPONS_GET_EVENT, VOICE_RESPONS_GET_TOMORROW];
    responseSpeech = [NSString stringWithFormat:VOICE_RESPONS_GET_EVENT, VOICE_RESPONS_GET_TOMORROW];
  }
  
  // Init speech string builder
  StringToSpeechFormatter *stringToSpeech = [StringToSpeechFormatter sharedSpeechFormatter];
  // Loop over all events tomorrow
  for (EKEvent *theEvent in tomorrowEvents) {
    NSDictionary *dict = [stringToSpeech calendarEventToText:theEvent];
    response = [NSString stringWithFormat:@"%@\n%@.", response, [dict objectForKey:KeyStringFormatterReadable]];
    responseSpeech = [NSString stringWithFormat:@"%@\n%@.", responseSpeech, [dict objectForKey:KeyStringFormatterSpeakable]];
  }
  
  // Return response string and speech
  NSMutableDictionary *responseDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:response,
                                       KeyVoiceCommandResponseString,
                                       responseSpeech, KeyVoiceCommandResponseSpeechString,
                                       [NSNumber numberWithBool:true], KeyVoiceCommandExecutedSuccessfully , nil];
  return responseDict;
}



-(NSDictionary*)weekEvents {
  // Get today date without hour minute
  NSMutableArray *weekEvents = [[NSMutableArray alloc] init];
  NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitWeekday | NSCalendarUnitYear fromDate:[NSDate date]];
  // Loop over all events and look if the event starts this week and after the current weekday
  for (EKEvent *theEvent in calendarEvents) {
    NSDateComponents *otherDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitWeekday | NSCalendarUnitYear fromDate:[theEvent startDate]];
    if ([dateComponents weekday] == [otherDateComponents weekday] && [dateComponents year] == [otherDateComponents year]
        && [dateComponents day] <= [otherDateComponents day]) {
      [weekEvents addObject:theEvent];
      if (DEBUG_CALENDAR) NSLog(@"Found week event: %@", [theEvent title]);
    }
  }
  // Construct response
  NSString *response = [NSString stringWithFormat:VOICE_RESPONS_GET_EVENTS, [weekEvents count], VOICE_RESPONS_GET_WEEK];
  NSString *responseSpeech = [NSString stringWithFormat:VOICE_RESPONS_GET_EVENTS, [weekEvents count], VOICE_RESPONS_GET_WEEK];
  if ([weekEvents count] == 1) {
    response = [NSString stringWithFormat:VOICE_RESPONS_GET_EVENT, VOICE_RESPONS_GET_WEEK];
    responseSpeech = [NSString stringWithFormat:VOICE_RESPONS_GET_EVENT, VOICE_RESPONS_GET_WEEK];
  }
  
  // Create speech string builder
  StringToSpeechFormatter *stringToSpeech = [StringToSpeechFormatter sharedSpeechFormatter];
  // Loop over all weekevents and add them
  for (EKEvent *theEvent in weekEvents) {
    NSDictionary *dict = [stringToSpeech calendarEventToText:theEvent];
    response = [NSString stringWithFormat:@"%@\n%@.", response, [dict objectForKey:KeyStringFormatterReadable]];
    responseSpeech = [NSString stringWithFormat:@"%@\n%@.", responseSpeech, [dict objectForKey:KeyStringFormatterSpeakable]];
  }
  
  // Return response string and speech
  NSMutableDictionary *responseDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:response,
                                       KeyVoiceCommandResponseString,
                                       responseSpeech, KeyVoiceCommandResponseSpeechString,
                                       [NSNumber numberWithBool:true], KeyVoiceCommandExecutedSuccessfully , nil];
  return responseDict;
}




/*
 * Returns the standard voice commands of the device.
 */
-(NSArray *)standardVoiceCommands {
  VoiceCommand *todayEvents = [[VoiceCommand alloc] init];
  [todayEvents setName:VOICE_COMMAND_GET_TODAY_EVENTS];
  [todayEvents setCommand:VOICE_COMMAND_GET_TODAY_EVENTS];
  [todayEvents setSelector:@"todayEvents"];
  //[todayEvents setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_TODAY_EVENTS, nil]];
  NSArray *commands = [[NSArray alloc] initWithObjects:todayEvents, nil];
  return commands;
}

/*
 * Return the available selectors for voice commands.
 */
-(NSArray *)voiceCommandSelectors {
  return [[NSArray alloc] initWithObjects:@"todayEvents", @"tomorowEvents", @"weekEvents", nil];
}

/*
 * Returns the voice command extensions the device should be sensitive to.
 */
-(NSArray *)voiceCommandSelectorsReadable {
  return [[NSArray alloc] initWithObjects:@"Events today", @"Events tomorrow", @"Events this week", nil];
}

/*
 * Executes a given selector on the device.
 */
-(NSDictionary*)executeSelector:(NSString *)selector {
  // Look for selector delimiter
  NSRange range = [selector rangeOfString:@":"];
  // If a delimiter is found, the selector has an object attached as string
  if (range.location != NSNotFound) {
    // Get the real selector and the object
    NSString *realSelector = [selector substringToIndex:range.location + range.length];
    NSString *object = @"";
    if ([selector length] > range.length + range.location) {
      object = [selector substringFromIndex:range.location + range.length];
    }
    if (DEBUG_CALENDAR) NSLog(@"Selector: %@, Object: %@", realSelector, object);
    // If the Device does not respond to the selector, return error
    if (![self respondsToSelector:NSSelectorFromString(realSelector)]) {
      return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:false], KeyVoiceCommandExecutedSuccessfully, nil];
    }
    // If the device responds to selector, perform it and store result in dictionary and return it
    //NSDictionary *result = [self performSelector:NSSelectorFromString(realSelector) withObject:object];
    NSDictionary *result = ((NSDictionary* (*)(id, SEL, NSObject*))[self methodForSelector:NSSelectorFromString(realSelector)])(self, NSSelectorFromString(selector), object);
    
    if (DEBUG_CALENDAR) NSLog(@"selector %@ exists, executed with result: %@", realSelector, result);
    return result;
  }
  // No object is attached
  // If the Device does not respond to the selector, return error
  if (![self respondsToSelector:NSSelectorFromString(selector)]) {
    return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:false], KeyVoiceCommandExecutedSuccessfully, nil];
  }
  // If the device responds to selector, perform it and store result in dictionary and return it
  //NSDictionary *result = [self performSelector:NSSelectorFromString(selector) withObject:nil];
  NSDictionary *result = ((NSDictionary* (*)(id, SEL))[self methodForSelector:NSSelectorFromString(selector)])(self, NSSelectorFromString(selector));
  
  if (DEBUG_CALENDAR) NSLog(@"selector %@ exists, executed with result: %@", selector, result);
  return result;
}



@end
