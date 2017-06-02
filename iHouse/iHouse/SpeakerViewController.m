//
//  SpeakerViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "SpeakerViewController.h"

@interface SpeakerViewController ()

@end

@implementation SpeakerViewController
@synthesize speaker;

- (id)initWithSpeaker:(Speaker *)theSpeaker {
  if (self = [super init]) {
    if ([theSpeaker isKindOfClass:[speaker class]]) speaker = (Speaker *) theSpeaker;
    else speaker = [[Speaker alloc] init];
  }
  return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
