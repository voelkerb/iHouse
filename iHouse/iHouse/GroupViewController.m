//
//  GroupViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 15/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "GroupViewController.h"
#define STANDARD_GROUP_NAME @"new group"

@implementation GroupViewController
@synthesize sideBarTableView, currentView, editGroupViewController, house, emptyView;


- (void)viewDidLoad {
  [super viewDidLoad];
  // Do view setup here.
  
  // Init the house singletone
  house = [House sharedHouse];
  
  // Init SideBar to contain all groups of house
  [self initSideBarTable];
  
  // If group exist, set view and selection
  if ([[house groups] count] != 0) {
    lastGroup = -1;
    [self changedSideBarTableAndView:0];
    // draw emptyview
  } else {
    lastGroup = -1;
    [emptyView setFrame:[currentView bounds]];
    [emptyView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [currentView addSubview:emptyView];
  }
}

/*
 * Init the content of the sidebar, the pictures and names from the groups
 */
- (void) initSideBarTable {
  // Select the generl item in the table View
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
  //[sideBarTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
  [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
  
  // The Sidebar is a tableview, just set its background color accordingly
  //[sideBarTableView setBackgroundColor:SIDEBAR_STYLE];
}

- (IBAction)addGroup:(id)sender {
  // Add a new group with standard values
  Group *newGroup = [[Group alloc] init];
  // Add it to the table view
  NSInteger count = 1;
  while (![house addGroup:newGroup :self]) {
    newGroup.name = [NSString stringWithFormat:@"%@ %li", STANDARD_GROUP_NAME, count];
    count++;
  }
  [sideBarTableView reloadData];
  
  [self changedSideBarTableAndView:[[house groups] count]-1];
  // Post notification that others can do sth
  [[NSNotificationCenter defaultCenter] postNotificationName:GroupAdded object:nil];
}

- (IBAction)removeGroup:(id)sender {
  //NSLog(@"%li", [sideBarTableView selectedRow]);
  
  // If no group in list or nothing selected, return
  if ([[house groups] count] == 0 || [sideBarTableView selectedRow] < 0) return;
  
  // Remove current selected Group
  [house removeGroup:[[house groups][sideBarTableView.selectedRow] name] :self];
  // If no group in list anymore
  if ([[house groups] count] == 0) {
    // Remove all Subviews
    NSArray* thisPageSubviews = [currentView subviews];
    for(NSView* thisPageSubview in thisPageSubviews) {
      [thisPageSubview removeFromSuperview];
    }
    // draw empty group view
    [emptyView setFrame:[currentView bounds]];
    [emptyView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [currentView addSubview:emptyView];
    lastGroup = -1;
    // else automatically select the new inserted room
  }
  // Reload data
  [sideBarTableView reloadData];
  // Post notification that sth changed
  [[NSNotificationCenter defaultCenter] postNotificationName:GroupRemoved object:nil];
  
  // Select the row and show the corresponding view
  if ([[house groups] count] > [sideBarTableView selectedRow]) {
    [self changedSideBarTableAndView:[sideBarTableView selectedRow]];
  } else if ([[house groups] count] > 0) {
    [self changedSideBarTableAndView:[[house groups] count]-1];
  }
}




/*
 * Action performed by clicking object in sidebar table view
 */
// Store last SideBarRow
NSInteger lastGroup = -1;

- (IBAction)changedSideBarTable:(id)sender {
  [self changedSideBarTableAndView:[sender selectedRow]];
}

/*
 * Called within code
 */
- (void)changedSideBarTableAndView:(NSInteger)row {
  // If it is the same row or no row just return, else we need to change the view
  if (row < 0 || row >= [[house groups] count]) {
    // Let the last row be selected
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:lastGroup];
    [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
    return;
  }
  // If it was the last row selected do nothing
  if (row == lastGroup) return;
  else lastGroup = row;
  
  // Remove all Subviews
  NSArray* thisPageSubviews = [currentView subviews];
  for(NSView* thisPageSubview in thisPageSubviews) {
    [thisPageSubview removeFromSuperview];
  }
  // Open group view by passing by the room
  if ([[house groups] count] != 0) {
    // TODO : add edit view
    editGroupViewController = [[EditGroupViewController alloc] initWithGroup:[house groups][row]];
    [editGroupViewController setDelegate:self];
    [[editGroupViewController view] setFrame:[currentView bounds]];
    [[editGroupViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [currentView addSubview:[editGroupViewController view]];
    
  }
  
  // Set it as selected
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:row];
  [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
}

// Delegate function if room changes to change name in tableview
- (void)groupDidChange {
  [sideBarTableView reloadData];
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:lastGroup];
  [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:NO];
}


#pragma TableView delegate methods

/*
 * Telling tableviews how many rows we have
 */
- (NSInteger)numberOfRowsInTableView:(nonnull NSTableView *)tableView {
  return [[house groups] count];
}


/*
 * Fill information into table cell
 */
- (nullable NSView *)tableView:(nonnull NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
  // Get the object inside the row
  Group *theGoup = [house groups][row];
  // Get the identifier of the table column (we have only 1 so basicly useless)
  NSString *identifier = [tableColumn identifier];
  // Compare if we are in right column
  if ([identifier isEqualToString:@"MainCell"]) {
    // Create the cell View and paste image and name into it
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
    [cellView.imageView setImage:[theGoup image]];
    [cellView.textField setStringValue:[theGoup name]];
    return cellView;
  }
  // Return nil if not matching or wrong row
  return nil;
}

@end
