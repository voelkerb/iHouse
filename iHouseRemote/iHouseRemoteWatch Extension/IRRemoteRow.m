//
//  IRRemoteRow.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 21/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "IRRemoteRow.h"

@implementation IRRemoteRow

@synthesize leftButton, leftName, middleButton, middleName, rightButton, rightName;

- (IBAction)leftButtonTapped {
  if ([self.delegate respondsToSelector:@selector(commandToggledWithName:)]) {
    [self.delegate commandToggledWithName:leftName];
  }
}


- (IBAction)middleButtonTapped {
  if ([self.delegate respondsToSelector:@selector(commandToggledWithName:)]) {
    [self.delegate commandToggledWithName:middleName];
  }
}

- (IBAction)rightButtonTapped {
  if ([self.delegate respondsToSelector:@selector(commandToggledWithName:)]) {
    [self.delegate commandToggledWithName:rightName];
  }
}
@end
