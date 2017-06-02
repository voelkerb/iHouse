//
//  GroupViewController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 16/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "GroupViewController.h"
#import "HouseSyncer.h"


@implementation GroupViewController

- (void)viewDidLoad {
  transition = nil;
  init = false;
  
  house = [House sharedHouse];

  [self displayGroups];
}


-(void)viewDidLayoutSubviews {
  if (!init) [self displayGroups];
}

-(void)resetInit {
  init = false;
}


- (void)displayGroups {
  init = true;
  [self performSelector:@selector(resetInit) withObject:nil afterDelay:0.1];
  NSArray *views = [[NSArray alloc] initWithArray:self.scrollView.subviews];
  for (UIView *theView in views) [theView removeFromSuperview];
  

  NSInteger theTag = 0;
  NSInteger xMargin = 20;
  NSInteger yMargin = 40;
  NSInteger sideMargin = 30;
  NSInteger topMargin = 40;
  NSInteger xPos = sideMargin;
  NSInteger yPos = topMargin;
  NSInteger groupsPerRow = 3;
  // Go for 3 items per row on ipad
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) groupsPerRow = 5;
  
  int columnCounter = 0;
  BOOL atBottom = false;
  
  // Get view bounds
  CGRect view = self.view.bounds;
  
  // we want to have 3 groups per row, estimate size
  NSInteger width = (view.size.width - (groupsPerRow-1)*xMargin - 2*sideMargin)/groupsPerRow;
  NSInteger height = width;
  
  
  
  
  for (Group *theGroup in [house groupList]) {
    UIImage *btnImage = theGroup.image;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [[button imageView] setContentMode:UIViewContentModeScaleAspectFit];
    
    UIButton *buttonText = [UIButton buttonWithType:UIButtonTypeSystem];
    [button addTarget:self
               action:@selector(groupPressed:)
     forControlEvents:UIControlEventTouchUpInside];
    [buttonText addTarget:self
                   action:@selector(groupPressed:)
         forControlEvents:UIControlEventTouchUpInside];
    [buttonText setTitle:theGroup.name forState:UIControlStateNormal];
    [button setImage:btnImage forState:UIControlStateNormal];
    [buttonText setTitle:theGroup.name forState:UIControlStateHighlighted];
    [button setImage:btnImage forState:UIControlStateHighlighted];
    [buttonText setTitle:theGroup.name forState:UIControlStateSelected];
    [button setImage:btnImage forState:UIControlStateSelected];
    [button setEnabled:YES];
    [buttonText setEnabled:YES];
    button.hidden = false;
    buttonText.hidden = false;
    [button setTag:theTag];
    [buttonText setTag:theTag];
    button.frame = CGRectMake(xPos, yPos, width, height);
    buttonText.frame = CGRectMake(xPos, yPos + height, width, 15);
    [self.scrollView addSubview:button];
    [self.scrollView addSubview:buttonText];
    
    atBottom = false;
    theTag++;
    columnCounter++;
    xPos = xPos + width + xMargin;
    if (columnCounter == groupsPerRow) {
      yPos = yPos + height + yMargin;
      columnCounter = 0;
      xPos = sideMargin;
      atBottom = true;
    }
  }
  if (!atBottom) yPos = yPos + height + yMargin + yMargin;
  CGSize size = self.view.bounds.size;
  size.height = yPos;
  self.scrollView.contentSize = size;
}


-(void)handlePan:(id)sender {
  if (DEBUG) NSLog(@"Go back!");
  if (!transition) {
    transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    [self.view.window.layer addAnimation:transition forKey:nil];
    
    [self dismissViewControllerAnimated:NO completion:nil];
  }
}

- (void)groupPressed:(id)sender {
  if (![[house groupList] objectAtIndex:[sender tag]]) return;
  NSLog(@"Pressed group: %@", [[house groupList] objectAtIndex:[sender tag]]);
  [[HouseSyncer sharedHouseSyncer] sendGroup:[[house groupList] objectAtIndex:[sender tag]]];
  // Update info of the device
  //[house updateDevice:house.currentDevice];
  //[self performSegueWithIdentifier:@"SingleDeviceSegue" sender:self];
  
}

-(void)activateVoice:(id)sender {
  [[HouseSyncer sharedHouseSyncer] activateSiri];
}
@end
