//
//  WatchConnector.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 07/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>

@interface WatchConnector : NSObject<WCSessionDelegate> {
  WCSession *wcSession;
}

// This class is singletone
+ (id)sharedWatchConnector;

@end
