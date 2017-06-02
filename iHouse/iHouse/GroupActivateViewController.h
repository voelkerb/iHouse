//
//  GroupActivateViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 16/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Group.h"
#import "DragDropImageView.h"

@interface GroupActivateViewController : NSViewController<NSCopying>

// The pointer to the device
@property (strong) Group *group;

// The toggle button
@property (weak) IBOutlet NSButton *switchButton;
// The image of the gorup
@property (weak) IBOutlet DragDropImageView *imageView;
// The name of the group
@property (weak) IBOutlet NSTextField *nameLabel;
// The backview wit the color of the group
@property (weak) IBOutlet NSView *backView;

// The group needs to be initiated with a group
- (id) initWithGroup:(Group *) theGroup;

// If the user pressed the toggle button
- (IBAction)toggleGroup:(id)sender;

@end
