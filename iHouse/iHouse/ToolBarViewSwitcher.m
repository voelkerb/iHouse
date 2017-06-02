//
//  ToolBarViewSwitcher.m
//  iHouse
//
//  Created by Benjamin Völker on 06/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "ToolBarViewSwitcher.h"
#import "HouseViewController.h"
#import "DeviceListViewController.h"
#import "SettingsViewController.h"
#import "VoiceCommandsViewController.h"
#import "RoomListViewController.h"
#import "GroupViewController.h"

// The Tags for the differen toolbar items (they need to be defined in the XIB)
#define HOUSE_VIEW_TAG 1
#define VOICE_COMMANDS_VIEW_TAG 2
#define DEVICE_LIST_VIEW_TAG 3
#define SETTINGS_VIEW_TAG 4
#define ROOMS_VIEW_TAG 5
#define GROUP_VIEW_TAG 6


@implementation ToolBarViewSwitcher
@synthesize currentView, currentViewController;
@synthesize window, completeView;

-(void)awakeFromNib {
  [self changeViewController:ROOMS_VIEW_TAG];
}

/*
 * Action to switch the currentview called by the toolbarItems
 */
- (IBAction)changeView:(id)sender {
  NSInteger tag = [sender  tag];
  [self changeViewController:tag];
  
}

/*
 * Change the view according to the tag id and allocate the corresponding viewcontroller
 */
NSInteger lastTag = 0;
- (void)changeViewController:(NSInteger)tag {
  // Remove the currentView if we did not press the current active item
  if (tag == lastTag) return;
  else lastTag = tag;
  [[currentViewController view] removeFromSuperview];
  
  switch (tag) {
    case HOUSE_VIEW_TAG:
      currentViewController = [[HouseViewController alloc] initWithNibName:@"HouseView" bundle:nil];
      break;
    case DEVICE_LIST_VIEW_TAG:
      currentViewController = [[DeviceListViewController alloc] initWithNibName:@"DeviceListView" bundle:nil];
      break;
    case SETTINGS_VIEW_TAG:
      currentViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil];
      break;
    case VOICE_COMMANDS_VIEW_TAG:
      currentViewController = [[VoiceCommandsViewController alloc] initWithNibName:@"VoiceCommandsView" bundle:nil];
      break;
    case ROOMS_VIEW_TAG:
      currentViewController = [[RoomListViewController alloc] initWithNibName:@"RoomListView" bundle:nil];
      break;
    case GROUP_VIEW_TAG:
      currentViewController = [[GroupViewController alloc] initWithNibName:@"GroupView" bundle:nil];
      break;
  }
  // Set the view as a subview
  [currentView addSubview:[currentViewController view]];
  [[currentViewController view] setFrame:[currentView bounds]];
  [[currentViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
}


@end
