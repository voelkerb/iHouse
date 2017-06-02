//
//  SingleDeviceViewController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 25/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "House.h"
#import "SocketLightViewController.h"
#import "MeterViewController.h"
#import "SensorViewController.h"
#import "InfraredViewController.h"


@interface SingleDeviceViewController : UIViewController{
  Device *device;
  UIViewController *deviceViewController;
  CATransition *transition;
}

@property (weak, nonatomic) IBOutlet UILabel *topBarLabel;
@property (weak, nonatomic) IBOutlet UIButton *groupButton;
@property UIView *deviceView;

-(void)setDevice:(Device*)theDevice;

-(IBAction)activateVoice:(id)sender;
-(IBAction)handlePan:(id)sender;

- (IBAction)groupPressed:(id)sender;

@end
