//
//  RoomListViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 16/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RoomPreferenceViewController.h"
#import "House.h"

@interface RoomListViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, RoomPreferenceViewControllerDelegate> 

// The Sidebar with the list of rooms
@property (weak) IBOutlet NSTableView *sideBarTableView;

// The current view of the selected table item
@property (weak) IBOutlet NSView *currentView;

// The view if no room is preset
@property (weak) IBOutlet NSView *emptyView;

// The House object containing all rooms
@property (strong) House *house;

// The view controller for editing the preferences of the room
@property (strong) RoomPreferenceViewController *roomPreferenceViewController;

// Action from the room tableview
- (IBAction)changedSideBarTable:(id)sender;

// Action from adding a room
- (IBAction)addRoom:(id)sender;

// Action from remove a room
- (IBAction)removeRoom:(id)sender;
@end
