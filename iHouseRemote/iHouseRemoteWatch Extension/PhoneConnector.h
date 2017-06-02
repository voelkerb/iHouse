//
//  PhoneConnector.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 07/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import "House.h"
#import "Constants.h"


@interface PhoneConnector : NSObject<WCSessionDelegate>

// This class is singletone
+ (id)sharedPhoneConnector;

-(void)sync;
-(void)sendCommand:(NSString*)command forGroup:(Group*)group;
-(void)sendCommand:(NSString*)command forDevice:(Device*)device;
-(void)sendCommand:(NSString *)command forDevice:(Device *)device withInfo:(NSString *)info;

@end
