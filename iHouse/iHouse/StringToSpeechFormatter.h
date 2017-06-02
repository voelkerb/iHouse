//
//  StringToSpeechFormatter.h
//  iHouse
//
//  Created by Benjamin Völker on 27/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const KeyStringFormatterReadable;
extern NSString* const KeyStringFormatterSpeakable;

@class EKEvent;
@interface StringToSpeechFormatter : NSObject {
  NSArray *dayText;
  NSArray *monthText;
}

// This class is singletone
+ (id)sharedSpeechFormatter;

// Converts a given temperature in words
-(NSString*)temperatureInWords:(double) temp;

// Converts a day into words (e.g. "tenth")
-(NSString*)dayInWords:(NSInteger) day;

// Converts a date into words (e.g. "tenth of August 2015, 10 o'clock")
-(NSString*)dateInWords:(NSDate*) date : (unsigned int) dateComponentFlags;

// Converts a calendar event into a readable and speakable text
-(NSDictionary*)calendarEventToText:(EKEvent*)theEvent;

@end
