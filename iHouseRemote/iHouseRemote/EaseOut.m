//
//  EaseOut.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 25/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "EaseOut.h"

@implementation EaseOut

-(void)perform {
  
  UIViewController *dst = [self destinationViewController];
  UIViewController *src = [self sourceViewController];
  
  
  
  CATransition *transition = [CATransition animation];
  transition.duration = 0.5;
  transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  transition.type = kCATransitionPush;
  transition.subtype = kCATransitionFromLeft;
  [src.view.window.layer addAnimation:transition forKey:nil];
  
  [src presentViewController:dst animated:NO completion:nil];
}

@end
