//
//  InfraredDeviceViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "InfraredDevice.h"
#import "NSFlippedView.h"

@class IDevice;

@interface InfraredDeviceViewController : NSViewController<NSCopying> {
  NSMutableArray *viewControllers;
}

// The pointer to the device
@property (strong) IDevice *iDevice;
// The backview with the color of the device
@property (weak) IBOutlet NSFlippedView *flippedBackView;

// The device needs to be initiated with an idevice
- (id) initWithDevice:(IDevice *) theDevice;

@end
