//
//  MainAppGeneralViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 15/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "House.h"
#import "Group.h"
#import "GroupActivateViewController.h"
#import "TemperatureViewController.h"
#import "WeatherViewController.h"
#import "CalendarViewController.h"
#import "HouseTileViewController.h"
#import "NSFlippedView.h"

@interface MainAppGeneralViewController : NSViewController {
  // The array holding all views with their positions in scrollview
  NSMutableArray *viewControllers;
  NSMutableArray *windowControllers;
  BOOL initDone;
  NSMutableArray *undockButtons;
}

// The scrollview and it's inside view
@property NSFlippedView *documentView;
@property (weak) IBOutlet NSScrollView *scrollView;

@end
