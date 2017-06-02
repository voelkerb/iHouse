//
//  SwitchViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 12.02.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "SwitchViewController.h"
#import "IDevice.h"

@interface SwitchViewController ()

@end

@implementation SwitchViewController
@synthesize iDevice, switchName, switchImage, backView;

/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  SocketViewController *copy = [[SocketViewController allocWithZone: zone] initWithDevice:iDevice];
  return copy;
}

- (id)initWithDevice:(IDevice *)theSwitchDevice {
  self = [super init];
  if (self && (theSwitchDevice.type == rcSwitch)) {
    // Get the pointer of the device
    iDevice = theSwitchDevice;
    
    // Add observer for device edit change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:iDeviceDidChange object:nil];
  }
  return self;
}

// If the device was dedited, we need to redraw
-(void)reDraw:(NSNotification*)notification {
  if ([iDevice isEqualTo:[notification object]]) {
    [self viewDidLoad];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  if (iDevice == nil) return;
  // Set name and image of the device
  [switchName setStringValue:[iDevice name]];
  [switchImage setImage:[iDevice image]];
  [switchImage setAllowDrag:false];
  [switchImage setAllowDrop:false];
  
  // Set the background color accordingly
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[[iDevice color] CGColor]];
  [backView setWantsLayer:YES];
  [backView setLayer:viewLayer];
}


@end
