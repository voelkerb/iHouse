//
//  SingleIRCommandViewController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 27/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "SingleIRCommandViewController.h"
#import "InfraredViewController.h"


#define DEBUG_SINGLE_IR_VIEW 1


@interface SingleIRCommandViewController ()

@end

@implementation SingleIRCommandViewController
@synthesize toggleButton, commandName;
@synthesize delegate;


-(id)initWithCommandName:(NSString *)theCommandName andImage:(UIImage *)image {
  if (self = [super init]) {
    self.commandName = theCommandName;
    commandImage = image;

  }
  return self;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  // If it is an empty comman, disable button, set opaque
  if ([self.commandName isEqualToString:IRCommandEmptyCommand]) {
    self.view.hidden = YES;
    toggleButton.enabled = NO;
  } else {
    [toggleButton setImage:commandImage forState:UIControlStateNormal];
    [[toggleButton imageView] setContentMode:UIViewContentModeScaleAspectFit];
    toggleButton.layer.cornerRadius = 10; // this value vary as per your desire
    toggleButton.clipsToBounds = YES;
  }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)toggleButtonPressed:(id)sender {
  if (DEBUG_SINGLE_IR_VIEW) {
    NSLog(@"IR Button pressed: %@", commandName);
  }
  [delegate pressedButton:commandName];
}

@end

