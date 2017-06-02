//
//  EditAmbilightViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 06.03.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "EditAmbilightViewController.h"

@interface EditAmbilightViewController ()

@end

@implementation EditAmbilightViewController
@synthesize ambilight;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (id) initWithAmbilight:(Ambilight*) theAmbilight {
  if (self = [super init]) {
    // Get the pointer of the device
    ambilight =  theAmbilight;
  }
  return self;
}

@end
