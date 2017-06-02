//
//  RoomViewController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 24/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "House.h"
#import "SyncManager.h"

@interface RoomViewController : UIViewController {
  House *house;
  SyncManager *syncManager;
  CATransition *transition;
  bool init;
  Room *currentRoom;
}

@property (weak, nonatomic) IBOutlet UIButton *groupButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)handlePan:(id)sender;
- (IBAction)groupPressed:(id)sender;

-(IBAction)activateVoice:(id)sender;
@end
