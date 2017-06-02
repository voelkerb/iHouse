//
//  TV.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "IPadDisplay.h"
#import "TCPServer.h"
#import "House.h"

#define DEBUG_IPAD 1

#define DISCOVER_COMMAND_RESPONSE @"iHouseRemote"
#define SYNC_COMMAND @"sync"
#define AUTOSYNC_COMMAND @"autoSync"
#define IDENTIFY_COMMAND @"identy"
#define SYNC_KEY_TYPE @"type"
#define SYNC_KEY_ROOM @"room"
#define SYNC_KEY_NAME @"name"
#define SYNC_KEY_IMAGE @"image"

@implementation IPadDisplay

@synthesize tcpConnectionHandler, host, autoSync;

- (id)init {
  self = [super init];
  if (self) {
    // TODO: Init stuff goes here
    host = @"";
    [self codingIndependentInits];
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  // TODO: Coding stuff goes here
  [encoder encodeObject:self.host forKey:@"host"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    // TODO: decoding stuff goes here
    self.host = [decoder decodeObjectForKey:@"host"];
    [self codingIndependentInits];
  }
  return self;
}
// Inits that must be done either if this object is newly inited or inted from file
- (void)codingIndependentInits {
  tcpConnectionHandler = [[TCPConnectionHandler alloc] init];
  tcpConnectionHandler.delegate = self;
  autoSync = true;
}


/*
 * Returns if the device is connected over tcp or not.
 */
- (void)identify {
  // TODO:
  [tcpConnectionHandler sendCommand:IDENTIFY_COMMAND];
  // TODO Test
  [self receivedCommand:SYNC_COMMAND];
}


/*
 * Returns if the device is connected over tcp or not.
 */
- (BOOL)isConnected {
  return [tcpConnectionHandler isConnected];
}

/*
 * If the device connected successfully.
 */
-(void)deviceConnected:(GCDAsyncSocket *)sock {
  tcpConnectionHandler = [[TCPConnectionHandler alloc] initWithSocket:sock];
  tcpConnectionHandler.delegate = self;
  // TODO:
  // If a device connected, let it sync itself by sending an autosync command
  if (autoSync) {
    [tcpConnectionHandler sendCommand:AUTOSYNC_COMMAND];
    autoSync = false;
  }
}

/*
 * If the device sent a command to us.
 */
-(void)receivedCommand:(NSString *)theCommand {
  if (DEBUG_IPAD) NSLog(@"Received remote Command: %@", theCommand);
  
  if ([theCommand isEqualToString:SYNC_COMMAND]) {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    // Get every object inside the House
    House *theHouse = [House sharedHouse];
    // Loop over all rooms
    for (Room *theRoom in [theHouse rooms]) {
      // And all devices
      for (IDevice *theDevice in [theRoom devices]) {
        // If the type is not a remote
        if (theDevice.type != iPadDisplay) {
          // Get information of it
          NSData *sourceImageData = [theDevice.image TIFFRepresentation];
          NSData *imageData = [self imageResize:sourceImageData newSize:NSMakeSize(512, 512)];
          NSDictionary *dev = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithInteger:theDevice.type], SYNC_KEY_TYPE,
                               theDevice.name, SYNC_KEY_NAME,
                               theDevice.roomName, SYNC_KEY_ROOM,
                               imageData, SYNC_KEY_IMAGE,
                               nil];
        
          [array addObject:dev];
        }
      }
    }
    // Convert array to data
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:array];
    //if (DEBUG_IPAD) NSLog(@"Number of kB: %.2f", (data.length/1024.0f));
    if (DEBUG_IPAD) NSLog(@"Number of %li Bytes", (data.length));
    
    // Indicate that it is data by sending '/' at first
    char c = '/';
    NSMutableData *commandAndData = [[NSMutableData alloc] initWithBytes:&c length:1];
    
    // Get length of data as long value
    SInt64 long_value = CFSwapInt64HostToBig(data.length);
    // Pointer to long
    UInt8 *long_ptr = (UInt8 *)& long_value;
    // Store long into byte array and thus append the length of the data to be buffered
    [commandAndData appendData:[[NSData alloc] initWithBytes:long_ptr length:8]];
    // Appeld the data and send it
    [commandAndData appendData:data];
    [tcpConnectionHandler sendData:commandAndData];
    //NSLog(@"Data: %@", data);
  }
}

- (NSData *)imageResize:(NSData*)sourceData newSize:(NSSize)newSize {
  float resizeWidth = newSize.width;
  float resizeHeight = newSize.height;
  
  NSImage *sourceImage = [[NSImage alloc] initWithData: sourceData];
  NSImage *resizedImage = [[NSImage alloc] initWithSize: NSMakeSize(resizeWidth, resizeHeight)];
  
  NSSize originalSize = [sourceImage size];
  
  [resizedImage lockFocus];
  [sourceImage drawInRect: NSMakeRect(0, 0, resizeWidth, resizeHeight) fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height) operation: NSCompositeSourceOver fraction: 1.0];
  [resizedImage unlockFocus];
  
  return [resizedImage TIFFRepresentation];
}

/*
 * Returns the discovering command response for discovering hoovers.
 */
-(NSString *)discoverCommandResponse {
  return DISCOVER_COMMAND_RESPONSE;
}

/*
 * To make the socket free if the device is deleted
 */
- (void) freeSocket {
  // Free the socket again
  if (DEBUG_IPAD) NSLog(@"Free socket of remote");
  if (!tcpConnectionHandler.socket) return;
  TCPServer *tcpServer = [TCPServer sharedTCPServer];
  [tcpServer freeSocket:tcpConnectionHandler.socket];
}


@end
