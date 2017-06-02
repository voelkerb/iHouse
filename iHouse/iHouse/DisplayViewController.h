//
//  DisplayViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Display.h"
@class IDevice;

@interface DisplayViewController : NSViewController<NSCopying>

// The pointer to the device
@property (strong) IDevice *iDevice;

// The Image of the display
@property (weak) IBOutlet NSImageView *displayImage;
// The name of the display
@property (weak) IBOutlet NSTextField *nameLabel;
// The backview of the view in the color of the device
@property (weak) IBOutlet NSView *backView;
// A textfield for the warning message on the display
@property (weak) IBOutlet NSTextField *warningMsgTextField;
// A textfield fot the headline message
@property (weak) IBOutlet NSTextField *headlineMsgTextField;
// A textfield in which the name of an image stored on the displays SD card could be entered
@property (weak) IBOutlet NSTextField *imageNameTextField;

- (id) initWithDevice:(IDevice*) theDisplayDevice;
// To make a warning tone on the display
- (IBAction)beepPressed:(id)sender;
// To set a warning message on the display
- (IBAction)setWarning:(id)sender;
// To set the displays headline
- (IBAction)setHeadline:(id)sender;
// To set an image
- (IBAction)setImage:(id)sender;
// To reset the display to black
- (IBAction)resetDisplay:(id)sender;

@end
