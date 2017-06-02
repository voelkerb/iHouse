//
//  Room.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 05/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "Room.h"

@implementation Room

@synthesize image, name, deviceList;

/*
 * Init function
 */
- (id)init {
  if((self = [super init])) {
    image = [UIImage imageNamed:@"roomBold_256"];
    name = [[NSString alloc] initWithFormat:@"New Room"];
    deviceList = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  //Encode properties, other class variables, etc
  [encoder encodeObject:self.image forKey:@"image"];
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.deviceList forKey:@"deviceList"];
}

- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    //decode properties, other class vars
    self.image = [decoder decodeObjectForKey:@"image"];
    self.name = [decoder decodeObjectForKey:@"name"];
    self.deviceList = [decoder decodeObjectForKey:@"deviceList"];
  }
  return self;
}

-(void)addDevice:(Device *)dev {
  [deviceList addObject:dev];
}



@end
