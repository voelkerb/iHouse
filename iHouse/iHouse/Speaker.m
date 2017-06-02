//
//  Speaker.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "Speaker.h"

@implementation Speaker

- (id)init {
  self = [super init];
  if (self) {
    // TODO: Init stuff goes here
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  // TODO: Coding stuff goes here
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    // TODO: decoding stuff goes here
  }
  return self;
}
@end
