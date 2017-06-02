//
//  ViewController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 23/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "SyncManager.h"
@interface ViewController : UIViewController <SyncManagerDelegate> {
  SyncManager *syncManager;
  CABasicAnimation* rotationAnimation;
}

@property (weak, nonatomic) IBOutlet UIProgressView *connectProgress;
@property (nonatomic) float progressValue;
@property (nonatomic) BOOL syncNow;
@property (weak, nonatomic) IBOutlet UIImageView *logoImage;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

- (IBAction)connect:(id)sender;
- (IBAction)settingsPressed:(id)sender;
@end

