//
//  SerialConnectionHandler.m
//  iHouse
//
//  Created by Benjamin Völker on 06/07/15.
//  Copyright © 2015 Benjamin Völker.
//  eMail:      voelkerb@me.com.
//  Company:    University of Freiburg.
//  Education:  Master of Science, Embedded Systems Engineering.
//


#import "SerialConnectionHandler.h"
#import "AVBufferedPlayer.h"

#define DEBUG_SERIALPORT 1
#define SERIAL_BAUDRATE 115200
#define DISCOVERING_COMMAND @"?"
#define DISCOVERING_RESPONSE @"OK"
#define DISCOVERING_RESPONSE_TIMEOUT 2.5
#define OPEN_SERIALPORT_DELAY 2

const unsigned char SERIAL_PREFIXES[] = {(Byte)0xff, (Byte)0xfe};

NSString * const SerialConnectionHandlerSerialCommand = @"SerialConnectionHandlerSerialCommand";
NSString * const SerialConnectionHandlerSerialResponse = @"SerialConnectionHandlerSerialResponse";
NSString * const SerialConnectionHandlerCommand = @"SerialConnectionHandlerCommand";
NSString * const SerialConnectionHandlerData = @"SerialConnectionHandlerData";

@implementation SerialConnectionHandler
@synthesize serialPort, serialPortManager;
@synthesize baudrate, portName;



/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedSerialConnectionHandler {
  static SerialConnectionHandler *sharedSerialConnectionHandler = nil;
  @synchronized(self) {
    if (sharedSerialConnectionHandler == nil) {
        sharedSerialConnectionHandler = [[self alloc] init];
    }
  }
  return sharedSerialConnectionHandler;
}


- (id)init {
  self = [super init];
  if (self) {
    // Init all variables
    buffer = @"";
    portName = [NSString stringWithFormat:@""];
    baudrate = 0;
    serialPort.numberOfStopBits = 0;
    discoveringSerialPorts = false;
    
    // The serialPort singletone
    self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
		
    // Register notificationcenter to get notifications if new serialports were connected to the computer
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(serialPortsWereConnected:) name:ORSSerialPortsWereConnectedNotification object:nil];
    [nc addObserver:self selector:@selector(serialPortsWereDisconnected:) name:ORSSerialPortsWereDisconnectedNotification object:nil];
    // Register at user notificationcenter to show messages if ports were connected, disconnected or no device available
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    // We are the delegate of the serialport
    serialPort.delegate = self;
    
    // Register to get notifications if some device would like to send over the serialPort via notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sendSerialCommandNotification:)
                                                 name:SerialConnectionHandlerSerialCommand
                                               object:nil];
    
    // Get the last stored serialport
    Settings *settings = [Settings sharedSettings];
    if (DEBUG_SERIALPORT) NSLog(@"Available ports: %@", serialPortManager.availablePorts);
    if (DEBUG_SERIALPORT) NSLog(@"Stored port name: %@", [settings serialPortName]);
    
    // Try to open the last stored serialport
    if (![self openPort:SERIAL_BAUDRATE :[settings serialPortName]]) {
      // If this does not work, begin to discover for serialports
      discoveringSerialPorts = true;
      [self discoverSerialPorts:serialPortManager.availablePorts];
    // Else post a user notification, that an iHouse device is connected successfully
    } else {
      [self postUserNotificationForConnectedToiHouseDevice:[serialPort name]];
    }
    
  }
  return self;
}

/*
 * This function discoveres an array of given serialports. It tries to open the port and sends a specific identification command.
 * If the Serialport responsed correctly, the port is used and stored as the default device.
 * If the Serialport did not response or can not be opened, the next port is discovered until all ports were discovered.
 * If no port responsed correctly a notification is posted.
 */
// The currently discovered serialport number
NSInteger discoveredPort = 0;
- (void)discoverSerialPorts:(NSArray*) theSerialPorts {
  // If the Port responsed correctly discovering can be stopped
  if (!discoveringSerialPorts) return;
  // If not, close the port that is currently opened
  if (serialPort.isOpen) {
    [serialPort close];
    if (DEBUG_SERIALPORT) NSLog(@"...closed without response");
  } else {
    if (DEBUG_SERIALPORT) NSLog(@"...failed to open");
  }
  // If at least one serialport is left for discovery, try to open it
  if ([theSerialPorts count] > discoveredPort) {
    if (DEBUG_SERIALPORT) NSLog(@"Try port: %@", [(ORSSerialPort*)[theSerialPorts objectAtIndex:discoveredPort] name]);
    // If the Serialport was opened successfully
    if ([self openPort:SERIAL_BAUDRATE :[(ORSSerialPort*)[theSerialPorts objectAtIndex:discoveredPort] path]]) {
      // Send the discovering command after a delay because the port needs an initial delay to responde
      [self performSelector:@selector(sendStringWithPrefix:) withObject:DISCOVERING_COMMAND afterDelay:OPEN_SERIALPORT_DELAY];
      // Indicate the discovering with a user notification
      [self postUserNotificationForDiscoveringPorts:[(ORSSerialPort*)[theSerialPorts objectAtIndex:discoveredPort] name]];
      // Start a new discovery if the port wont response in given time
      [self performSelector:@selector(discoverSerialPorts:) withObject:theSerialPorts afterDelay:DISCOVERING_RESPONSE_TIMEOUT];
    } else {
      // If the port could not be opened, immidiately start a new discovery
      [self performSelector:@selector(discoverSerialPorts:) withObject:theSerialPorts afterDelay:0.1];
    }
    // Increment serialport pointer
    discoveredPort++;
  // If all ports were discovered
  } else {
    // Stop discovering and post no device notification
    if (DEBUG_SERIALPORT) NSLog(@"No port available");
    discoveredPort = 0;
    [self postUserNotificationForNoDevice];
  }
}

/*
 * This function is called when the port could be opened and responde to the discovering command
 */
- (void)portFound:(NSString*) response {
  // If the response is correct
  if ([response containsString:DISCOVERING_RESPONSE]) {
    // The port is stored and used as the default device
    discoveringSerialPorts = false;
    Settings *settings = [Settings sharedSettings];
    settings.serialPortName = [serialPort path];
    if ([settings store:self]) {
      // The serialport pointer is resetted and a notification is posted indicating that the
      // Serialport was successfully discovered
      discoveredPort = 0;
      if (DEBUG_SERIALPORT) NSLog(@"Port found: %@", [settings serialPortName]);
      [self postUserNotificationForConnectedToiHouseDevice:[serialPort name]];
    }
  }
}

/*
 * Returns if the serialport is open or not
 */
- (BOOL)serialPortIsOpen {
  return serialPort.isOpen;
}

/*
 * Opens a given serialport connection
 */
- (BOOL)openPort:(int)theBaudrate :(NSString *)thePortName {
  portName = thePortName;
  baudrate = theBaudrate;
    
  serialPort = [ORSSerialPort serialPortWithPath:portName];
  serialPort.baudRate = [NSNumber numberWithInteger:baudrate];
    
  [serialPort open];
  serialPort.delegate = self;
  [serialPort setDTR:true];
  return serialPort.isOpen;
}

/*
 * Close the current serialport
 */
- (void)closePort {
  [serialPort close];
  serialPort.delegate = nil;
  serialPort = nil;
  serialPortManager = nil;
}

/*
 * Sends NSData to the serialport with prefix
 */
- (BOOL)sendDataWithPrefix:(NSData *)theData {
  NSMutableData *concatenatedData = [NSMutableData data];
  [concatenatedData appendData:[NSData dataWithBytes:SERIAL_PREFIXES length:sizeof(SERIAL_PREFIXES)]];
  [concatenatedData appendData:theData];
  return [serialPort sendData:concatenatedData];
}

/*
 * Sends a String to the serialport with prefix
 */
- (BOOL)sendStringWithPrefix:(NSString *)theString {
	NSData *dataToSend = [theString dataUsingEncoding:NSUTF8StringEncoding];
	return [self sendDataWithPrefix:dataToSend];
}

/*
 * Sends a string to the serialport
 */
- (BOOL)sendString:(NSString *)theString {
  NSData *dataToSend = [theString dataUsingEncoding:NSUTF8StringEncoding];
  return [serialPort sendData:dataToSend];
}

/*
 * Sends one single byte with prefix to the serialport
 */
- (BOOL)sendByteWithPrefix:(int)integer {
  Byte data = (Byte) integer;
  NSData *dataToSend = [NSData dataWithBytes:&data length:1];
  return [self sendDataWithPrefix:dataToSend];
}

/*
 * Sends one single byte to the serialport
 */
- (BOOL)sendByte:(int)integer {
  Byte data = (Byte) integer;
  NSData *dataToSend = [NSData dataWithBytes:&data length:1];
  return [serialPort sendData:dataToSend];
}


/*
 * Sends a given command as dictionary to the serial port with prefix
 */
- (BOOL)sendSerialCommand:(NSDictionary *)theDataAsDict {
  // If the port is not opened, post an alert and return false
  if (!serialPort.isOpen) return false;
  
  // If the port is open try to decode the data from the command dictionary
  NSMutableData *theData = [NSMutableData data];
  // If a commandstring exist, extract it and encode it as data
  if ([theDataAsDict objectForKey:SerialConnectionHandlerCommand]) {
    [theData appendData:[[theDataAsDict objectForKey:SerialConnectionHandlerCommand] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  // If data exist append it to the current data
  if ([theDataAsDict objectForKey:SerialConnectionHandlerData]) {
    [theData appendData:[theDataAsDict objectForKey:SerialConnectionHandlerData]];
  }
  
  // if the data is not nil send it with prefix
  if (theData) [self sendDataWithPrefix:theData];
  return true;
}

#pragma mark - called from notificationcenter and thus from every device that wants to send sth over serial
/*
 * Sends a given command as dictionary to the serial port with prefix but without a response for the caller
 */
- (void)sendSerialCommandNotification:(NSNotification *)notification {
  // If the port is not opened, post an alert and return
  if (!serialPort.isOpen) return;

  // Get the command from the notification
  NSDictionary *theDataAsDict = [notification object];
  // If the port is open try to decode the data from the command dictionary
  NSMutableData *theData = [NSMutableData data];
  // If a commandstring exist, extract it and encode it as data
  if ([theDataAsDict objectForKey:SerialConnectionHandlerCommand]) {
    [theData appendData:[[theDataAsDict objectForKey:SerialConnectionHandlerCommand] dataUsingEncoding:NSUTF8StringEncoding]];
  }
  // If data exist append it to the current data
  if ([theDataAsDict objectForKey:SerialConnectionHandlerData]) {
    [theData appendData:[theDataAsDict objectForKey:SerialConnectionHandlerData]];
  }
  
  // if the data is not nil send it with prefix
  if (theData) [self sendDataWithPrefix:theData];
}


#pragma mark - ORSSerialPortDelegate Delegates
/*
 * Is called when a serialport connection was opened succesfully
 */
- (void)serialPortWasOpened:(ORSSerialPort *)serialPort {
  if (DEBUG_SERIALPORT) NSLog(@"SerialPortOpened");
}

/*
 * Is called when a serialport connection was closed
 */
- (void)serialPortWasClosed:(ORSSerialPort *)serialPort {
  if (DEBUG_SERIALPORT) NSLog(@"SerialPortClosed");
}

/*
 * Is called if a serialport received data
 */
- (void)serialPort:(ORSSerialPort *)theSerialPort didReceiveData:(NSData *)data {
  // If it is not our serial port stop
  if (theSerialPort != self.serialPort) return;
  //NSLog(@"%li", [data length]);
  // If data block is not huge it may be a command
  if ([data length] < 60) {
    // Data is always send as strings
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // If the data does not contain usefull information return
    if ([string length] == 0) return;
    if ([string length] > 1000) return;
    // Buffer the command
    buffer = [NSString stringWithFormat:@"%@%@", buffer, string];
    // If the buffer contains one or more commands, the command needs to be extracted properly
    // without disregarding other commands
    while ([buffer rangeOfString:@"\n"].location != NSNotFound) {
      NSUInteger loc = [buffer rangeOfString:@"\n"].location;
      if (loc == 0) loc++;
      // Get one command properly
      NSString *command = [NSString stringWithFormat:@"%@", [buffer substringToIndex:loc - 1]];
    
      if (discoveringSerialPorts) {
        if (DEBUG_SERIALPORT) NSLog(@"Search for response");
        [self portFound:command];
      } else {
        if (DEBUG_SERIALPORT) NSLog(@"Received command: %@", command);
        // Post notification so others can do sth with the command now
        [[NSNotificationCenter defaultCenter] postNotificationName:SerialConnectionHandlerSerialResponse object:command];
      }
      // Store the rest of the command(s)
      if ([buffer length] >= loc + 1) buffer = [buffer substringFromIndex:loc + 1];
    }
  // If it is a huge block of data, regard it as audio data
  } else {
    // Convert the data to int (pointer to avoid copy)
    int8_t *intData = (int8_t *)[data bytes];
    // Keep track of how many audio samples to add
    long blockSize = [data length];
    // Allocate float array to hold data
    float *block = (float *)malloc(blockSize * sizeof(float));
    // Copy values to float
    for (int i = 0; i < blockSize; i++) {
      // For conversion regard data as 16 bit int, convert it to float
      // and scale it to [-1:1]
      // Since it is constructed from 16 Bit int, values can reach from
      // -2^15 to 2^15 -> 32768
      block[i] = (float)((int16_t)(intData[i] << 8))/32768.0f;
      //block[i] = (float)((int16_t)(intData[i] << 8))/65536.0f;
    }
    // Get singletone of the player object
    if (ENABLE_USB_AUDIO) {
      AVBufferedPlayer *avBuffPlayer = [AVBufferedPlayer sharedAVBufferedPlayer];
      // Add float to queue
      [avBuffPlayer addToQueue:block :(int)blockSize];
    }
    
    // Print it for debugging
    /*
    for (int i = 0; i < [data length]; ++i) {
      //NSLog(@"%d\n", values[i]);
      NSLog(@"%.2f\n", block[i]);
    }*/
  }
}

/*
 * Is called if a serialport was completely removed from the system
 */
- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)theSerialPort {
	// After a serial port is removed from the system, it is invalid and we must discard any references to it
  if ([theSerialPort isEqualTo:self.serialPort]) self.serialPort = nil;
}

/*
 * Is called if a serialport encountered an error
 */
- (void)serialPort:(ORSSerialPort *)theSerialPort didEncounterError:(NSError *)error {
	NSLog(@"Serial port %@ encountered an error: %@", theSerialPort, error);
}

#pragma mark - NSUserNotificationCenterDelegate

#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
/*
 * Is called if a notification was delivered
 */
- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification {
  // Remove all notification after 5 seconds
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[center removeDeliveredNotification:notification];
	});
}

/*
 * If notifications should be shown
 */
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
	return YES;
}

#endif

#pragma mark - Notifications
/*
 * Post a notification if new serialports are connected
 */
- (void)serialPortsWereConnected:(NSNotification *)notification {
	NSArray *connectedPorts = [[notification userInfo] objectForKey:ORSConnectedSerialPortsKey];
	NSLog(@"Ports were connected: %@", connectedPorts);
  // If currently no serialport is connected try to discover the newly attached serialports
  if (![self serialPortIsOpen]) {
    [self performSelector:@selector(discoverSerialPorts:) withObject:connectedPorts afterDelay:OPEN_SERIALPORT_DELAY];
  }
}

/*
 * Post a notification if new serialports are disconnected
 */
- (void)serialPortsWereDisconnected:(NSNotification *)notification {
	NSArray *disconnectedPorts = [[notification userInfo] objectForKey:ORSDisconnectedSerialPortsKey];
	NSLog(@"Ports were disconnected: %@", disconnectedPorts);
  // If the currently used serialport is disconnected, show a userNotification and distroy object
  for (ORSSerialPort *theSerialPort in disconnectedPorts) {
    if ([[theSerialPort path] isEqualToString:[[Settings sharedSettings] serialPortName]]) {
      [self.serialPort close];
      self.serialPort = nil;
      [self postUserNotificationForNoDevice];
    }
  }
}

/*
 * Post a notification if new serialports are connected
 */
- (void)postUserNotificationForConnectedPorts:(NSArray *)connectedPorts {
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
	if (!NSClassFromString(@"NSUserNotificationCenter")) return;
	NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
	for (ORSSerialPort *port in connectedPorts) {
		NSUserNotification *userNote = [[NSUserNotification alloc] init];
		userNote.title = NSLocalizedString(@"Serial Port Connected", @"Serial Port Connected");
		NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was connected to your Mac.", @"Serial port connected user notification informative text");
		userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
		userNote.soundName = nil;
		[unc deliverNotification:userNote];
	}
#endif
}

/*
 * Post a notification if new serialports are disconnected
 */
- (void)postUserNotificationForDisconnectedPorts:(NSArray *)disconnectedPorts {
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
	if (!NSClassFromString(@"NSUserNotificationCenter")) return;
	NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
	for (ORSSerialPort *port in disconnectedPorts) {
		NSUserNotification *userNote = [[NSUserNotification alloc] init];
		userNote.title = NSLocalizedString(@"Serial Port Disconnected", @"Serial Port Disconnected");
		NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ was disconnected from your Mac.", @"Serial port disconnected user notification informative text");
		userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
		userNote.soundName = nil;
		[unc deliverNotification:userNote];
	}
#endif
}

/*
 * Post a notification if a new serialport is discovered
 */
- (void)postUserNotificationForDiscoveringPorts:(NSString *)discoveringPortName {
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
  if (!NSClassFromString(@"NSUserNotificationCenter")) return;
  NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
  NSUserNotification *userNote = [[NSUserNotification alloc] init];
  userNote.title = NSLocalizedString(@"Serial Port Discovery", @"Serial Port Discovery");
  NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ is discovered for beeing an iHouse device", @"Serial port discovery user notification informative text");
  userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, discoveringPortName];
  userNote.soundName = nil;
  [unc deliverNotification:userNote];
#endif
}

/*
 * Post a notification if a new serialport is connected as iHouse device
 */
- (void)postUserNotificationForConnectedToiHouseDevice:(NSString *)devicePortName {
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
  if (!NSClassFromString(@"NSUserNotificationCenter")) return;
  NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
  NSUserNotification *userNote = [[NSUserNotification alloc] init];
  userNote.title = NSLocalizedString(@"iHouse Device connected", @"iHouse Device connected");
  NSString *informativeTextFormat = NSLocalizedString(@"Serial Port %@ is connected as iHouse device", @"iHouse device connected user notification informative text");
  userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, devicePortName];
  userNote.soundName = nil;
  [unc deliverNotification:userNote];
#endif
}

/*
 * Post a notification if no iHouse device is connected
 */
- (void)postUserNotificationForNoDevice {
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
  if (!NSClassFromString(@"NSUserNotificationCenter")) return;
  NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
  NSUserNotification *userNote = [[NSUserNotification alloc] init];
  userNote.title = NSLocalizedString(@"No iHouse Device connected", @"No iHouse Device connected");
  userNote.informativeText = NSLocalizedString(@"No iHouse device is connected to this computer, connect a device to make your home smarter", @"No iHouse device connected user notification informative text");
  userNote.soundName = nil;
  [unc deliverNotification:userNote];
#endif
}



@end
