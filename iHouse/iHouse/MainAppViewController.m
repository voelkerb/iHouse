//
//  MainAppViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 13/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "MainAppViewController.h"

// The style of The bars
#define TOPBAR_STYLE CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.2)]
#define SIDEBAR_STYLE [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.2]
#define GENERAL_STRING @"General"
#define GENERAL_TYPE @"GENERAL"
#define ROOM_TYPE @"ROOM"
#define GENERAL_PICTURE @"houseBold_bright_256.png"
#define ACTIVATE_UNDOCK_IMAGE @"activateUndock_256.png"
NSString* UndockNotificationEnable = @"undockNotificationEnable";
NSString* UndockNotificationDisable = @"undockNotificationDisable";


@interface MainAppViewController ()

@end

@implementation MainAppViewController
@synthesize delegate;
@synthesize topBar, sideBarTableView;
@synthesize currentDateTimeLabel;
@synthesize mainAppGeneralViewController, currentView;
@synthesize house;
@synthesize undockButton;


- (void)viewDidLoad {
  [super viewDidLoad];
  // Not undockable at start
  undockEnabled = false;
  
  // Do view setup here.
  [self setUpBarStyles];
  // Update Time Label every Second
  [self updateTimeLabel];
  [NSTimer scheduledTimerWithTimeInterval:1.0
                                   target:self
                                 selector:@selector(updateTimeLabel)
                                 userInfo:nil
                                  repeats:YES];
  // Init the house and the connectionHandler
  house = [House sharedHouse];
  
  roomViewControllers = [[NSMutableArray alloc] init];
  for (Room *theRoom in [house rooms]) {
    MainAppRoomViewController *viewController = [[MainAppRoomViewController alloc] initWithNibName:@"MainAppRoomView" bundle:nil room:theRoom];
    [[viewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [roomViewControllers addObject:viewController];
  }
  
  // Check for room updates
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForRoomUpdate:) name:RoomImageDidChange object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForRoomUpdate:) name:RoomNameDidChange object:nil];
  
  // Init SideBar to contain general and room rows
  [self initSideBarTable];
  
  
  // Init the view Controller for the subview and set the currentview to generalView
  mainAppGeneralViewController = [[MainAppGeneralViewController alloc] initWithNibName:@"MainAppGeneralView" bundle:nil];
  [[mainAppGeneralViewController view] setFrame:[currentView bounds]];
  [[mainAppGeneralViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [currentView addSubview:[mainAppGeneralViewController view]];
}


/*
 * Init the content of the sidebar, the pictures and names from the rooms and the general "tab"
 */
- (void) initSideBarTable {
  // Init the sideBar images
  sideBarContent = [[NSMutableArray alloc] init];
  NSDictionary *obj = @{@"image": [NSImage imageNamed:GENERAL_PICTURE],
                        @"name" : GENERAL_STRING,
                        @"type" : GENERAL_TYPE};
  [sideBarContent addObject:obj];
  
  // Insert all available rooms
  for (Room *room in [house rooms]) {
    obj = @{@"type"  : ROOM_TYPE,
            @"room"  : room};
    [sideBarContent addObject:obj];
  }
  
  
  
  // Select the generl item in the table View
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
  [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:YES];
  
  
}

/*
 * Updates the time every second in the topbar
 */
- (void) updateTimeLabel {
  [currentDateTimeLabel setStringValue:[NSDateFormatter localizedStringFromDate:
                                        [NSDate date] dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterMediumStyle]];
}

/*
 * If name or image of room changed
 */
- (void) checkForRoomUpdate:(NSNotification*)notification {
  [self initSideBarTable];
  [sideBarTableView reloadData];
}

/*
 * Set up the design of the top bar
 */
- (void) setUpBarStyles {
  // Add the background layer of the topBar
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:TOPBAR_STYLE;
  [topBar setWantsLayer:YES];
  [topBar setLayer:viewLayer];
  // The Sidebar is a tableview, just set its background color accordingly
  [sideBarTableView setBackgroundColor:SIDEBAR_STYLE];
}

/*
 * Action performed by prefderence Button -> preference window should be opened by delegate
 */
- (IBAction)openPreferences:(id)sender {
  [delegate openPreferenceWindow];
}
   
   
/*
 * Action performed by clicking object in sidebar table view
 */
// Store last SideBarRow
NSInteger lastSideBarRow = 0;
- (IBAction)changedSideBarTable:(id)sender {
  // Get current Row
  NSInteger row = [sender selectedRow];
  // If it is the same row or no row just return, else we need to change the view
  if (row < 0 || row > [sideBarContent count]) {
    // Let the last row be selected
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:lastSideBarRow];
    [sideBarTableView selectRowIndexes:indexSet byExtendingSelection:YES];
    return;
  }
  if (row == lastSideBarRow) return;
  else lastSideBarRow = row;
  
  // Remove all Subviews
  NSArray* thisPageSubviews = [currentView subviews];
  for(NSView* thisPageSubview in thisPageSubviews) {
    [thisPageSubview removeFromSuperview];
  }
  // If type is GeneralView, open GeneralView
  if ([[sideBarContent[row] objectForKey:@"type"] isEqualToString:GENERAL_TYPE]) {
    [[mainAppGeneralViewController view] setFrame:[currentView bounds]];
    [[mainAppGeneralViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [currentView addSubview:[mainAppGeneralViewController view]];
  // If type is Room
  } else if ([[sideBarContent[row] objectForKey:@"type"] isEqualToString:ROOM_TYPE]) {
    // Search for the correct viewcontrolle for the selection and show it
    BOOL foundViewController = false;
    for (MainAppRoomViewController *viewController in roomViewControllers) {
      if ([viewController.room isEqualTo:[sideBarContent[row] objectForKey:@"room"]]) {
        [[viewController view] setFrame:[currentView bounds]];
        [currentView addSubview:[viewController view]];
        foundViewController = true;
      }
    }
    // If no viewcontroller is found, we must add it to the array because it was recently added
    if (!foundViewController) {
      MainAppRoomViewController *viewController = [[MainAppRoomViewController alloc] initWithNibName:@"MainAppRoomView" bundle:nil room:[sideBarContent[row] objectForKey:@"room"]];
      [[viewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
      [roomViewControllers addObject:viewController];
      [[viewController view] setFrame:[currentView bounds]];
      [currentView addSubview:[viewController view]];
    }
  }  
}

#pragma TableView delegate methods
   
/*
 * Telling tableviews how many rows we have
 */
- (NSInteger)numberOfRowsInTableView:(nonnull NSTableView *)tableView {
  return [sideBarContent count];
}


/*
 * Fill information into table cell
 */
- (nullable NSView *)tableView:(nonnull NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
  // Get the object inside the row
  NSDictionary *flag = sideBarContent[row];
  // Get the identifier of the table column (we have only 1 so basicly useless)
  NSString *identifier = [tableColumn identifier];
  // Compare if we are in right column
  if ([identifier isEqualToString:@"MainCell"]) {
    // Create the cell View and paste image and name into it
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
    if ([flag[@"type"] isEqualToString:ROOM_TYPE]) {
      [cellView.imageView setImage:[flag[@"room"] image]];
      [cellView.textField setStringValue:[flag[@"room"] name]];
      
    } else {
      [cellView.imageView setImage:flag[@"image"]];
      [cellView.textField setStringValue:flag[@"name"]];
    }
    // Make the background of the cell transparent
    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:[[NSColor clearColor] CGColor]]; //RGB plus Alpha Channel
    [cellView setWantsLayer:YES];
    [cellView setLayer:viewLayer];
    return cellView;
  }
  // Return nil if not matching or wrong row
  return nil;
}


   

- (IBAction)enableUndock:(id)sender {
  NSColor *tintColor = [NSColor whiteColor];
  if (undockEnabled) {
    [[NSNotificationCenter defaultCenter] postNotificationName:UndockNotificationDisable object:nil];
  } else {
    [[NSNotificationCenter defaultCenter] postNotificationName:UndockNotificationEnable object:nil];
    tintColor = [NSColor colorWithCalibratedRed:0.0 green:122.0f/255.0f blue:1.0f alpha:0.7f];
  }
  
  NSImage *template = [NSImage imageNamed:ACTIVATE_UNDOCK_IMAGE];
  [template setTemplate:YES];
  [undockButton setImage:nil];
  CALayer *maskLayer = [CALayer layer];
  [maskLayer setContents:template];
  [maskLayer setFrame:undockButton.bounds];
  [undockButton.layer setMask:maskLayer];
  [undockButton.layer setBackgroundColor:[tintColor CGColor]];
  
  undockEnabled = !undockEnabled;
}
@end
