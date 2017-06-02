//
//  HouseSyncer.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 04.02.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "House.h"
#import "Room.h"
#import "Group.h"
#import "Device.h"
#import "Constants.h"
#import "SyncManager.h"

@interface HouseSyncer : NSObject<SyncManagerDelegate> {
  SyncManager *syncManager;
  House *house;
}
@property BOOL synced;

+ (id)sharedHouseSyncer;

-(BOOL)isSynced;
-(void)handleSyncArray:(NSArray*)syncArray;
-(void)updateDevice:(Device*)device;
-(void)sendAction:(NSString*)action withValue:(int)value forDevice:(Device*)device;
-(void)sendGroup:(Group*)group;
-(void)activateSiri;

@end
