//
//  RoomPreferenceViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 19/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "RoomPreferenceViewController.h"
#import "MainAppRoomViewController.h"

#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NAME_EXISTS_MESSAGE @"A room with the selected name already exists."
#define ALERT_NAME_EXISTS_MESSAGE_INFORMAL @"Please select a different name."

@interface RoomPreferenceViewController ()

@end

@implementation RoomPreferenceViewController
@synthesize room, previewView, nameTextField, colorWell, imageView, delegate, roomViewController;

/*
 * Init the Room properly with object
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
                                    room: (Room *)theRoom {
  
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  
  if (self) {
    // Store name for further processing
    room = theRoom;
  }
  
  return self;
}

- (void)viewDidLoad {
  // Show the alpha slider of the color panel
  [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
  
  // Set values of the room
  [nameTextField setStringValue:[room name]];
  [colorWell setColor:[room color]];
  [imageView setImage:[room image]];

  
  roomViewController = [[MainAppRoomViewController alloc] initWithNibName:@"MainAppRoomView" bundle:nil room:room];
  [[roomViewController view] setFrame:[previewView bounds]];
  [[roomViewController view] setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [previewView addSubview:[roomViewController view]];
  
  [super viewDidLoad];
}


/*
 * If name did change
 */
- (IBAction)nameTextFieldChanged:(id)sender {
  BOOL nameExist = false;
  House *theHouse = [House sharedHouse];
  for (Room *theRoom in [theHouse rooms]) {
    // If room with this name already exist, choose different one
    if ([[theRoom name] isEqualToString:[nameTextField stringValue]] && theRoom != room) {
      // Make alert sheet to display that the room already exist
      NSAlert *alert = [[NSAlert alloc] init];
      [alert addButtonWithTitle:ALERT_BUTTON_OK];
      [alert setMessageText:ALERT_NAME_EXISTS_MESSAGE];
      [alert setInformativeText:ALERT_NAME_EXISTS_MESSAGE_INFORMAL];
      [alert setAlertStyle:NSWarningAlertStyle];
      [nameTextField setStringValue:[room name]];
      [alert runModal];
      nameExist = true;
    }
  }
  // else just change name of it
  if (!nameExist) {
    room.name = [nameTextField stringValue];
    [delegate roomDidChange];
    [[NSNotificationCenter defaultCenter] postNotificationName:RoomNameDidChange object:room];
  }
}

/*
 * If image did change
 */
- (IBAction)imageChanged:(id)sender {
  room.image = [imageView image];
  [delegate roomDidChange];
  [[NSNotificationCenter defaultCenter] postNotificationName:RoomImageDidChange object:room];
}

/*
 * If color did change
 */
- (IBAction)colorChanged:(id)sender {
  room.color = [colorWell color];
  [delegate roomDidChange];
  [[NSNotificationCenter defaultCenter] postNotificationName:RoomBackgroundDidChange object:room];
}

@end
