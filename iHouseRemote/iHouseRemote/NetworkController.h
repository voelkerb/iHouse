
#import <Foundation/Foundation.h>
#import "NSNetService+Util.h"

// Block typedefs
@class NetworkController;
typedef void (^ConnectionBlock)(NetworkController*);
typedef void (^MessageBlock)(NetworkController*,NSString*);
typedef void (^DataBlock)(NetworkController*,NSData*);
typedef void (^DataProgressBlock)(NetworkController*,float);
typedef void (^ServiceFoundBlock)(NetworkController*);


@interface NetworkController : NSObject<NSStreamDelegate> {
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

// Singleton instance
+ (NetworkController*)sharedInstance;

// Methods
- (void)setHostAndPort:(NSString*)theHost :(int)thePort;
- (void)connect;
- (void)disconnect;
- (void)sendMessage:(NSString*)message;

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
