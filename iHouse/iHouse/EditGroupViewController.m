//
//  EditGroupViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 15/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "EditGroupViewController.h"

#import "NSFlippedView.h"
#import "House.h"
#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NAME_EXISTS_MESSAGE @"A group with the selected name already exists."
#define ALERT_NAME_EXISTS_MESSAGE_INFORMAL @"Please select a different group."

@interface EditGroupViewController ()

@end

@implementation EditGroupViewController
@synthesize delegate;
@synthesize nameTextField, imageView, group, devicesAndActionsScrollView;

/*
 * Init with the current group
 */
-(id)initWithGroup:(Group *)theGroup {
  if (self = [super init]) {
    group = theGroup;
  }
  return self;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  viewControllers = [[NSMutableArray alloc] init];
  [devicesAndActionsScrollView setBorderType:NSNoBorder];
  
  // Set values of the room
  [nameTextField setStringValue:[group name]];
  [imageView setImage:[group image]];
}

-(void)viewDidLayout {
  [self drawScrollView];
}


-(void)drawScrollView {
  // Remove all existing view controller from the array
  [viewControllers removeAllObjects];
  // Remove all subviews in the currentview
  NSArray *subviews = [[NSArray alloc] initWithArray:[[devicesAndActionsScrollView documentView] subviews]];
  for (NSView *view in subviews) [view removeFromSuperview];
  
  NSRect completeFrame = NSMakeRect(0, 0, devicesAndActionsScrollView.frame.size.width, 0);
  // Get the height of the complete documentview
  completeFrame.size.height = devicesAndActionsScrollView.frame.size.height;
  NSInteger heightPerTile = 40;
  NSInteger height = 0;
  if (group.groupItems.count*heightPerTile > completeFrame.size.height) {
    completeFrame.size.height = group.groupItems.count*heightPerTile;
  }
  
  // The documentview is flipped. 0,0 is in the upper left
  NSFlippedView *document = [[NSFlippedView alloc] initWithFrame:completeFrame];
  
  // The frame of each view
  NSRect viewFrame = NSMakeRect(0, height, devicesAndActionsScrollView.frame.size.width, heightPerTile);
  // Go through all views
  for (int i = 0; i < [[group groupItems] count]; i++) {
    // Set new height of frame and set the frame
    GroupItemEditView *groupItemEditView = [[GroupItemEditView alloc] initWithGroupItem:
                                            [[group groupItems] objectAtIndex:i] andNumber:i+1];
    groupItemEditView.delegate = self;
    [groupItemEditView.view setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
    [groupItemEditView.view setFrame:viewFrame];
    [viewControllers addObject:groupItemEditView];
    
    // Set The bgColor
    if (i%2 == 0) {
      CALayer *viewLayer = [CALayer layer];
      [viewLayer setBackgroundColor:[[NSColor colorWithCalibratedRed:0.3f green:0.3f blue:0.3f alpha:0.05] CGColor]];
      [groupItemEditView.view setWantsLayer:YES];
      [groupItemEditView.view setLayer:viewLayer];
    }
    
    // Add the view to the scrollview
    [document addSubview:[groupItemEditView view]];
    // Increment y value for next view
    viewFrame.origin.y += heightPerTile;
  }
  
  [devicesAndActionsScrollView setDocumentView:document];
}

/*
 * If name did change
 */
- (IBAction)nameTextFieldChanged:(id)sender {
  BOOL nameExist = false;
  House *theHouse = [House sharedHouse];
  for (Group *theGroup in [theHouse groups]) {
    // If room with this name already exist, choose different one
    if ([[theGroup name] isEqualToString:[nameTextField stringValue]] && theGroup != group) {
      // Make alert sheet to display that the room already exist
      NSAlert *alert = [[NSAlert alloc] init];
      [alert addButtonWithTitle:ALERT_BUTTON_OK];
      [alert setMessageText:ALERT_NAME_EXISTS_MESSAGE];
      [alert setInformativeText:ALERT_NAME_EXISTS_MESSAGE_INFORMAL];
      [alert setAlertStyle:NSWarningAlertStyle];
      [nameTextField setStringValue:[group name]];
      [alert runModal];
      nameExist = true;
    }
  }
  // else just change name of it
  if (!nameExist) {
    group.name = [nameTextField stringValue];
    if (delegate) [delegate groupDidChange];
    [[NSNotificationCenter defaultCenter] postNotificationName:GroupChanged object:group];
  }
}

-(void)groupItemRemoved:(id)sender {
  NSInteger number = [viewControllers indexOfObject:sender];
  if (number >= 0 && number < [[group groupItems] count]) {
    [[group groupItems] removeObjectAtIndex:number];
    [self drawScrollView];
  }
}

/*
 * If image did change
 */
- (IBAction)imageChanged:(id)sender {
  group.image = [imageView image];
  if (delegate) [delegate groupDidChange];
  [[NSNotificationCenter defaultCenter] postNotificationName:GroupChanged object:group];
}

-(IBAction)addGroupItem:(id)sender {
  [group addDevice];
  [self drawScrollView];
}

- (IBAction)testGroup:(id)sender {
  [group activate];
}

@end
