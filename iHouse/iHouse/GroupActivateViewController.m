//
//  GroupActivateViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 16/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "GroupActivateViewController.h"

@interface GroupActivateViewController ()

@end

@implementation GroupActivateViewController
@synthesize group, nameLabel, imageView, backView;

/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  GroupActivateViewController *copy = [[GroupActivateViewController allocWithZone: zone] initWithGroup:group];
  return copy;
}


/*
 * Init this view properly with a group
 */
-(id)initWithGroup:(Group *)theGroup {
  if (self = [super init]) {
    group = theGroup;
  }
  return self;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  // Do view setup here.
  // Set the name and image if group is not nil
  if (group) {
    [nameLabel setStringValue:group.name];
    [imageView setImage:group.image];
  }
  // Image is not drag- nor droppable
  [imageView setAllowDrag:false];
  [imageView setAllowDrop:false];
  // We have no bg color yet
  /*
  CALayer *layer = [[CALayer alloc] init];
  [backView setWantsLayer:YES];
  [backView setLayer:layer];
   */
}

/*
 * If the user presses the toggle button
 */
-(void)toggleGroup:(id)sender {
  // The group simply needs to be activated if exist
  if (group) {
    [group activate];
  }
}

@end
