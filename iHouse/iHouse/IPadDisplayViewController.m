//
//  TVViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "IPadDisplayViewController.h"
#import "IDevice.h"
@interface IPadDisplayViewController ()

@end

@implementation IPadDisplayViewController
@synthesize iDevice, deviceImage, deviceName, backView;


-(id)initWithDevice:(IDevice *)theDevice {
  self = [super init];
  if (self && (theDevice.type == iPadDisplay)) {
    iDevice = theDevice;
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
  // Do view setup here.
  
  // Set name and image of the idevice
  [deviceName setStringValue:[iDevice name]];
  [deviceImage setImage:[iDevice image]];
  
  
  // Set the background color accordingly
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[[iDevice color] CGColor]];
  [backView setWantsLayer:YES];
  [backView setLayer:viewLayer];
}

- (IBAction)dummy:(id)sender {
  [(IPadDisplay*) [iDevice theDevice] identify];
}
@end
