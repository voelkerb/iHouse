//
//  flippedView.m
//  iHouse
//
//  Created by Benjamin Völker on 30/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "NSFlippedView.h"

@implementation NSFlippedView

-(id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code here.
  }
  return self;
}

-(void)drawRect:(NSRect)dirtyRect {
  // Drawing code here.
}

-(BOOL)isFlipped {
  return YES;
}

@end
