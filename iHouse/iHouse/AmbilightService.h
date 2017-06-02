//
//  AmbilightServiceSearch.h
//  iHouse
//
//  Created by Benjamin Völker on 06.05.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCPClient.h"
#import "NSNetService+Util.h"
#import <Cocoa/Cocoa.h>

@interface AmbilightService : NSObject<NSNetServiceBrowserDelegate, NSNetServiceDelegate> {
  
  // Bonkjour stuff
  NSNetServiceBrowser		*browser;
  NSMutableArray			*services;
  AddressAndPort *addrAndPort;
  TCPClient* tcpConnection;
}

@property (nonatomic, assign) bool ambilight;
@property (nonatomic, assign) bool fade;
@property (nonatomic, assign) float brightness;
@property (nonatomic, strong) NSColor *currentColor;

// This class is singletone
+ (id)sharedAmbilightService;

-(void)sendData;

@end
