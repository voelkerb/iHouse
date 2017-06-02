//
//  GroupViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 15/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "House.h"
#import "EditGroupViewController.h"

@interface GroupViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, EditGroupViewControllerDelegate>

// The Sidebar with the list of groups
@property (weak) IBOutlet NSTableView *sideBarTableView;

// The current view of the selected table item
@property (weak) IBOutlet NSView *currentView;

// The view if no group is present
@property (weak) IBOutlet NSView *emptyView;

// The House object containing all groups
@property (strong) House *house;

// The view controller for editing the preferences of the roomgroup
@property (strong) EditGroupViewController *editGroupViewController;

// Action for the group tableview
- (IBAction)changedSideBarTable:(id)sender;

// Action from adding a group
- (IBAction)addGroup:(id)sender;

// Action from removing a group
- (IBAction)removeGroup:(id)sender;
@end
