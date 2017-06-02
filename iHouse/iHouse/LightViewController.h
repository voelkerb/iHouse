//
//  LightViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Light.h"
#import "OnOffSwitchControlCell.h"
#import "DragDropImageView.h"

@class IDevice;

@interface LightViewController : NSViewController<NSCopying>

// The pointer to the device
@property (strong) IDevice *iDevice;

// The toggle button
@property (weak) IBOutlet OnOffSwitchControlCell *switchButton;
// The image of the light
@property (weak) IBOutlet DragDropImageView *lightImage;
// The name of the ligjt
@property (weak) IBOutlet NSTextField *lightName;
// The backview wit the color of the device
@property (weak) IBOutlet NSView *backView;

// The device needs to be initiated with an idevice
- (id) initWithDevice:(IDevice *) theLightDevice;

// If the user pressed the toggle button
- (IBAction)toggleLight:(id)sender;

@end
