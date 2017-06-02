//
//  StringToSpeechFormatter.m
//  iHouse
//
//  Created by Benjamin Völker on 27/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "StringToSpeechFormatter.h"

#import <EventKit/EventKit.h>

#define DEBUG_STRING_TO_SPEECH 0

// Key for readable text
NSString* const KeyStringFormatterReadable = @"KeyStringFormatterReadable";
// Key for speakable text
NSString* const KeyStringFormatterSpeakable = @"KeyStringFormatterSpeakable";

@implementation StringToSpeechFormatter

/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedSpeechFormatter {
  static StringToSpeechFormatter *sharedSpeechFormatter = nil;
  @synchronized(self) {
    if (sharedSpeechFormatter == nil) {
      sharedSpeechFormatter = [[self alloc] init];
    }
  }
  return sharedSpeechFormatter;
}

/*
 * Init the arrays holding the speech
 */
- (id)init {
  if (self = [super init]) {
    dayText = [[NSArray alloc] initWithObjects:@"first", @"second",
               @"third", @"fourth", @"fifth", @"sixth", @"seventh", @"eighth",
               @"nineth", @"tenth", @"eleventh", @"twelveth", @"thirteenth", @"fourteenth", @"fifteenth",
               @"sixteenth", @"seventeenth", @"eighteenth", @"nineteenth", @"twentieth", @"twenty first",
               @"twenty second", @"twenty third", @"twenty fourth", @"twenty fifth", @"twenty sixth",
               @"twenty seventh", @"twenty eighth", @"twenty nineth", @"thirtieth", @"thirty first", nil];
    
    monthText = [[NSArray alloc] initWithObjects:@"January", @"February",
               @"March", @"April", @"May", @"June", @"July", @"August",
               @"September", @"Oktober", @"November", @"December", nil];
  }
  return self;
}

/*
 * Converts a given temperature to speech.
 */
-(NSString*)temperatureInWords:(double)temp {
  return [NSString stringWithFormat:@"%.1f degrees celsius", temp];
}

/*
 * Converts a given calendar event to a speakable and readable string.
 */
-(NSDictionary*)calendarEventToText:(EKEvent*)theEvent {
  // Set Dateformater to hours and minutes
  NSDateFormatter *df = [[NSDateFormatter alloc] init];
  [df setLocale:[NSLocale currentLocale]];
  [df setDateFormat:@"HH:mm"];
  
  // One response for readable and one for speakable text
  NSString *oneEventResponse = [NSString stringWithFormat:@"%@,", [theEvent title]];
  NSString *oneEventResponseSpeech = [NSString stringWithFormat:@"%@,", [theEvent title]];
  
  // If the event is not all day, append date, if not, append just nothing
  if (![theEvent isAllDay]) {
    // Get only the day of start and stop
    NSDateComponents *componentsStartDay = [[NSCalendar currentCalendar] components:
                                            NSCalendarUnitDay fromDate:[theEvent endDate]];
    NSDateComponents *componentsStopDay = [[NSCalendar currentCalendar] components:
                                           NSCalendarUnitDay fromDate:[theEvent startDate]];
    
    // If the event ends on other day print full dates seperated by "till"
    if ([componentsStartDay day] != [componentsStopDay day]) {
      oneEventResponse = [NSString stringWithFormat:@"%@ from today, %@", oneEventResponse,
                          [df stringFromDate:[theEvent startDate]]];
      
      oneEventResponseSpeech = [NSString stringWithFormat:@"%@ from today, %@", oneEventResponseSpeech,
                                [self dateInWords:[theEvent startDate] :(NSCalendarUnitMonth |
                                                                                   NSCalendarUnitDay|
                                                                                   NSCalendarUnitHour |
                                                                                   NSCalendarUnitMinute)]];
      // Stop date with day and month
      [df setDateFormat:@"dd.MM HH:mm"];
      oneEventResponse = [NSString stringWithFormat:@"%@ till %@", oneEventResponse,
                          [df stringFromDate:[theEvent endDate]]];
      oneEventResponseSpeech = [NSString stringWithFormat:@"%@ till %@", oneEventResponseSpeech,
                                [self dateInWords:[theEvent startDate] :(NSCalendarUnitMonth |
                                                                                   NSCalendarUnitDay|
                                                                                   NSCalendarUnitHour |
                                                                                   NSCalendarUnitMinute)]];
    // If the event ends on startday than just print Hour:Minute-Hour:Minute
    } else {
      oneEventResponse = [NSString stringWithFormat:@"%@ from %@ till %@", oneEventResponse,
                          [df stringFromDate:[theEvent startDate]],
                          [df stringFromDate:[theEvent endDate]]];
      
      oneEventResponseSpeech = [NSString stringWithFormat:@"%@ from %@ till %@", oneEventResponseSpeech,
                                [self dateInWords:[theEvent startDate] :(NSCalendarUnitHour |
                                                                                   NSCalendarUnitMinute)],
                                [self dateInWords:[theEvent endDate] :(NSCalendarUnitHour |
                                                                                 NSCalendarUnitMinute)]];
    }
  }
  // If a location exist, add location
  if ([theEvent location]) {
    oneEventResponse = [NSString stringWithFormat:@"%@ at location: %@",
                        oneEventResponse, [theEvent location]];
    oneEventResponseSpeech = [NSString stringWithFormat:@"%@ at %@",
                              oneEventResponseSpeech, [theEvent location]];
  }
  // Return as dictionary
  return [NSDictionary dictionaryWithObjectsAndKeys:oneEventResponse, KeyStringFormatterReadable, oneEventResponseSpeech, KeyStringFormatterSpeakable, nil];

}

/*
 * Convert a given day as integer into a string (e.g. "tenth")
 */
-(NSString*)dayInWords:(NSInteger) day {
  return dayText[day-1];
}

/*
 * Convert a given day with some given dateComponent Flags into a speakable string (e.g."tenth of august 2015, 10 o'clock").
 */
-(NSString*) dateInWords:(NSDate*) date : (unsigned int) dateComponentFlags {
  // Get the calendar object
  NSCalendar *theCalendar = [NSCalendar currentCalendar];
  // Get the components
  NSDateComponents *components = [theCalendar components:
                                          dateComponentFlags fromDate:date];
  NSString *dateAsString = @"";
  // If flags contained day
  if ([components day] < 32) {
    if (DEBUG_STRING_TO_SPEECH) NSLog(@"day: %li", [components day]);
    dateAsString = [NSString stringWithFormat:@"%@%@ ", dateAsString, dayText[[components day]-1]];
  }
  // If flags contained month
  if ([components month] < 13) {
    if (DEBUG_STRING_TO_SPEECH) NSLog(@"month: %li", [components month]);
    dateAsString = [NSString stringWithFormat:@"%@of %@ ", dateAsString, monthText[[components month]-1]];
  }
  // If flags contained year
  if ([components year] < 3000) {
    if (DEBUG_STRING_TO_SPEECH) NSLog(@"year: %li", [components year]);
    dateAsString = [NSString stringWithFormat:@"%@%li, ", dateAsString, [components year]];
  }
  // If flags contained hour
  if ([components hour] < 25) {
    if (DEBUG_STRING_TO_SPEECH) NSLog(@"hour: %li", [components hour]);
    dateAsString = [NSString stringWithFormat:@"%@%li ", dateAsString, [components hour]];
    // If no minute will be attached, append "o'clock"
    if ([components minute] < 61) {
      //dateAsString = [NSString stringWithFormat:@"%@o'clock ", dateAsString];
    }
  }
  // If flags contained minute
  if ([components minute] < 61) {
    if (DEBUG_STRING_TO_SPEECH) NSLog(@"minute: %li", [components minute]);
    // If minute is 0 append an "o'clock" to the string
    if ([components minute] == 0) {
      dateAsString = [NSString stringWithFormat:@"%@o'clock ", dateAsString];
    // else leave o'clock away
    } else {
      // If smaller 9 add a 0 to read e.g. ten zero five
      if ([components minute] < 9) {
        dateAsString = [NSString stringWithFormat:@"%@0%li ", dateAsString, [components minute]];
      } else {
        dateAsString = [NSString stringWithFormat:@"%@%li ", dateAsString, [components minute]];
      }
    }
  }
  // If flags contained second
  if ([components second] < 61) {
    if (DEBUG_STRING_TO_SPEECH) NSLog(@"second: %li", [components second]);
    // Handle second(s)
    if ([components second] == 1) {
      dateAsString = [NSString stringWithFormat:@"%@and %li second", dateAsString, [components second]];
    } else {
      dateAsString = [NSString stringWithFormat:@"%@and %li seconds", dateAsString, [components second]];
    }
  }

  return dateAsString;
}

@end
