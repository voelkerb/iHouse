//
//  DeviceViewController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 25/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "House.h"

@interface DeviceViewController : UIViewController {
  House *house;
  Room *room;
  Device *device;
  CATransition *transition;
  bool init;
}


@property (weak, nonatomic) IBOutlet UILabel *topBarLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *groupButton;

-(void)setRoom:(Room*)theRoom;
  
-(IBAction)activateVoice:(id)sender;
-(IBAction)handlePan:(id)sender;

- (IBAction)groupPressed:(id)sender;
@end
