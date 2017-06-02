//
//  DevicePreviewViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 04/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "DevicePreviewViewController.h"

@interface DevicePreviewViewController ()

@end

@implementation DevicePreviewViewController
@synthesize device, previewView, previewViewController;


- (id)initWithDevice:(IDevice *)theDevice {
  if (self = [super init]) {
    device = theDevice;
    // After 'a short' delay, draw the view centered, otherwise it is not centered because maybe the bounds are missing
    // This is kind of ugly but a quick workaround
    [self performSelector:@selector(drawViewCentered) withObject:nil afterDelay:0.05];
    [self performSelector:@selector(addFrameChangeObserver) withObject:nil afterDelay:0.11];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceChanged:) name:iDeviceDidChange object:nil];
  }
  return self;
}

/*
 * If the device was changed, redraw
 */
- (void)deviceChanged:(NSNotification*)notification {
  if ([[notification object] isEqualTo:device]) {
    [self drawViewCentered];
  }
}

/*
 * Add an observer which is called if the view changed
 */
- (void) addFrameChangeObserver {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(drawViewCentered)
                                               name:NSViewFrameDidChangeNotification
                                             object:self.view];
}

- (void)viewDidLoad {
  [super viewDidLoad];
}

/*
 * Draws the view centered in the preview view
 */
- (void) drawViewCentered {
  // Remove all views
  NSArray *subviews = [previewView subviews];
  for (NSView *theView in subviews) [theView removeFromSuperview];
  // Get the view of the device and its size
  previewViewController = [device deviceView];
  // Get width and height of the device and set the position inside the view
  NSRect deviceFrame = NSMakeRect(0, 0, previewViewController.view.frame.size.width, previewViewController.view.frame.size.height);
  deviceFrame.origin.x = (previewView.frame.size.width - deviceFrame.size.width)/2;
  deviceFrame.origin.y = (previewView.frame.size.height - deviceFrame.size.height)/2;
  // Set its frame and add it as a subview of the view of all devices of this kind
  [[previewViewController view] setFrame:deviceFrame];
  [previewView addSubview:[previewViewController view]];
}

@end
