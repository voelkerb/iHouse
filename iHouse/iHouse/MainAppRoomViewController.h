//
//  MainAppRoomViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 15/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Room.h"
#import "NSFlippedView.h"

@interface MainAppRoomViewController : NSViewController{
  NSMutableArray *viewControllers;
  NSMutableArray *windowControllers;
  NSMutableArray *undockButtons;
}


@property (weak) IBOutlet NSTextField *dummyText;

// The scrollview and its inside view
@property (weak) IBOutlet NSView *viewThatScrolls;
@property (weak) IBOutlet NSScrollView *scrollView;

// The room variable
@property (strong, nullable) Room *room;

// A Room must be inited with a name so that the it can be identified
- (nullable instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
                                room: (nullable Room *)theRoom;

@end
