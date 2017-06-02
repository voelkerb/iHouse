//
//  VoiceCommandScrollViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 09/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "VoiceCommand.h"
@interface VoiceCommandScrollViewController : NSObject {
  BOOL currentlyDisplaysWelcomMsg;
  NSMutableArray *views;
  NSMutableArray *viewControllers;
  NSView *scrollPointView;
  NSString *roomName;
}

// The scrollView of the command responses
@property (strong) NSScrollView *responseScrollView;

// Init with the scrollView
-(id)initWithScrollView:(NSScrollView*) theScrollView;
-(void)reInitWithRoomName:(NSString*)theRoomName;

- (void)appendSeperator;
- (void)appendText:(NSString*) theText :(NSTextAlignment) textAlignment :(BOOL) autoScroll;
- (void)appendView:(NSView*) theView :(NSTextAlignment) textAlignment :(BOOL) autoScroll;
- (void)appendViewWithController:(NSViewController*) theViewController :(NSTextAlignment) textAlignment :(BOOL) autoScroll;


@end
