//
//  RoomListViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 16/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "RoomListViewController.h"
#define STANDARD_ROOM_ICON @"roomBold_256.png"
#define STANDARD_ROOM_NAME @"New Room"
#define STANDARD_ROOM_COLOR [NSColor clearColor]
#define NO_ROOM_LABEL @"Press \"+\" to add a Room"

@interface RoomListViewController ()

@end

@implementation RoomListViewController
@synthesize sideBarTableView, currentView, roomPreferenceViewController, house, emptyView;


- (void)viewDidLoad {
  [super viewDidLoad];
  // Do view setup here.
  
  // Init the house singletone
  house = [House sharedHouse];
  
  // Init SideBar to contain all rooms of house
  [self initSideBarTable];
  
  // If rooms exist, set view and selection
  if ([[house rooms] count] != 0) {
    lastRoom = -1;
    [self changedSideBarTableAndView:0];
  // draw emptyview
  } else {
    lastRoom = -1;
    [emptyView setFrame:[currentView bounds]];
    [emptyView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [currentView addSubview:emptyView];
  }
}

/*
 * Init the content of the sidebar, the pictures and names from the rooms and the general "tab"
 */
- (void) initSideBarTable {
  // Select the generl item in the table View
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
  //[sideBarTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
  [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
  
  // The Sidebar is a tableview, just set its background color accordingly
  //[sideBarTableView setBackgroundColor:SIDEBAR_STYLE];
}

- (IBAction)addRoom:(id)sender {
  // Add a new room with standard color
  Room *newRoom = [[Room alloc] init];
  newRoom.image = [NSImage imageNamed:STANDARD_ROOM_ICON];
  newRoom.name = STANDARD_ROOM_NAME;
  newRoom.color = STANDARD_ROOM_COLOR;
  // Add it to the table view
  NSInteger count = 1;
  while (![house addRoom:newRoom :self]) {
    newRoom.name = [NSString stringWithFormat:@"%@ %li", STANDARD_ROOM_NAME, count];
    count++;
  }
  [sideBarTableView reloadData];
  
  [self changedSideBarTableAndView:[[house rooms] count]-1];
  // Post notification that others can do sth
  [[NSNotificationCenter defaultCenter] postNotificationName:RoomImageDidChange object:nil];
}

- (IBAction)removeRoom:(id)sender {
  //NSLog(@"%li", [sideBarTableView selectedRow]);
  
  // If no room in list or nothing selected, return
  if ([[house rooms] count] == 0 || [sideBarTableView selectedRow] < 0) return;
  
  // Remove current selected Room
  [house removeRoom:[[house rooms][sideBarTableView.selectedRow] name] :self];
  // If no room in list anymore
  if ([[house rooms] count] == 0) {
    // Remove all Subviews
    NSArray* thisPageSubviews = [currentView subviews];
    for(NSView* thisPageSubview in thisPageSubviews) {
      [thisPageSubview removeFromSuperview];
    }
    // draw empty room view
    [emptyView setFrame:[currentView bounds]];
    [emptyView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [currentView addSubview:emptyView];
    lastRoom = -1;
  // else automatically select the new inserted room
  }
  // Reload data
  [sideBarTableView reloadData];
  // Post notification that sth changed
  [[NSNotificationCenter defaultCenter] postNotificationName:RoomImageDidChange object:nil];
  
  // Select the row and show the corresponding view
  if ([[house rooms] count] > [sideBarTableView selectedRow]) {
    [self changedSideBarTableAndView:[sideBarTableView selectedRow]];
  } else if ([[house rooms] count] > 0) {
    [self changedSideBarTableAndView:[[house rooms] count]-1];
  }
}




/*
 * Action performed by clicking object in sidebar table view
 */
// Store last SideBarRow
NSInteger lastRoom = -1;

- (IBAction)changedSideBarTable:(id)sender {
  [self changedSideBarTableAndView:[sender selectedRow]];
}

/*
 * Called within code
 */
- (void)changedSideBarTableAndView:(NSInteger)row {
  // If it is the same row or no row just return, else we need to change the view
  if (row < 0 || row >= [[house rooms] count]) {
    // Let the last row be selected
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:lastRoom];
    [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
    return;
  }
  // If it was the last row selected do nothing
  if (row == lastRoom) return;
  else lastRoom = row;
  
  // Remove all Subviews
  NSArray* thisPageSubviews = [currentView subviews];
  for(NSView* thisPageSubview in thisPageSubviews) {
    [thisPageSubview removeFromSuperview];
  }
  // Open room view by passing by the room
  if ([[house rooms] count] != 0) {
    roomPreferenceViewController = [[RoomPreferenceViewController alloc] initWithNibName:@"RoomPreferenceView" bundle:nil room:[house rooms][row]];
    [roomPreferenceViewController setDelegate:self];
    [[roomPreferenceViewController view] setFrame:[currentView bounds]];
    [[roomPreferenceViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [currentView addSubview:[roomPreferenceViewController view]];
  }
  
  // Set it as selected
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:row];
  [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
}

// Delegate function if room changes to change name in tableview
- (void)roomDidChange {
  [sideBarTableView reloadData];
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:lastRoom];
  [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
}


#pragma TableView delegate methods

/*
 * Telling tableviews how many rows we have
 */
- (NSInteger)numberOfRowsInTableView:(nonnull NSTableView *)tableView {
  return [[house rooms] count];
}


/*
 * Fill information into table cell
 */
- (nullable NSView *)tableView:(nonnull NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
  // Get the object inside the row
  Room *theRoom = [house rooms][row];
  // Get the identifier of the table column (we have only 1 so basicly useless)
  NSString *identifier = [tableColumn identifier];
  // Compare if we are in right column
  if ([identifier isEqualToString:@"MainCell"]) {
    // Create the cell View and paste image and name into it
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
    [cellView.imageView setImage:[theRoom image]];
    [cellView.textField setStringValue:[theRoom name]];
    return cellView;
  }
  // Return nil if not matching or wrong row
  return nil;
}


@end
