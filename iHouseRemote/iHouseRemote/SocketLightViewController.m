//
//  SocketLightViewController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 26/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "SocketLightViewController.h"
#import "HouseSyncer.h"
#define DEBUG_SOCKET_LIGHT_VIEW 0

@implementation SocketLightViewController
@synthesize deviceImage, switchSegmentControl;

-(id)initWithDevice:(Device *)theDevice {
  if (self = [super init]) {
    device = theDevice;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:DeviceDidChange object:nil];
  }
  return self;
}

// If the device was dedited, we need to redraw
-(void)reDraw:(NSNotification*)notification {
  if ([device.name isEqualToString:[notification object]]) {
    if (DEBUG_SOCKET_LIGHT_VIEW) NSLog(@"Redraw %@ view", [notification object]);
    [self viewDidLoad];
  }
}


- (void)viewDidLoad {
  [super viewDidLoad];
  
  // If not inited properly
  if (device == nil) device = [[Device alloc] init];
  
  [deviceImage setImage:device.image];
  [deviceImage setContentMode:UIViewContentModeScaleAspectFit];
  
  
  NSDictionary *deviceInfo = device.info;
  BOOL state = false;
  
  if ([deviceInfo objectForKey:SocketLightKeyState]) {
    state = [[deviceInfo objectForKey:SocketLightKeyState] boolValue];
  }
  [switchSegmentControl setSelectedSegmentIndex:state];
  [switchSegmentControl addTarget:self
                        action:@selector(switchButtonPressed:)
              forControlEvents:UIControlEventValueChanged];
  
  if (DEBUG_SOCKET_LIGHT_VIEW) NSLog(@"Current state of Socket/Light: %i", state);
  
}


- (IBAction)switchButtonPressed:(id)sender {
  NSLog(@"Switch button pressed %li", [switchSegmentControl selectedSegmentIndex]);
  int value = (int)[switchSegmentControl selectedSegmentIndex];
  [[HouseSyncer sharedHouseSyncer] sendAction:SwitchCommand withValue:value forDevice:device];
}
@end
