//
//  TempertureViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 16/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "TemperatureViewController.h"

@interface TemperatureViewController ()

@end

@implementation TemperatureViewController

- (nullable instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil bgColor:(nullable NSColor *)theBGColor {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  
  if (self) {
    // Store BG Color
    bgColor = theBGColor;
  }
  
  return self;
}
- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Set the bgColor
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[bgColor CGColor]];
  [self.view setWantsLayer:YES];
  [self.view setLayer:viewLayer];
}

@end
