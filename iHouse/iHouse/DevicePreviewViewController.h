//
//  DevicePreviewViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 04/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IDevice.h"

@interface DevicePreviewViewController : NSViewController

// The device to preview
@property (strong) IDevice *device;
// The view in which the device will be previewd
@property (weak) IBOutlet NSView* previewView;
// The viewcontroller storing the device view
@property (strong) NSViewController* previewViewController;

- (id)initWithDevice:(IDevice*) theDevice;
@end
