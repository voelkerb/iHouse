//
//  MeterViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <Foundation/Foundation.h>


@interface mbFliperViews : NSObject
{
  NSMutableArray* views; //Animated views
  NSView* superView; // Super view
  NSInteger idxActiveView;
  NSInteger idxBefore;
  CGPoint origin; // origin for views
  NSInteger prespect; // перспектива
  double time;
}

- (void)addView:(NSView*)view;
- (void)removeViewAtIndex:(NSInteger)idx;
- (NSView*)viewAtIndex:(NSInteger)idx;
- (void)setActiveViewAtIndex:(NSInteger)idx;// set active view
- (IBAction)flipRight:(id)sender; // flip right
- (IBAction)flipLeft:(id)sender; // flip left
- (IBAction)flipUp:(id)sender; // flip up
- (IBAction)flipDown:(id)sender; // flip down

@property (nonatomic) CGPoint origin; // Starting point coordinates of all species in superview
@property NSInteger prespect; //perspective, the default value -1000
@property (retain) NSView* superView; // superview to insert the added view
@property double time; // time of the animation in seconds, default 1.0

@end