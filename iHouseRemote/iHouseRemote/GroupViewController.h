//
//  GroupViewController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 16/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "House.h"

@interface GroupViewController : UIViewController {
  House *house;
  CATransition *transition;
  bool init;
}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

-(IBAction)activateVoice:(id)sender;
-(IBAction)handlePan:(id)sender;

@end
