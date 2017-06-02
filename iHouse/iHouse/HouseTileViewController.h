//
//  HouseTileView.h
//  iHouse
//
//  Created by Benjamin Völker on 16/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface HouseTileViewController : NSViewController {
  NSColor *bgColor;
}


- (nullable instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
                                bgColor: (nullable NSColor*) theBGColor;
@end
