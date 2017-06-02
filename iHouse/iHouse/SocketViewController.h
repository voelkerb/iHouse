//
//  SocketViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Socket.h"
#import "OnOffSwitchControl.h"
#import "DragDropImageView.h"

@class IDevice;

@interface SocketViewController : NSViewController<NSCopying>
// The pointer to the device
@property (strong) IDevice *iDevice;

// The toggle button
@property (weak) IBOutlet OnOffSwitchControl *switchButton;
// The image of the socket
@property (weak) IBOutlet DragDropImageView *socketImage;
// The name of the socket
@property (weak) IBOutlet NSTextField *socketName;
// The backview with the bg color
@property (weak) IBOutlet NSView *backView;

// This controller needs to be initiated with a socket device
- (id) initWithDevice:(IDevice*) theSocketDevice;

// If the user pressed the toggle button
- (IBAction)toggleSocket:(id)sender;

@end
