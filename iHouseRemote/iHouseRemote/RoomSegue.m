//
//  RoomSegue.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 24/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "RoomSegue.h"

@implementation RoomSegue

-(void)perform {
  
  UIViewController *dst = [self destinationViewController];
  UIViewController *src = [self sourceViewController];
  
  //Custom Code
  
  //[src presentModalViewController:dst animated:YES];
  [src presentViewController:dst animated:YES completion:nil];
  
}

@end
