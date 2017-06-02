//
//  TCPClient.m
//  iHouse
//
//  Created by Benjamin Völker on 06.05.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "TCPClient.h"

#pragma mark - Private properties and methods

@interface TCPClient () {
  NSString* messageDelimiter;
  NSString* messageDelimiterSent;
}

- (BOOL)openConnection;
- (void)closeConnection;
- (BOOL)isConnected;
- (void)finishOpeningConnection;
- (void)readFromStreamToInputBuffer;
- (void)parseIncomingData;
- (void)writeOutputBufferToStream;
- (void)notifyConnectionBlock:(ConnectionBlock)block;

@end


@implementation TCPClient
@synthesize messageReceivedBlock, dataReceivedBlock;
@synthesize connectionOpenedBlock, connectionFailedBlock, connectionClosedBlock, dataReceivedProgressBlock;
@synthesize isOpen, bufferingProgress;

#pragma mark - Singleton

static id sharedInstance = nil;

#pragma mark - Public methods

- (void)connect {
  if (![self isConnected]) {
    if (![self openConnection]) {
      [self notifyConnectionBlock:connectionFailedBlock];
    }
  }
}

- (void)disconnect {
  [self closeConnection];
}

- (void)sendMessage:(NSString*)message {
  [outputBuffer appendBytes:[message cStringUsingEncoding:NSASCIIStringEncoding]
                     length:[message length]];
  [outputBuffer appendBytes:[messageDelimiterSent cStringUsingEncoding:NSASCIIStringEncoding]
                     length:[messageDelimiterSent length]];
  
  [self writeOutputBufferToStream];
}
- (void)sendData:(NSData*)message {
  [outputBuffer appendBytes:[message bytes]
                     length:[message length]];
  
  [self writeOutputBufferToStream];
}

-(void)setHostAndPort:(NSString *)theHost :(int)thePort {
  host = theHost;
  port = thePort;
}


#pragma mark - Private methods

- (id)init {
  // This might come from some configuration store or Bonjour.
  
  host = @"localhost";//@"10.205.1.94";
  port = 2000;
  messageDelimiter = @"\n";
  messageDelimiterSent = @"\r\n";
  isOpen = false;
  isBufferingData = false;
  bufferingSize = 0;
  bufferingProgress = 0.0f;
  // Init data buffer
  dataBuffer = [[NSMutableData alloc] init];
  return self;
}

- (BOOL)openConnection {
  // Nothing is open at the moment.
  isInputStreamOpen = NO;
  isOutputStreamOpen = NO;
  
  // Setup socket connection
  CFReadStreamRef readStream;
  CFWriteStreamRef writeStream;
  
  CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                     (__bridge CFStringRef)host, port,
                                     &readStream, &writeStream);
  
  if (readStream == nil || writeStream == nil)
    return NO;
  
  // Indicate that we want socket to be closed whenever streams are closed.
  CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket,
                          kCFBooleanTrue);
  CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket,
                           kCFBooleanTrue);
  
  // Setup input stream.
  inputStream = (__bridge_transfer NSInputStream*)readStream;
  inputStream.delegate = self;
  [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [inputStream open];
  
  // Setup output stream.
  outputStream = (__bridge_transfer NSOutputStream*)writeStream;
  outputStream.delegate = self;
  [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [outputStream open];
  
  // Setup buffers.
  inputBuffer = [[NSMutableData alloc] init];
  outputBuffer = [[NSMutableData alloc] init];
  
  isOpen = true;
  return YES;
}

- (void)closeConnection {
  // Notify world.
  if (![self isConnected])
    [self notifyConnectionBlock:connectionFailedBlock];
  else
    [self notifyConnectionBlock:connectionClosedBlock];
  
  // Clean up input stream.
  inputStream.delegate = nil;
  [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [inputStream close];
  inputStream = nil;
  isInputStreamOpen = NO;
  
  // Clean up output stream.
  outputStream.delegate = nil;
  [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [outputStream close];
  outputStream = nil;
  isOutputStreamOpen = NO;
  
  // Clean up buffers.
  inputBuffer = nil;
  outputBuffer = nil;
  isOpen = false;
}

- (BOOL)isConnected {
  return (isInputStreamOpen && isOutputStreamOpen);
}

- (void)finishOpeningConnection {
  if (isInputStreamOpen && isOutputStreamOpen) {
    [self notifyConnectionBlock:connectionOpenedBlock];
    [self writeOutputBufferToStream];
    isOpen = true;
  }
}

- (void)readFromStreamToInputBuffer {
  // Temporary buffer to read data into.
  uint8_t buffer[1024];
  
  // Try reading while there is data.
  while ([inputStream hasBytesAvailable]) {
    
    NSInteger bytesRead = [inputStream read:buffer maxLength:sizeof(buffer)];
    if (bytesRead > 0 && bytesRead <= sizeof(buffer))[inputBuffer appendBytes:buffer length:bytesRead];
  }
  
  // Do protocol-specific processing of data.
  [self parseIncomingData];
}

// Customization point: protocol-specific logic is here.
//
- (void)parseIncomingData {
  if (!isBufferingData) {
    unsigned char *n = [inputBuffer bytes];
    char c = n[0];
    if (c == '/') {
      SInt64 numbBytes = ((SInt64)n[1] << 56) + ((SInt64)n[2] << 48)
      + ((SInt64)n[3] << 40) + ((SInt64)n[4] << 32)
      + ((SInt64)n[5] << 24) + ((SInt64)n[6] << 16)
      + ((SInt64)n[7] << 8) + ((SInt64)n[8]);
      
      //NSLog(@"We have data of length %lli Bytes", numbBytes);
      // Store buffering state
      bufferingSize = numbBytes;
      isBufferingData = true;
      dataBuffer = nil;
      dataBuffer = [[NSMutableData alloc] init];
      bufferingProgress = 0.0f;
      
      // Delete first 9 bytes from array
      [inputBuffer replaceBytesInRange:NSMakeRange(0, 9)
                             withBytes:NULL
                                length:0];
    }
  }
  
  
  
  // Keep going until we are out of data.
  // Loop can also be terminated because there are no line breaks left.
  while ([inputBuffer length] > 0) {
    
    // If data needs to bufferd
    if (isBufferingData) {
      // Get length of the dataBuffer
      SInt64 lengthNow = [dataBuffer length];
      if (lengthNow < bufferingSize) {
        if ((lengthNow + inputBuffer.length) > bufferingSize) {
          [dataBuffer appendBytes:[inputBuffer bytes] length:(bufferingSize - lengthNow)];
          // Delete only the copied data
          [inputBuffer replaceBytesInRange:NSMakeRange(0, (bufferingSize - lengthNow))
                                 withBytes:NULL
                                    length:0];
        } else {
          // Copy complete data into buffer
          [dataBuffer appendData:inputBuffer];
          [inputBuffer replaceBytesInRange:NSMakeRange(0, inputBuffer.length)
                                 withBytes:NULL
                                    length:0];
        }
        
        bufferingProgress = (float)([dataBuffer length]/(float)(bufferingSize));
        if (dataReceivedProgressBlock != nil)
          dataReceivedProgressBlock(self, bufferingProgress);
        
        if ([dataBuffer length] >= bufferingSize) {
          //NSLog(@"All buffered");
          isBufferingData = false;
          if (dataReceivedBlock != nil)
            dataReceivedBlock(self, dataBuffer);
        }
      }
      
      
      
      // If data is short enough to be a command
    } else {
      // This allocation can be avoided if we store buffer as a string at all times.
      // However, that optimization is not strictly necessary for this demo.
      // You should probably avoid this in production code.
      NSString* bufferString = [[NSString alloc] initWithBytesNoCopy:[inputBuffer mutableBytes]
                                                              length:[inputBuffer length]
                                                            encoding:NSASCIIStringEncoding
                                                        freeWhenDone:NO];
      // Look for the first line break.
      NSRange rangeDelim = [bufferString rangeOfString:messageDelimiter];
      
      // If we don't have any line breaks, packet was not complete and we should wait for more data.
      if (rangeDelim.location == NSNotFound) break;
      
      // Notify whoever that message was received.
      NSString* message = [bufferString substringWithRange:NSMakeRange(0, rangeDelim.location)];
      if (messageReceivedBlock != nil)
        messageReceivedBlock(self, message);
      
      // Remove it from the buffer.
      [inputBuffer replaceBytesInRange:NSMakeRange(0, rangeDelim.location + rangeDelim.length)
                             withBytes:NULL
                                length:0];
    }
  }
}

// Write whatever data we have, as much of it as stream can handle.
//
- (void)writeOutputBufferToStream {
  // Is connection open?
  if (![self isConnected])
    return;
  
  // Do we have anything to write?
  if ([outputBuffer length] == 0) {
    return;
  }
  
  // Can stream take any data in?
  if (![outputStream hasSpaceAvailable]) {
    return;
  }
  
  // Write as much data as we can.
  NSInteger bytesWritten = [outputStream write:[outputBuffer bytes]
                                     maxLength:[outputBuffer length]];
  
  // Check for errors.
  if (bytesWritten == -1)  {
    //[self disconnect];
    return;
  }
  
  if ([outputBuffer length] < bytesWritten) {
    return;
  }
  
  // Remove it from the buffer.
  [outputBuffer replaceBytesInRange:NSMakeRange(0, bytesWritten)
                          withBytes:NULL
                             length:0];
  
  //if (DEBUG) NSLog(@"Successfully written %li to outputstream", bytesWritten);
}

- (void)notifyConnectionBlock:(ConnectionBlock)block {
  if (block != nil)
    block(self);
}


#pragma mark - NSStreamDelegate methods

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)streamEvent {
  
  if (stream == inputStream) {
    switch (streamEvent) {
        
      case NSStreamEventOpenCompleted:
        isInputStreamOpen = YES;
        [self finishOpeningConnection];
        break;
        
      case NSStreamEventHasBytesAvailable:
        [self readFromStreamToInputBuffer];
        break;
        
      case NSStreamEventHasSpaceAvailable:
        // Should not happen for input stream!
        break;
        
      case NSStreamEventErrorOccurred:
        // Treat as "connection should be closed"
      case NSStreamEventEndEncountered:
        [self closeConnection];
        break;
    }
  }
  
  if (stream == outputStream) {
    switch (streamEvent) {
        
      case NSStreamEventOpenCompleted:
        isOutputStreamOpen = YES;
        [self finishOpeningConnection];
        break;
        
      case NSStreamEventHasBytesAvailable:
        // Should not happen for output stream!
        break;
        
      case NSStreamEventHasSpaceAvailable:
        [self writeOutputBufferToStream];
        break;
        
      case NSStreamEventErrorOccurred:
        // Treat as "connection should be closed"
      case NSStreamEventEndEncountered:
        [self closeConnection];
        break;
    }
  }
}





@end
