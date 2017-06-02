//
//  InfraredDeviceViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "InfraredDeviceViewController.h"
#import "IDevice.h"

@interface InfraredDeviceViewController ()

@end

@implementation InfraredDeviceViewController
@synthesize iDevice, flippedBackView;


/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  InfraredDeviceViewController *copy = [[InfraredDeviceViewController allocWithZone: zone] initWithDevice:iDevice];
  return copy;
}


-(id)initWithDevice:(IDevice *)theDevice {
  self = [super init];
  if (self && (theDevice.type == ir)) {
    iDevice = theDevice;
    // Alloc the viewcontroller array
    viewControllers = [[NSMutableArray alloc] init];
    // Add observer for device idevice change and irdevice change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:iDeviceDidChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:IRDeviceCountChanged object:nil];
  }
  return self;
}

// If the device was edited, we need to redraw
-(void)reDraw:(NSNotification*)notification {
  // If the sender is the iDevice or the ir device, redraw
  if ([iDevice isEqualTo:[notification object]] || [[iDevice theDevice] isEqualTo:[notification object]]) {
    [self viewDidLoad];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Init the ir view
  [self initView];
}

/*
 * Init the ir view and set the background color correctly.
 */
- (void) initView {
  // Remove all existing view controller from the array
  [viewControllers removeAllObjects];
  // Remove all subviews in the currentview
  NSArray *subviews = [[NSArray alloc] initWithArray:[flippedBackView subviews]];
  for (NSView *view in subviews) [view removeFromSuperview];
  
  // Set the backgroundcolor accordingly
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[[iDevice color] CGColor]];
  [flippedBackView setWantsLayer:YES];
  [flippedBackView setLayer:viewLayer];
  
  // The height of the complete view
  NSInteger height = 0;
  
  // Add every single command view to the command view
  NSRect frame = NSMakeRect(0, 0, 0, 0);
  // For every existing ir command
  for (InfraredCommand* irCommand in [(InfraredDevice*)[iDevice theDevice] infraredCommands]) {
    // Get the view and store the width and height
    NSViewController *irCommandViewController = [irCommand deviceView];
    frame.size.width = irCommandViewController.view.frame.size.width;
    frame.size.height = irCommandViewController.view.frame.size.height;
    // Increment x position
    frame.origin.x += irCommandViewController.view.frame.size.width;
    // If x position is now beyond bounds, set the x position back to 0 and increment y position
    if (frame.origin.x >= flippedBackView.frame.size.width) {
      frame.origin.x = 0;
      frame.origin.y += irCommandViewController.view.frame.size.height;
      height = frame.origin.y;
    } else {
      height = frame.origin.y + frame.size.height;
    }
  }
  // Set the name of the ir remote at the top and increase height
  NSTextField *nameTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 8, flippedBackView.frame.size.width, 24)];
  NSInteger startOfIRView = nameTextField.frame.origin.y + nameTextField.frame.size.height;
  height += startOfIRView;
  // Set the view to the given width and height
  [[self view] setFrame:NSMakeRect(self.view.frame.origin.x, self.view.frame.origin.y, flippedBackView.frame.size.width, height)];
  // Set the frame of the backview as well
  [flippedBackView setFrame:NSMakeRect(0, 0, flippedBackView.frame.size.width, height)];
  // Set the nametextfield to the name, to width sizable and to not editable
  [nameTextField setStringValue:[iDevice name]];
  [nameTextField setAutoresizingMask:NSViewWidthSizable];
  [nameTextField setBordered:NO];
  [nameTextField setEditable:NO];
  [nameTextField setDrawsBackground:YES];
  // Make background clear and center text
  [nameTextField setBackgroundColor:[NSColor clearColor]];
  [nameTextField setAlignment:NSTextAlignmentCenter];
  [flippedBackView addSubview:nameTextField];
  
  // Add every single command view to the command view
  frame = NSMakeRect(0, startOfIRView, 0, 0);
  for (InfraredCommand* irCommand in [(InfraredDevice*)[iDevice theDevice] infraredCommands]) {
    // Get the view and set the frame accordingly
    NSViewController *irCommandViewController = [irCommand deviceView];
    frame.size.width = irCommandViewController.view.frame.size.width;
    frame.size.height = irCommandViewController.view.frame.size.height;
    // Add to the viewController
    [viewControllers addObject:irCommandViewController];
    // Add the view, set its frame and add it as a subview
    [irCommandViewController.view setFrame:frame];
    [flippedBackView addSubview:irCommandViewController.view];
    
    // Increment x position and if needed also the y position
    frame.origin.x += irCommandViewController.view.frame.size.width;
    if (frame.origin.x + frame.size.width > flippedBackView.frame.size.width) {
      frame.origin.x = 0;
      frame.origin.y += irCommandViewController.view.frame.size.height;
    }
  }
}

@end
