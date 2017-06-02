//
//  TVViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IPadDisplay.h"

@class IDevice;
@interface IPadDisplayViewController : NSViewController

- (IBAction)dummy:(id)sender;

// The pointer to the device
@property (strong) IDevice *iDevice;

// The image of the device
@property (weak) IBOutlet NSImageView *deviceImage;
// The name of the device
@property (weak) IBOutlet NSTextField *deviceName;
// The backview with the color of the device
@property (weak) IBOutlet NSView *backView;


// The device needs to be initiated with an idevice
- (id) initWithDevice:(IDevice *) theDevice;

@end
