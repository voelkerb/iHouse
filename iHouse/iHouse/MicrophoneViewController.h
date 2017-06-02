//
//  MicrophoneViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Microphone.h"

@class IDevice;
@interface MicrophoneViewController : NSViewController<NSCopying>

// The device
@property (strong) IDevice *iDevice;

// The Image of the micro
@property (weak) IBOutlet NSImageView *microImage;
// The name of the micro
@property (weak) IBOutlet NSTextField *nameLabel;
// The backview of the view in the color of the device
@property (weak) IBOutlet NSView *backView;
// Some status messages of the micro
@property (weak) IBOutlet NSTextField *statusMsgLabel;
// The button for toggleing the speaker and micro
@property (weak) IBOutlet NSButton *speakerToggleButton;

- (id) initWithDevice:(IDevice*) theMicrophoneDevice;

-(IBAction)toggleAudio:(id)sender;

@end
