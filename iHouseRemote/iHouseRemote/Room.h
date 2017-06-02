//
//  Room.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 05/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>
#import "Device.h"

@interface Room : NSObject<NSCoding>

@property (strong) NSMutableArray *deviceList;
@property (strong) NSString *name;
@property (strong) UIImage *image;


-(void)addDevice:(Device*)dev;

@end
