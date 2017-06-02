//
//  SyncManager.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 26/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkController.h"
#import "Settings.h"
#import "NSNetService+Util.h"

// The Functions the delegate has to implement
@protocol SyncManagerDelegate <NSObject>

// The delegate needs to change something
- (void)syncStatus:(float)progress;

- (void)commandResponse:(NSString*)response;

- (void)updateDeviceResponse:(NSDictionary*)deviceDict;


@end

@interface SyncManager : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate> {
  NetworkController* tcpConnection;
  NSArray *roomList;
  NSArray *deviceList;
  NSArray *groupList;
  NSArray *deviceNameAndRoomList;
  
  // Bonkjour stuff
  NSNetServiceBrowser		*browser;
  NSMutableArray			*services;
  AddressAndPort *addrAndPort;
}

// The delegate variable
@property (weak) id<SyncManagerDelegate> delegate;
@property (nonatomic) float progressValue;
@property (nonatomic) BOOL isConnected;
@property Settings *settings;

// This class is singletone
+ (id)sharedSyncManager;

- (void)syncNow;

- (void)sendCommand:(NSString*)command;
- (void)connectToServer:(NSString*)host withPort:(NSInteger)port;
- (void)connectToServer;
- (void)disconnectFromServer;
- (void)disableAlertSheets;
- (void)enableAlertSheets;

@end
