//
//  ConnectionInterfaceController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 05/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "ConnectionInterfaceController.h"
#import "House.h"


@interface ConnectionInterfaceController ()

@end

@implementation ConnectionInterfaceController

@synthesize connectButton, indicator;

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  phoneConnector = [PhoneConnector sharedPhoneConnector];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncComplete) name:NCSyncComplete object:nil];
  [indicator stopAnimating];
  /*
   [indicator setBackgroundImage:[UIImage imageNamed:@"Progress"]];
  
  
  NSTimeInterval duration = 0.35;
  [indicator startAnimatingWithImagesInRange:NSMakeRange(0, 10) duration:duration repeatCount:10];
   */
}

- (void)willActivate {
  // This method is called when watch view controller is about to be visible to user
  [super willActivate];
  [connectButton setEnabled:true];
  [connectButton setHidden:false];
  [indicator stopAnimating];
}

- (void)didDeactivate {
  // This method is called when watch view controller is no longer visible
  [super didDeactivate];
}

- (IBAction)connectPressed {
  [phoneConnector sync];
  [indicator startAnimating];
  [connectButton setEnabled:false];
  [connectButton setHidden:true];
}

-(void)syncComplete {
  [self presentControllerWithName:@"Rooms" context:nil];
  [indicator stopAnimating];
  [connectButton setEnabled:true];
  [connectButton setHidden:false];
}

@end



