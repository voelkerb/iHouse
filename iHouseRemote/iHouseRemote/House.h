//
//  House.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 05/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Room.h"
#import "Group.h"


@interface House : NSObject



@property (strong) NSMutableArray *roomList;
@property (strong) NSMutableArray *groupList;

// This class is singletone
+ (id)sharedHouse;
-(void)addRoom:(Room*)room;
-(void)addGroup:(Group*)group;
-(void)destroy;

-(Device*)getDeviceNamed:(NSString*)deviceName;

-(void)initDummyHouse;

-(BOOL)store;

@end
