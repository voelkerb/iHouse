//
//  InfraredCommand.h
//  iHouse
//
//  Created by Benjamin Völker on 20/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

extern NSString * const IRCommandEmptyCommand;
extern NSString * const IRCommandImageChanged;
extern NSString * const IRCommandLearnedSuccessfully;

@class InfraredCommand;

// The Functions the delegate has to implement
@protocol InfraredCommandDelegate <NSObject>

// The delegate needs to change something
- (void)deleteCommand:(InfraredCommand*)theCommand;
// The delegate needs to change something
- (void)learnCommand:(InfraredCommand*)theCommand;
// The delegate needs to change something
- (void)stopLearning;
// The delegate needs to change something
- (void)toggle:(InfraredCommand*)theCommand;
// The delegate needs to change something
- (BOOL)isConnected;

@end

@interface InfraredCommand : NSObject <NSCoding>

// The available and supported ir protocolls
typedef NS_ENUM(NSUInteger, IRProtocoll) {
  IR_RAW,
  IR_NEC,
  IR_SONY,
  IR_RC5,
  IR_RC6,
  IR_DISH,
  IR_SHARP,
  IR_PANASONIC,
  IR_JVC,
  IR_SANYO,
  IR_MITSUBISHI,
  numbOfDifferentIRProtocolls
};

// The delegate variable
@property (weak) id<InfraredCommandDelegate> delegate;

// The name of the infrared command
@property NSString* name;

// The image of the infrared commmand
@property NSImage* image;

// The protocoll type of the infrared command
@property IRProtocoll irProtocoll;

// The array holding the raw code
@property NSArray* irRawCode;

// The number holding the ir code (if not raw)
@property NSNumber* irCode;
@property NSNumber* irCode2;
@property NSInteger repeatCount;

// Returns the toggle command for this infrared device
- (NSData*)toggleCommand;

// Decodes a learned command and sets the code and protocoll accordingly
- (void)gotLearnCommand:(NSString*)cmd;

// Deletes itself
- (void)deleteCommand;

// Learn itself
- (void)learnCommand;

// stop learn itself
- (void)stopLearning;

// Toggle itself
- (void)toggle;

// Toggle itself
- (BOOL)isConnected;

// Returns the viewcontroller of the deviceView
- (NSViewController*)deviceView;

// Returns the viewcontroller of the deviceEditView
- (NSViewController*)deviceEditView;

// Converts the protocoll to a string
- (NSString*)irProtocollToString:(IRProtocoll)theIRProtocoll;

@end
