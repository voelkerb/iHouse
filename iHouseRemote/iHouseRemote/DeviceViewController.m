//
//  DeviceViewController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 25/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "DeviceViewController.h"
#import "HouseSyncer.h"
#import "SingleDeviceViewController.h"

#define DEBUG_DEVICEVIEW 1
#define CONNECTION_ISSUE_MSG @"Could not connect to the iHouse server application (host: 192.168.0.18).\nMake sure the application is up and running."
#define CONNECTION_ISSUE_TITLE @"Connection Problem"
#define CONNECTION_BROKE_ISSUE_TITLE @"Server Disconnected"
#define CONNECTION_BROKE_ISSUE_MSG @"The connection to the server was lost.\nTry to manually re-establish the connection."

@implementation DeviceViewController
@synthesize topBarLabel, scrollView, groupButton;

- (void)viewDidLoad {
  [super viewDidLoad];
  transition = nil;
  init = false;
  device = nil;
  
  if ([[[House sharedHouse] groupList] count] > 0) {
    groupButton.hidden = false;
    groupButton.enabled = true;
  } else {
    groupButton.hidden = true;
    groupButton.enabled = false;
  }
  
  house = [House sharedHouse];
  
  if (room) {
    topBarLabel.text = room.name;
  }
}

-(void)setRoom:(Room*)theRoom {
  NSLog(@"Set the Room: %@", theRoom.name);
  room = theRoom;
  topBarLabel.text = room.name;
  [self displayDevices];
}

-(void)viewDidLayoutSubviews {
  if (!init) [self displayDevices];
}

-(void)resetInit {
  init = false;
}

- (void)displayDevices {
  init = true;
  [self performSelector:@selector(resetInit) withObject:nil afterDelay:0.1];
  NSArray *views = [[NSArray alloc] initWithArray:self.scrollView.subviews];
  for (UIView *theView in views) [theView removeFromSuperview];
  
  NSInteger theTag = 0;
  NSInteger xMargin = 20;
  NSInteger yMargin = 40;
  NSInteger sideMargin = 30;
  NSInteger topMargin = 40;
  NSInteger xPos = sideMargin;
  NSInteger yPos = topMargin;
  NSInteger devicesPerRow = 3;
  // Go for 3 items per row on ipad
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) devicesPerRow = 5;
  
  int columnCounter = 0;
  BOOL atBottom = false;
  
  // Get view bounds
  CGRect view = self.view.bounds;
  
  // we want to have 3 rooms per row, estimate size
  NSInteger width = (view.size.width - (devicesPerRow-1)*xMargin - 2*sideMargin)/devicesPerRow;
  NSInteger height = width;
  
  
  
  NSLog(@"Devices in room: %@", [room deviceList]);
  for (Device *theDevice in [room deviceList]) {
    UIImage *btnImage = theDevice.image;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [[button imageView] setContentMode:UIViewContentModeScaleAspectFit];
    
    UIButton *buttonText = [UIButton buttonWithType:UIButtonTypeSystem];
    [button addTarget:self
               action:@selector(devicePressed:)
     forControlEvents:UIControlEventTouchUpInside];
    [buttonText addTarget:self
                   action:@selector(devicePressed:)
         forControlEvents:UIControlEventTouchUpInside];
    [button setImage:btnImage forState:UIControlStateNormal];
    [buttonText setTitle:theDevice.name forState:UIControlStateNormal];
    [buttonText setTitle:theDevice.name forState:UIControlStateHighlighted];
    [buttonText setTitle:theDevice.name forState:UIControlStateSelected];
    /*
    [button setEnabled:YES];
    [buttonText setEnabled:YES];
    button.hidden = false;
    buttonText.hidden = false;*/
    [button setTag:theTag];
    [buttonText setTag:theTag];
    
    // Filter out lights and switchable sockets to enable fast switch
    // And show the current light state in the image
    if (theDevice.type == light || theDevice.type == switchableSocket) {
      NSDictionary *deviceInfo = theDevice.info;
      BOOL state = false;
      if ([deviceInfo objectForKey:SocketLightKeyState]) {
        state = [[deviceInfo objectForKey:SocketLightKeyState] boolValue];
      }
      if (!state) {
        button.alpha = 0.5;
        [button setImage:[theDevice.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        button.tintColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.4f];
      } else {
        button.alpha = 1.0;
      }
    }
    
    button.frame = CGRectMake(xPos, yPos, width, height);
    buttonText.frame = CGRectMake(xPos, yPos + height, width, 15);
    [self.scrollView addSubview:button];
    [self.scrollView addSubview:buttonText];
    
    
    atBottom = false;
    theTag++;
    columnCounter++;
    xPos = xPos + width + xMargin;
    if (columnCounter == devicesPerRow) {
      yPos = yPos + height + yMargin;
      columnCounter = 0;
      xPos = sideMargin;
      atBottom = true;
    }
  }
  if (!atBottom) yPos = yPos + height + yMargin + yMargin;
  CGSize size = self.view.bounds.size;
  size.height = yPos;
  self.scrollView.contentSize = size;
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


- (void)devicePressed:(id)sender {
  if (![[room deviceList] objectAtIndex:[sender tag]]) return;
  device = [[room deviceList] objectAtIndex:[sender tag]];
  NSLog(@"Pressed device: %@", device.name);
  
  // Filter out lights and switchable sockets to enable fast switch
  // And show the current light state in the image
  if (device.type == light || device.type == switchableSocket) {
    NSMutableDictionary *deviceInfo = [[NSMutableDictionary alloc] initWithDictionary:device.info];
    BOOL state = false;
    if ([deviceInfo objectForKey:SocketLightKeyState]) {
      state = [[deviceInfo objectForKey:SocketLightKeyState] boolValue];
    }
    NSLog(@"Current Light state: %i, need to toggle.", state);
    UIButton *button = (UIButton *)sender;
    if (state) {
      button.alpha = 0.5;
      [button setImage:[device.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
      button.tintColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.4f];
    } else {
      button.alpha = 1.0;
      [button setImage:device.image forState:UIControlStateNormal];
    }
    [button setNeedsDisplay];
    state = !state;
    NSLog(@"Stored %@", deviceInfo);
    [deviceInfo setObject:[NSNumber numberWithBool:state] forKey:SocketLightKeyState];
    device.info = deviceInfo;
    [[HouseSyncer sharedHouseSyncer] sendAction:SwitchCommand withValue:state forDevice:device];
    
    
  } else {
    // Update info of the device
    [[HouseSyncer sharedHouseSyncer] updateDevice:device];
    // Change to device view
    [self performSegueWithIdentifier:@"SingleDeviceSegue" sender:self];
  }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  // Make sure your segue name in storyboard is the same as this line
  if ([[segue identifier] isEqualToString:@"SingleDeviceSegue"])
  {
    // Get reference to the destination view controller
    SingleDeviceViewController *vc = [segue destinationViewController];
    
    // Pass any objects to the view controller here, like...
    [vc setDevice:device];
  }
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
