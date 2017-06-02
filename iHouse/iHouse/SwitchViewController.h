//
//  SwitchViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 12.02.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DragDropImageView.h"

@class IDevice;
@interface SwitchViewController : NSViewController<NSCopying>

// The pointer to the device
@property (strong) IDevice *iDevice;

// The image of the switch
@property (weak) IBOutlet DragDropImageView *switchImage;
// The name of the switch
@property (weak) IBOutlet NSTextField *switchName;
// The backview with the bg color
@property (weak) IBOutlet NSView *backView;

// This controller needs to be initiated with a switch device
- (id) initWithDevice:(IDevice*) theSwitchDevice;



@end
