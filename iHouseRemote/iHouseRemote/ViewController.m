//
//  ViewController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 23/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "ViewController.h"
#import "Constants.h"
#define DEBUG_INIT_VIEW 1
#define LOGO_ROT_TIME 90
#define LOGO_ROT_DEGREE 0.07

@interface ViewController ()

@end

@implementation ViewController
@synthesize connectProgress, progressValue, syncNow, logoImage, settingsButton;

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self initStuff];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self initStuff];
  settingsButton.alpha = 0.4;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoSyncStarted) name:StartAutoSync object:nil];
  
}

- (void)initStuff {
  
  syncManager = [SyncManager sharedSyncManager];
  syncManager.delegate = self;
  
  connectProgress.hidden = YES;
  progressValue = 0.0f;
  syncNow = false;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


- (void) runSpinAnimationWithDuration:(CGFloat)duration rotations:(CGFloat)rotations repeat:(float)repeat; {
  if (!rotationAnimation) {
    if (DEBUG_INIT_VIEW) NSLog(@"Start rotating");
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * rotations * duration ];
    rotationAnimation.duration = duration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = repeat;
    rotationAnimation.delegate = self;
    
    [logoImage.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
  }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
  //[self runSpinAnimationWithDuration:LOGO_ROT_TIME rotations:LOGO_ROT_DEGREE repeat:YES];
}


- (void)syncComplete {
  [logoImage stopAnimating];
  rotationAnimation.delegate = nil;
  rotationAnimation = nil;

  
  connectProgress.hidden = YES;
  // TODO: change view
  if (DEBUG_INIT_VIEW) NSLog(@"Sync completed");
  
  [self performSegueWithIdentifier:@"RoomSegue" sender:self];
}



-(void)syncStatus:(float)progress {
  
  if (progress <= 0.0f) {
    connectProgress.hidden = YES;
  } else {
    connectProgress.progress = progress;
    connectProgress.hidden = NO;
  }
  if (progress == -1.0f) {
    [self runSpinAnimationWithDuration:LOGO_ROT_TIME rotations:LOGO_ROT_DEGREE repeat:YES];
  }
  if (progress >= 1.0f) [self syncComplete];
}


- (IBAction)connect:(id)sender {
  [self.view endEditing:YES];
  
  if (DEBUG_INIT_VIEW) NSLog(@"Syncing now");
  [syncManager syncNow];
}

-(void) autoSyncStarted {
  [self.view endEditing:YES];
  if (DEBUG_INIT_VIEW) NSLog(@"Autosync now");
}

- (IBAction)settingsPressed:(id)sender {
  
  [self performSegueWithIdentifier:@"SettingsSegue" sender:self];
}

@end
