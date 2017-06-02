//
//  TCPClient.h
//  iHouse
//
//  Created by Benjamin Völker on 06.05.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import "NSNetService+Util.h"




// Block typedefs
@class TCPClient;
typedef void (^ConnectionBlock)(TCPClient*);
typedef void (^MessageBlock)(TCPClient*,NSString*);
typedef void (^DataBlock)(TCPClient*,NSData*);
typedef void (^DataProgressBlock)(TCPClient*,float);
typedef void (^ServiceFoundBlock)(TCPClient*);

@interface TCPClient : NSObject<NSStreamDelegate> {
  // Connection info
  NSString* host;
  int port;
  
  // Input
  NSInputStream* inputStream;
  NSMutableData* inputBuffer;
  BOOL isInputStreamOpen;
  
  // Output
  NSOutputStream* outputStream;
  NSMutableData* outputBuffer;
  BOOL isOutputStreamOpen;
  
  // Event handlers
  MessageBlock messageReceivedBlock;
  DataBlock dataReceivedBlock;
  ConnectionBlock connectionOpenedBlock;
  ConnectionBlock connectionFailedBlock;
  ConnectionBlock connectionClosedBlock;
  
  BOOL isBufferingData;
  SInt64 bufferingSize;
  NSMutableData *dataBuffer;
  
}


// Methods
- (void)setHostAndPort:(NSString*)theHost :(int)thePort;
- (void)connect;
- (void)disconnect;
- (void)sendMessage:(NSString*)message;
- (void)sendData:(NSData*)message;

// Properties
@property (copy) MessageBlock messageReceivedBlock;
@property (copy) DataBlock dataReceivedBlock;
@property (copy) DataProgressBlock dataReceivedProgressBlock;
@property (copy) ConnectionBlock connectionOpenedBlock;
@property (copy) ConnectionBlock connectionFailedBlock;
@property (copy) ConnectionBlock connectionClosedBlock;
@property (copy) ServiceFoundBlock serviceFoundBlock;
@property bool isOpen;
@property float bufferingProgress;

@end
