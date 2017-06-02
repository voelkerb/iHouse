//
//  InfraredViewController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 27/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "InfraredViewController.h"
#import "Constants.h"
#import "HouseSyncer.h"

#define DEBUG_IR_VIEW 1
NSString * const IRCommandEmptyCommand = @"new command";

@interface InfraredViewController ()

@end

@implementation InfraredViewController

@synthesize deviceImage;
@synthesize scrollView;


-(id)initWithDevice:(Device*)theDevice {
  if (self = [super init]) {
    device = theDevice;
    init = false;
    // Alloc the viewcontroller array
    viewControllers = [[NSMutableArray alloc] init];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:DeviceDidChange object:nil];
  }
  return self;
}

// If the device was dedited, we need to redraw
-(void)reDraw:(NSNotification*)notification {
  if ([device.name isEqualToString:[notification object]]) {
    if (DEBUG_IR_VIEW) NSLog(@"Redraw %@ view", [notification object]);
    [self drawButtons];
  }
}



- (void)viewDidLoad {
  [super viewDidLoad];
  if (device == nil) device = [[Device alloc] init];
    // Do any additional setup after loading the view from its nib.
}


-(void)viewDidLayoutSubviews {
  if (!init) [self drawButtons];
}

-(void)resetInit {
  init = false;
}


- (void)drawButtons {
  init = true;
  [self performSelector:@selector(resetInit) withObject:nil afterDelay:0.1];

  // Remove all existing view controller from the array
  for (SingleIRCommandViewController *viewCon in viewControllers) viewCon.delegate = nil;
  [viewControllers removeAllObjects];
  
  // And from the scrollview
  NSArray *views = [[NSArray alloc] initWithArray:scrollView.subviews];
  for (UIView *view in views) [view removeFromSuperview];
  
  
  // Get all commands
  NSDictionary *deviceInfo = [NSDictionary dictionaryWithDictionary:device.info];
  NSArray *irCommands;
  if ([deviceInfo objectForKey:KeyIRCommands]) {
    irCommands = [deviceInfo objectForKey:KeyIRCommands];
  } else {
    if (DEBUG_IR_VIEW) NSLog(@"No IR Commands decoded");
  }
  
  NSInteger theTag = 0;
  NSInteger xMargin = 4;
  NSInteger yMargin = 4;
  NSInteger sideMargin = 30;
  NSInteger topMargin = 30;
  NSInteger xPos = sideMargin;
  NSInteger yPos = topMargin;
  NSInteger irPerRow = 3;
  
  int columnCounter = 0;
  
  // Get view bounds
  CGRect view = self.view.bounds;
  
  // we want to have 3 buttons per row, estimate size
  NSInteger width = (view.size.width - (irPerRow-1)*xMargin - 2*sideMargin)/irPerRow;
  NSInteger height = width;
  
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
  // If in landscape mode
  if (UIDeviceOrientationIsLandscape(orientation)) {
  }
  // If iPad
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    width /= 2;
    height = width;
    sideMargin = view.size.width/2 - 1.5f*width - xMargin;
    xPos = sideMargin;
  }
  
  
  
  
  BOOL atBottom = false;
  
  // For every existing ir command
  for (NSDictionary* irCommand in irCommands) {
    NSString *name = [irCommand objectForKey:KeyName];
    UIImage *image = [irCommand objectForKey:KeyImage];
    if (name) {
      SingleIRCommandViewController *singleIRViewController = [[SingleIRCommandViewController alloc] initWithCommandName:name andImage:image];
      singleIRViewController.delegate = self;
      [viewControllers addObject:singleIRViewController];
      [singleIRViewController.view setFrame:CGRectMake(xPos, yPos, width, height)];
      [singleIRViewController.view setAutoresizingMask:UIViewAutoresizingNone];
      [self.scrollView addSubview:singleIRViewController.view];
      
      
      atBottom = false;
      theTag++;
      columnCounter++;
      xPos = xPos + width + xMargin;
      if (columnCounter == irPerRow) {
        yPos = yPos + height + yMargin;
        columnCounter = 0;
        xPos = sideMargin;
        atBottom = true;
      }
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

- (void)pressedButton:(NSString *)command {
  [[HouseSyncer sharedHouseSyncer] sendAction:[NSString stringWithFormat:@"%@%@", IRToggleAction, command] withValue:0 forDevice:device];
}

@end
