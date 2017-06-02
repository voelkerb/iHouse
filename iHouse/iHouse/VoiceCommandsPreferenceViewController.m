//
//  VoiceCommandsPreferenceView.m
//  iHouse
//
//  Created by Benjamin Völker on 22/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "VoiceCommandsPreferenceViewController.h"
#import "House.h"
#define DEBUG_VOICE_COMMAND_SETTINGS_VIEW 1

#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NAME_EXISTS_MESSAGE @"A voice command with the selected name already exists."
#define ALERT_NAME_EXISTS_MESSAGE_INFORMAL @"Please select a different name."

#define ACTIVE_IN_ROOM_STRING @"Active in room: "
#define ACTIVE_IN_ANY_ROOM_STRING @"Active in all rooms"
#define BOUND_TO_NO_DEVICE_STRING @""
#define BOUND_TO_DEVICE_STRING @"Bound to device: "
#define NO_VIEW_LABEL @"No view"
#define DEVICE_VIEW_LABEL @"Device view"
#define CUSTOM_VIEW_LABEL @"Custom image"

@interface VoiceCommandsPreferenceViewController ()

@end

@implementation VoiceCommandsPreferenceViewController
@synthesize voiceCommand, nameTextField, responsesTextView, commandTextField, deviceDependentViewUnbound;
@synthesize activeRoomLabel, deviceDependentEmptyView, deviceDependentView, deviceActionPopUp, boundDeviceLabel;
@synthesize viewPopUpButton, viewPopUpButtonUnbound, customReturnView, customReturnViewUnbound;

/*
 * Init the view properly with voice command.
 */
- (id)initWithVoiceCommand:(VoiceCommand *)theVoiceCommand {
  self = [super init];
  if (self) {
    // Store name for further processing
    voiceCommand = theVoiceCommand;
    // By default notifications are enabled
    postsNotification = true;
  }
  return self;
}

/*
 * Disables notifications.
 */
-(void)disableNotifications {
  postsNotification = false;
}

- (void)viewDidLoad {
  // Set values of the interactive command
  [nameTextField setStringValue:[voiceCommand name]];
  [commandTextField setStringValue:[voiceCommand command]];
  for (NSString *response in [voiceCommand responses]) {
    [responsesTextView setString:[NSString stringWithFormat:@"%@%@\n", [responsesTextView string], response]];
  }
  
  // Add an observer for the textview to get notified whenever the user changes the text
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responsesTextViewChanged:)
                                               name:NSTextDidChangeNotification object:responsesTextView];
  
  // Init the device dependent view
  [self initDeviceDependentView];
  
  // Init the device action popup
  [self initDeviceActionPopUp];
  
  // Init the viewPopup
  [self initViewPopUp];
  
  // Init the active room label and the device label
  if ([[[voiceCommand room] name] isEqualToString:VoiceCommandAnyRoom]) {
    [activeRoomLabel setStringValue:ACTIVE_IN_ANY_ROOM_STRING];
  } else {
    [activeRoomLabel setStringValue:[NSString stringWithFormat:@"%@%@", ACTIVE_IN_ROOM_STRING, [[voiceCommand room] name]]];
  }
  if (![voiceCommand handler]) {
    [boundDeviceLabel setStringValue:BOUND_TO_NO_DEVICE_STRING];
  } else {
    [boundDeviceLabel setStringValue:[NSString stringWithFormat:@"%@%@", BOUND_TO_DEVICE_STRING, [(IDevice*)[voiceCommand handler] name]]];
  }
  
  // init the custom return view
  if ([voiceCommand commandView] == voiceCommand_custom_view) {
    [customReturnView setHidden:NO];
    [customReturnView setImage:[voiceCommand image]];
    [customReturnView setAllowDrag:YES];
    [customReturnViewUnbound setHidden:NO];
    [customReturnViewUnbound setImage:[voiceCommand image]];
    [customReturnViewUnbound setAllowDrag:YES];
  } else {
    [customReturnView setHidden:YES];
    [customReturnViewUnbound setHidden:YES];
  }
  [super viewDidLoad];
}

/*
 * If name did change.
 */
- (IBAction)nameTextFieldChanged:(id)sender {
  BOOL nameExist = false;
  House *theHouse = [House sharedHouse];
  for (VoiceCommand *theVoiceCommand in [theHouse voiceCommands]) {
    // If voice command with this name already exist, choose different one
    if ([[theVoiceCommand name] isEqualToString:[nameTextField stringValue]] && theVoiceCommand != voiceCommand) {
      // Make alert sheet to display that the voice command already exist
      NSAlert *alert = [[NSAlert alloc] init];
      [alert addButtonWithTitle:ALERT_BUTTON_OK];
      [alert setMessageText:ALERT_NAME_EXISTS_MESSAGE];
      [alert setInformativeText:ALERT_NAME_EXISTS_MESSAGE_INFORMAL];
      [alert setAlertStyle:NSWarningAlertStyle];
      [nameTextField setStringValue:[voiceCommand name]];
      [alert runModal];
      nameExist = true;
    }
  }
  // else just change name of it
  if (!nameExist) {
    voiceCommand.name = [nameTextField stringValue];
    if (postsNotification) [[NSNotificationCenter defaultCenter] postNotificationName:VoiceCommandNameChanged object:voiceCommand];
  }
}

/*
 * If command text field changed.
 */
- (IBAction)commandTextFieldChanged:(id)sender {
  // Change the command of the voice command and post notification if needed
  if (DEBUG_VOICE_COMMAND_SETTINGS_VIEW) NSLog(@"Command: %@", [commandTextField stringValue]);
  [voiceCommand setCommand:[commandTextField stringValue]];
  if (postsNotification) [[NSNotificationCenter defaultCenter] postNotificationName:VoiceCommandChanged object:voiceCommand];
}

/*
 * If the responses text view changed
 */
- (void)responsesTextViewChanged:(NSNotification*)notification {
  // Get the text of the response view
  NSString *text = [responsesTextView string];
  // If no text return
  if (![text length]) return;
  // If the text does not end with a newline return
  if (![[text substringFromIndex:[text length]-1] isEqualToString:@"\n"]) return;
  // The text ends with a newline and is edited
  NSMutableArray *responses = [[NSMutableArray alloc] init];
  // Get all responses seperated by newline and store it in array
  while ([text rangeOfString:@"\n"].location != NSNotFound) {
    [responses addObject:[text substringToIndex:[text rangeOfString:@"\n"].location]];
    if (![text substringFromIndex:[text rangeOfString:@"\n"].location+1]) return;
    text = [text substringFromIndex:[text rangeOfString:@"\n"].location+1];
  }
  // Add response array to the voice command
  if (DEBUG_VOICE_COMMAND_SETTINGS_VIEW) NSLog(@"Responses: %@", responses);
  [voiceCommand setResponses:responses];
}

/*
 * Init the device dependent view.
 */
-(void)initDeviceDependentView {
  // If the voice command belongs to a device. Set the view to a device dependent view
  if ([voiceCommand handler]) {
    [deviceDependentView setFrame:[deviceDependentEmptyView bounds]];
    [deviceDependentView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [deviceDependentEmptyView addSubview:deviceDependentView];
  // Else set the view to a unbound device view
  } else {
    [deviceDependentViewUnbound setFrame:[deviceDependentEmptyView bounds]];
    [deviceDependentViewUnbound setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [deviceDependentEmptyView addSubview:deviceDependentViewUnbound];
  }
}

/*
 * Init the device action popup
 */
-(void)initDeviceActionPopUp {
  // Remove all items
  [deviceActionPopUp removeAllItems];
  // if the device has a handler
  if ([voiceCommand handler]) {
    // Tag variable
    int i = 0;
    // Get all readable actions from the iDevice
    for (NSString *readableAction in [(IDevice*)[voiceCommand handler] voiceCommandSelectorsReadable]) {
      // Add the readable action to the action popup and set the tag
      [deviceActionPopUp addItemWithTitle:readableAction];
      [[deviceActionPopUp itemWithTitle:readableAction] setTag:i];
      i++;
    }
    // Look if the device already has a action, if so, select this row
    i = 0;
    BOOL hasAction = false;
    for (NSString *action in [(IDevice*)[voiceCommand handler] voiceCommandSelectors]) {
      if ([action isEqualToString:[voiceCommand selector]]) {
        [deviceActionPopUp selectItemWithTag:i];
        hasAction = true;
      }
      i++;
    }
    // If it does not have an action yet, set the action to the first action
    if (!hasAction) [voiceCommand setSelector:[[(IDevice*)[voiceCommand handler] voiceCommandSelectors] firstObject]];
  }
}

/*
 * If the action popup changed and the voice command has a handler, set the new action.
 */
- (IBAction)deviceActionPopUpChanged:(id)sender {
  if ([voiceCommand handler]) {
    NSArray *selectors = [[NSArray alloc] initWithArray:[(IDevice*)[voiceCommand handler] voiceCommandSelectors]];
    [voiceCommand setSelector:[selectors objectAtIndex:[[deviceActionPopUp selectedItem] tag]]];
  }
}


/*
 * Init the view popup.
 */
-(void)initViewPopUp {
  // Add device view, no view and custom view option and set the tag.
  [viewPopUpButton removeAllItems];
  [viewPopUpButton addItemWithTitle:DEVICE_VIEW_LABEL];
  [[viewPopUpButton itemWithTitle:DEVICE_VIEW_LABEL] setTag:voiceCommand_device_view];
  [viewPopUpButton addItemWithTitle:NO_VIEW_LABEL];
  [[viewPopUpButton itemWithTitle:NO_VIEW_LABEL] setTag:voiceCommand_no_view];
  [viewPopUpButton addItemWithTitle:CUSTOM_VIEW_LABEL];
  [[viewPopUpButton itemWithTitle:CUSTOM_VIEW_LABEL] setTag:voiceCommand_custom_view];
  [viewPopUpButton selectItemWithTag:[voiceCommand commandView]];
  
  // For unbound devices ADD ONLY no view and custom view option and set the tag.
  [viewPopUpButtonUnbound removeAllItems];
  [viewPopUpButtonUnbound addItemWithTitle:NO_VIEW_LABEL];
  [[viewPopUpButtonUnbound itemWithTitle:NO_VIEW_LABEL] setTag:voiceCommand_no_view];
  [viewPopUpButtonUnbound addItemWithTitle:CUSTOM_VIEW_LABEL];
  [[viewPopUpButtonUnbound itemWithTitle:CUSTOM_VIEW_LABEL] setTag:voiceCommand_custom_view];
  [viewPopUpButtonUnbound selectItemWithTag:[voiceCommand commandView]];

}

/*
 * If the view popup changed set the commandview type of the command accordingly.
 */
- (IBAction)viewPopUpButtonChanged:(id)sender {
  [voiceCommand setCommandView:[[viewPopUpButton selectedItem] tag]];
  // If custom view was selected, enable the imagewell
  if ([voiceCommand commandView] == voiceCommand_custom_view) {
    [customReturnView setHidden:NO];
    if ([voiceCommand image]) [customReturnView setImage:[voiceCommand image]];
    [customReturnView setAllowDrag:YES];
  // Else disable the image well
  } else {
    [customReturnView setHidden:YES];
  }
}

/*
 * If the view popup for unbound device changed set the commandview type of the command accordingly.
 */
- (IBAction)viewPopUpButtonUnboundChanged:(id)sender {
  [voiceCommand setCommandView:[[viewPopUpButtonUnbound selectedItem] tag]];
  // If custom view was selected, enable the imagewell
  if ([voiceCommand commandView] == voiceCommand_custom_view) {
    [customReturnViewUnbound setHidden:NO];
    if ([voiceCommand image]) [customReturnViewUnbound setImage:[voiceCommand image]];
    [customReturnViewUnbound setAllowDrag:YES];
  // Else disable the image well
  } else {
    [customReturnViewUnbound setHidden:YES];
  }
}

/*
 * If the image for custom return changed, set the return image of the command.
 */
- (IBAction)customReturnViewChanged:(id)sender {
  if ([customReturnView image]) [voiceCommand setImage:[customReturnView image]];
}

/*
 * If the image for custom return on unbound devices changed, set the return image of the command.
 */
- (IBAction)customReturnViewUnboundChanged:(id)sender {
  if ([customReturnViewUnbound image]) [voiceCommand setImage:[customReturnViewUnbound image]];
}

@end
