//
//  SingleDeviceViewController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 25/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "SingleDeviceViewController.h"
#import "HouseSyncer.h"

#define DEBUG_SINGLE_DEVICEVIEW 1

@implementation SingleDeviceViewController
@synthesize topBarLabel;
@synthesize deviceView, groupButton;

- (void)viewDidLoad {
  [super viewDidLoad];
  
  if ([[[House sharedHouse] groupList] count] > 0) {
    groupButton.hidden = false;
    groupButton.enabled = true;
  } else {
    groupButton.hidden = true;
    groupButton.enabled = false;
  }
}

-(void)setDevice:(Device*)theDevice {
  NSInteger topMargin = 70;
  transition = nil;
  deviceView = [[UIView alloc] initWithFrame:CGRectMake(0, topMargin, self.view.bounds.size.width, self.view.bounds.size.height - topMargin)];
  [deviceView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
  [self.view addSubview:deviceView];
  device = theDevice;
  
  if (DEBUG_SINGLE_DEVICEVIEW) NSLog(@"SetDevice %@", device.name);
  
  topBarLabel.text = device.name;
  
  
  if (DEBUG_SINGLE_DEVICEVIEW) NSLog(@"Device type %@", device.deviceTypeToString);
  
  switch (device.type) {
    case light:
    case switchableSocket:
      deviceViewController = [[SocketLightViewController alloc] initWithDevice:device];
      break;
    case sensor:
      deviceViewController = [[SensorViewController alloc]  initWithDevice:device];
      break;
    case meter:
      deviceViewController = [[MeterViewController alloc] initWithDevice:device];
      break;
    case ir:
      deviceViewController = [[InfraredViewController alloc] initWithDevice:device];
      break;
    default:
      break;
  }
  
  
  [deviceViewController.view setFrame:[deviceView bounds]];
  [deviceView addSubview:deviceViewController.view];
  [deviceView setNeedsDisplay];
  
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


-(void)handlePan:(id)sender {
  if (DEBUG) NSLog(@"Go back!");
  if (!transition) {
    transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    [self.view.window.layer addAnimation:transition forKey:nil];
    
    [self dismissViewControllerAnimated:NO completion:nil];
  }
}

-(void)activateVoice:(id)sender {
  [[HouseSyncer sharedHouseSyncer] activateSiri];
}
- (void)groupPressed:(id)sender {
  NSLog(@"Pressed group");
  [self performSegueWithIdentifier:@"GroupSegue" sender:self];
}

@end
