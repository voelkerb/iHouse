//
//  VoiceCommandsPreferenceView.h
//  iHouse
//
//  Created by Benjamin Völker on 22/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VoiceCommand.h"
#import "DragDropImageView.h"

@interface VoiceCommandsPreferenceViewController : NSViewController {
  // If notifications should be posted
  BOOL postsNotification;
}

// The voice command that is edited
@property (strong) VoiceCommand *voiceCommand;

// The name of the voice command
@property (weak) IBOutlet NSTextField *nameTextField;
// The command
@property (weak) IBOutlet NSTextField *commandTextField;
// The response text view containing all the voice responses seperated by "\n"
@property (unsafe_unretained) IBOutlet NSTextView *responsesTextView;
// The device dependent view that is empty
@property (weak) IBOutlet NSView *deviceDependentEmptyView;
// The device dependent view -> set in the empty frame if no unbound device
@property (strong) IBOutlet NSView *deviceDependentView;
// The not bound to a device view
@property (strong) IBOutlet NSView *deviceDependentViewUnbound;
// The device action popup displaying all available voice functions of the device
@property (weak) IBOutlet NSPopUpButton *deviceActionPopUp;
// The room label dispaying to what room the voice command is bound
@property (weak) IBOutlet NSTextField *activeRoomLabel;
// The device label displaying to what device the voice command is bound
@property (weak) IBOutlet NSTextField *boundDeviceLabel;
// The view popup showing the available view responses of the voice command (device view, no view, custom image)
@property (weak) IBOutlet NSPopUpButton *viewPopUpButton;
// The view popup for unbound devices displaying the available response view (no view, custom image)
@property (weak) IBOutlet NSPopUpButton *viewPopUpButtonUnbound;
// The image view displaying the custom response image
@property (weak) IBOutlet DragDropImageView *customReturnView;
// The image view displaying the custom response image for unbound devices
@property (weak) IBOutlet DragDropImageView *customReturnViewUnbound;

// The viewcontroller needs to be inited with a voice command
- (id)initWithVoiceCommand:(VoiceCommand *)theVoiceCommand;

// Name was changed
- (IBAction)nameTextFieldChanged:(id)sender;
// Command was changed
- (IBAction)commandTextFieldChanged:(id)sender;
// Device Action was changed
- (IBAction)deviceActionPopUpChanged:(id)sender;
// Response view type was changed
- (IBAction)viewPopUpButtonChanged:(id)sender;
// Response view type for unbound devices was changed
- (IBAction)viewPopUpButtonUnboundChanged:(id)sender;
// The custom response image was changed
- (IBAction)customReturnViewChanged:(id)sender;
// The custom response image for unbound devices was changed
- (IBAction)customReturnViewUnboundChanged:(id)sender;

// Disables all notifications
- (void)disableNotifications;

@end
