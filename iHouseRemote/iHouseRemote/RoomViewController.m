//
//  RoomViewController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 24/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "RoomViewController.h"
#import "HouseSyncer.h"
#import "DeviceViewController.h"

#define DEBUG_ROOMVIEW 1
#define CONNECTION_ISSUE_MSG @"Could not connect to the iHouse server application (host: 192.168.0.18).\nMake sure the application is up and running."
#define CONNECTION_ISSUE_TITLE @"Connection Problem"
#define CONNECTION_BROKE_ISSUE_TITLE @"Server Disconnected"
#define CONNECTION_BROKE_ISSUE_MSG @"The connection to the server was lost.\nTry to manually re-establish the connection."

@implementation RoomViewController
@synthesize scrollView, groupButton;

- (void)viewDidLoad {  [super viewDidLoad];
  transition = nil;
  init = false;
  house = [House sharedHouse];
  currentRoom = nil;
  if ([[house groupList] count] > 0) {
    groupButton.hidden = false;
    groupButton.enabled = true;
  } else {
    groupButton.hidden = true;
    groupButton.enabled = false;
  }
  
  [self displayRooms];
}

-(void)viewDidLayoutSubviews {
  if (!init) [self displayRooms];
}

-(void)resetInit {
  init = false;
}

- (void)displayRooms {
  init = true;
  [self performSelector:@selector(resetInit) withObject:nil afterDelay:0.1];
  NSArray *views = [[NSArray alloc] initWithArray:self.scrollView.subviews];
  for (UIView *theView in views) [theView removeFromSuperview];
  
  NSInteger theTag = 0;
  NSInteger xMargin = 20;
  NSInteger yMargin = 30;
  NSInteger sideMargin = 30;
  NSInteger topMargin = 10;
  NSInteger xPos = sideMargin;
  NSInteger yPos = topMargin;
  
  NSInteger roomsPerRow = 2;
  // Go for 3 items per row on ipad
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) roomsPerRow = 3;
  
  
  int columnCounter = 0;
  
  // Get view bounds
  CGRect view = self.view.bounds;
  
  // we want to have 3 rooms per row, estimate size
  NSInteger width = (view.size.width - (roomsPerRow-1)*xMargin - 2*sideMargin)/roomsPerRow;
  NSInteger height = width;
  
  

  
  
  BOOL atBottom = false;
  
  for (Room *theRoom in [house roomList]) {
    UIImage *btnImage = theRoom.image;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [[button imageView] setContentMode:UIViewContentModeScaleAspectFit];
    
    UIButton *buttonText = [UIButton buttonWithType:UIButtonTypeSystem];
    [button addTarget:self
               action:@selector(roomPressed:)
     forControlEvents:UIControlEventTouchUpInside];
    [buttonText addTarget:self
               action:@selector(roomPressed:)
     forControlEvents:UIControlEventTouchUpInside];
    [buttonText setTitle:theRoom.name forState:UIControlStateNormal];
    [button setImage:btnImage forState:UIControlStateNormal];
    [buttonText setTitle:theRoom.name forState:UIControlStateHighlighted];
    [button setImage:btnImage forState:UIControlStateHighlighted];
    [buttonText setTitle:theRoom.name forState:UIControlStateSelected];
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
    if (columnCounter == roomsPerRow) {
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
  //[self.scrollView setContentOffset:CGPointMake(0, -self.scrollView.contentInset.top) animated:YES];
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


- (void)groupPressed:(id)sender {
  NSLog(@"Pressed group");
  [self performSegueWithIdentifier:@"GroupSegue" sender:self];
}

- (void)roomPressed:(id)sender {
  if (![[house roomList] objectAtIndex:[sender tag]]) return;
  currentRoom = [[house roomList] objectAtIndex:[sender tag]];
  NSLog(@"Pressed room with tag: %@", currentRoom.name);
  
  [self performSegueWithIdentifier:@"DeviceSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  // Make sure your segue name in storyboard is the same as this line
  if ([[segue identifier] isEqualToString:@"DeviceSegue"])
  {
    // Get reference to the destination view controller
    DeviceViewController *vc = [segue destinationViewController];
    
    // Pass any objects to the view controller here, like...
    [vc setRoom:currentRoom];
  }
}

-(void)handlePan:(id)sender {
  if (DEBUG) NSLog(@"Go to connection!");
  
  
  [self performSegueWithIdentifier:@"ConnectionSegue" sender:self];
  
  [[SyncManager sharedSyncManager] syncNow];
  /*
  
  if (!transition) {
    transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    [self.view.window.layer addAnimation:transition forKey:nil];
    
    [[SyncManager sharedSyncManager] syncNow];
    [self dismissViewControllerAnimated:NO completion:nil];
  }*/
}

-(void)activateVoice:(id)sender {
  [[HouseSyncer sharedHouseSyncer] activateSiri];
}

@end
