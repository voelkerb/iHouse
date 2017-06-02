//
//  MainAppViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 13/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MainAppGeneralViewController.h"
#import "MainAppRoomViewController.h"
#import "House.h"

// Notifications to enable and disable undocking
extern NSString* UndockNotificationEnable;
extern NSString* UndockNotificationDisable;

// The Functions the delegate has to implement
@protocol MainAppViewControllerDelegate <NSObject>

// The delegate needs to open the preference window
- (void) openPreferenceWindow;

@end

@interface MainAppViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate> {
  // The array holding the images of the sidebar
  NSMutableArray *sideBarContent;
  NSMutableArray *roomViewControllers;
  BOOL undockEnabled;
}

// The delegate variable
@property (weak) id<MainAppViewControllerDelegate> delegate;

// The House object containing all rooms
@property (strong) House *house;

// The top bar and side bar of the main view window (the darker ones)
@property (weak) IBOutlet NSView *topBar;
@property (weak) IBOutlet NSTableView *sideBarTableView;

// The date and time label in the top bar
@property (weak) IBOutlet NSTextField *currentDateTimeLabel;

// The current view of the selected table item
@property (weak) IBOutlet NSView *currentView;
@property (weak) IBOutlet NSButton *undockButton;

// The view controllers for the different selectable views
@property (strong) MainAppGeneralViewController *mainAppGeneralViewController;

- (IBAction)enableUndock:(id)sender;

- (IBAction)openPreferences:(id)sender;

- (IBAction)changedSideBarTable:(id)sender;
@end
