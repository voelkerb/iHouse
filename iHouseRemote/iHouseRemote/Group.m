//
//  Group.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 07/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "Group.h"

@implementation Group
@synthesize image, name;

/*
 * Init function
 */
- (id)init {
  if((self = [super init])) {
    image = [UIImage imageNamed:@"devices_256"];
    name = [[NSString alloc] initWithFormat:@"New Group"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  //Encode properties, other class variables, etc
  [encoder encodeObject:self.image forKey:@"image"];
  [encoder encodeObject:self.name forKey:@"name"];
}

- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    //decode properties, other class vars
    self.image = [decoder decodeObjectForKey:@"image"];
    self.name = [decoder decodeObjectForKey:@"name"];
  }
  return self;
}


@end
