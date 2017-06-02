//
//  InfraredCommandViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 20/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "InfraredCommandViewController.h"
#import "DragDropImageView.h"
#import "InfraredDevice.h"

#define DEBUG_INFRARED_COMMAND_VIEW 1



#define ALERT_BUTTON_SAVE @"Save"
#define ALERT_BUTTON_CANCEL @"Cancel"
#define ALERT_BUTTON_LEARN @"Learn"
#define ALERT_BUTTON_DELETE @"Delete"
#define ALERT_EDIT_MESSAGE @"Edit Infrared Command"
#define ALERT_EDIT_MESSAGE_INFORMAL @"Change the name and the image of the infrared command. Press learn and then the corresponding button on the remote."


#define ALERT_EDIT_REPEATED_TITLE @"Repeated Sends:"
#define ALERT_EDIT_IMAGE_BOX_TITLE @"Drag image:"
#define ALERT_EDIT_ERROR_MESSAGE @"Name not set"
#define ALERT_EDIT_ERROR_MESSAGE_INFROMAL @"You did not change the name. To save a valid voice command, please enter a name for the command or press cancel to leave this a placeholder."

#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NO_CONNECTION_MESSAGE @"IR device not connected"
#define ALERT_NO_CONNECTION_MESSAGE_INFORMAL @"Connect an iHouse IR device to enable this feature."


#define ALERT_LEARN_MESSAGE @"Learning"
#define ALERT_LEARN_MESSAGE_INFORMAL @"Press the button on the IR remote that should be learned."

@interface InfraredCommandViewController ()

@end

@implementation InfraredCommandViewController
@synthesize irCommand, toggleButton, editButton;


-(id)initWithIRCommand:(InfraredCommand *)theIRCommand :(BOOL)isEditView {
  if (self = [super init]) {
    irCommand = theIRCommand;
    editView = isEditView;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:IRCommandImageChanged object:nil];
  }
  return self;
}

// If the device was edited, we need to redraw
-(void)reDraw:(NSNotification*)notification {
  // If the sender is the iDevice or the ir device, redraw
  if ([irCommand isEqualTo:[notification object]]) {
    [self viewDidLoad];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do view setup here.
  [toggleButton setImage:[irCommand image]];
  
  if ([[irCommand name] isEqualToString:IRCommandEmptyCommand]) [toggleButton setBordered:NO];
  // Decide wether this is a edit view or not
  if (editView) {
    [toggleButton setEnabled:NO];
    [editButton setTransparent:NO];
    [editButton setHidden:NO];
  } else {
    [toggleButton setEnabled:YES];
    [editButton setTransparent:YES];
    [editButton setHidden:YES];
    if (![[irCommand name] isEqualToString:IRCommandEmptyCommand]) [toggleButton setSound:[NSSound soundNamed:@"Pop"]];
  }
}

/*
 * If the user pressed the editButton
 */
- (IBAction)editButtonPressed:(id)sender {
  if(DEBUG_INFRARED_COMMAND_VIEW) NSLog(@"Edit Button of %@ pressed", [irCommand name]);
  [self showEditDeviceAlert];
}

/*
 * If the user pressed the toggleButton
 */
- (IBAction)toggleButtonPressed:(id)sender {
  if ([[irCommand name] isEqualToString:IRCommandEmptyCommand]) return;
  if(DEBUG_INFRARED_COMMAND_VIEW) NSLog(@"toggle Button of %@ pressed", [irCommand name]);
  if ([self checkConnected]) [irCommand toggle];
}

/*
 * Shows an alert where the user can edit the infrared command
 */
-(void)showEditDeviceAlert {
  
  NSBox *imageBox = [[NSBox alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
  // The image of the current device embedded in an nsbox
  DragDropImageView *image = [[DragDropImageView alloc] initWithFrame:[imageBox contentView].frame];
  [image setImage:[irCommand image]];
  image.allowDrag = true;
  image.allowDrop = true;
  imageBox.contentView = image;
  [imageBox setTitle:ALERT_EDIT_IMAGE_BOX_TITLE];
  
  // The name of the current device, position left
  NSTextField *nameTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 110, 120, 24)];
  [nameTextField setStringValue:[irCommand name]];
  
  NSTextField *repeatTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(120, 0, 105, 24)];
  [repeatTextField setStringValue:ALERT_EDIT_REPEATED_TITLE];
  [repeatTextField setBezeled:NO];
  [repeatTextField setDrawsBackground:NO];
  [repeatTextField setEditable:NO];
  [repeatTextField setSelectable:NO];
  NSPopUpButton *repeatsAlertPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(225, 2, 50, 24)];
  // Init with unbound sensor devices that are known yet
  //NSString *repeatCountNow = [NSString stringWithFormat:@"%li", [irCommand repeatCount]];
  for (int i = 1; i < 10; i++) {
    [repeatsAlertPopup addItemWithTitle:[NSString stringWithFormat:@"%i", i]];
  }
  [repeatsAlertPopup selectItemAtIndex:[irCommand repeatCount]-1];
  
  // The learn button to press, position is right next to name text field
  NSButton *learnButton = [[NSButton alloc] initWithFrame:NSMakeRect(130, 110, 70, 24)];
  
  [learnButton setBezelStyle:NSRoundedBezelStyle];
  [learnButton setButtonType:NSMomentaryPushInButton];
  [learnButton setTitle:ALERT_BUTTON_LEARN];
  [learnButton setTarget:self];
  [learnButton setAction:@selector(learnDevice:)];
  NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 280, 134)];
  NSArray *array = [NSArray arrayWithObjects:imageBox, nameTextField, learnButton, repeatsAlertPopup, repeatTextField, nil];
  [view setSubviews:array];
  
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:ALERT_EDIT_MESSAGE];
  [alert setInformativeText:ALERT_EDIT_MESSAGE_INFORMAL];
  [alert addButtonWithTitle:ALERT_BUTTON_SAVE];
  [alert addButtonWithTitle:ALERT_BUTTON_CANCEL];
  [alert addButtonWithTitle:ALERT_BUTTON_DELETE];
  [alert setAccessoryView:view];
  
  //[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(editDeviceAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
  
  long returnCode = [alert runModal];
  
  if (returnCode == 1000) {
    if (DEBUG_INFRARED_COMMAND_VIEW) NSLog(@"Save pressed");
    // Get the new name and the new image out of the acessory view
    NSArray *array = [[alert accessoryView] subviews];
    DragDropImageView *imageView = (DragDropImageView*)[(NSBox*)[array objectAtIndex:0] contentView];
    NSTextField *nameTextField = (NSTextField*)[array objectAtIndex:1];
    NSPopUpButton *repeatCountPop = (NSPopUpButton*)[array objectAtIndex:3];
    NSInteger repeatCountValue = [[[repeatCountPop selectedItem] title] integerValue];
    if (DEBUG_INFRARED_COMMAND_VIEW) NSLog(@"Repeated: %li", repeatCountValue);
    if (repeatCountValue > 0 && repeatCountValue < 10 && repeatCountValue != [irCommand repeatCount]) {
      [irCommand setRepeatCount:repeatCountValue];
    }
    if (![[[imageView image] name] isEqualToString:[[irCommand image] name]]) {
      [irCommand setImage:[imageView image]];
      // Let View redraw
      [[NSNotificationCenter defaultCenter] postNotificationName:IRCommandImageChanged object:irCommand];
    }
    // If name is empty, this is not a valid ir command display message
    if ([[nameTextField stringValue] isEqualToString:IRCommandEmptyCommand]) {
      NSAlert *alert = [[NSAlert alloc] init];
      [alert setMessageText:ALERT_EDIT_ERROR_MESSAGE];
      [alert setInformativeText:ALERT_EDIT_ERROR_MESSAGE_INFROMAL];
      [alert addButtonWithTitle:ALERT_BUTTON_OK];
      [alert runModal];
      // Reshow this alert
      [self showEditDeviceAlert];
    } else {
      // Look if name chganged and only than post the notification because otherwise this is useless
      if (![[irCommand name] isEqualToString:[nameTextField stringValue]]) {
        [irCommand setName:[nameTextField stringValue]];
        // Post notification that name and so on changed
        [[NSNotificationCenter defaultCenter] postNotificationName:IRDeviceCountChanged object:irCommand.delegate];
      }
    }
  } else if (returnCode == 1001) {
    if (DEBUG_INFRARED_COMMAND_VIEW) NSLog(@"Cancel pressed");
  } else if (returnCode == 1002) {
    if (DEBUG_INFRARED_COMMAND_VIEW) NSLog(@"Delete pressed");
    // If delete is pressed, delete the command
    [irCommand deleteCommand];
  }
}

/*
 * If the user wants to learn a new infrared command.
 */
-(void)learnDevice:(id)sender {
  if(DEBUG_INFRARED_COMMAND_VIEW) NSLog(@"Learn Button of %@ pressed", [irCommand name]);
  // Look if connected, if not return
  if (![self checkConnected]) return;
  // Add ab observer for succesfully learned new command so that the learn alert message can be closed on success
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(learnFinished:) name:IRCommandLearnedSuccessfully object:nil];
  // Start learning the command
  [irCommand learnCommand];
  // Alloc new learn alert
  learnAlert = [[NSAlert alloc] init];
  [learnAlert setMessageText:ALERT_LEARN_MESSAGE];
  [learnAlert setInformativeText:ALERT_LEARN_MESSAGE_INFORMAL];
  [learnAlert addButtonWithTitle:ALERT_BUTTON_CANCEL];
  long returnCode = [learnAlert runModal];
  // If cancel was pressed, stop learning
  if (returnCode == 1000) {
    if (DEBUG_INFRARED_COMMAND_VIEW) NSLog(@"Cancel pressed");
    [irCommand stopLearning];
  }
  // Remove the observer on finish
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
 * Called if a new code was learned successfully.
 */
-(void)learnFinished:(NSNotification*)notification {
  // If a new code was learned succesfully and the learned command was our command, close the learn alert window and remove the obsever
  if ([[notification object] isEqualTo:irCommand]) {
    [NSApp endSheet: [learnAlert window]];
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
 * Checks if the Device is connected over tcp.
 */
- (BOOL)checkConnected {
  if ([irCommand isConnected]) return true;
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:ALERT_NO_CONNECTION_MESSAGE];
  [alert setInformativeText:ALERT_NO_CONNECTION_MESSAGE_INFORMAL];
  [alert addButtonWithTitle:ALERT_BUTTON_OK];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
  return false;
}
@end
