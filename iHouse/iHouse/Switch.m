//
//  Switch.m
//  iHouse
//
//  Created by Benjamin Völker on 11.02.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "Switch.h"
#import "Group.h"
#import "IDevice.h"
#import "SynthesizedSpeechHandler.h"
// All Commands that are send to or received by the serialport
#define COMMAND_RESPONSE @"/"
#define COMMAND_SWITCH @"s"
#define COMMAND_CMI @"c"
#define COMMAND_SNIFF_SWITCH @"w"
#define COMMAND_RECEIVE @"r"
#define COMMAND_CMI_ON @"01"
#define COMMAND_CMI_OFF @"10"


// For notification when a socket was sniffed succesfully
NSString * const SwitchSniffedSuccessfully = @"SwitchSniffedSuccessfully";
NSString * const KeySwitchItemGroup = @"KeySwitchItemGroup";
NSString * const KeySwitchItemDevice = @"KeySwitchItemDevice";
NSString * const KeySwitchItemSelector = @"KeySwitchItemSelector";

@implementation Switch
@synthesize type, cmiTristate, connectionHandler, switchItem;

- (id)init {
  self = [super init];
  if (self) {
    // Init global variable
    type = cmi_switch;
    cmiTristate = @"000000000000";
    switchItem = [[NSMutableDictionary alloc] init];
    [self codingIndependentInits];
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeBool:self.state forKey:@"state"];
  [encoder encodeInteger:self.type forKey:@"type"];
  [encoder encodeObject:self.cmiTristate forKey:@"cmiTristate"];
  [encoder encodeObject:self.switchItem forKey:@"switchItem"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    self.state = [decoder decodeBoolForKey:@"state"];
    self.type = [decoder decodeIntegerForKey:@"type"];
    self.cmiTristate = [decoder decodeObjectForKey:@"cmiTristate"];
    self.switchItem = [decoder decodeObjectForKey:@"switchItem"];
    [self codingIndependentInits];
  }
  return self;
}
/*
 * Inits that have to be done independent if the device is inited with decoder or inited traditional.
 */
- (void)codingIndependentInits {
  // Init the connectionHandler object
  connectionHandler = [SerialConnectionHandler sharedSerialConnectionHandler];
  // Add an observer to get meter data
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(checkSwitchData:)
                                               name:SerialConnectionHandlerSerialResponse
                                             object:nil];
  
}

- (void) checkSwitchData:(NSNotification*)notification {
  NSString *theCommand = [notification object];
  NSString *cmdPrefix = [NSString stringWithFormat:@"%@%@%@", COMMAND_RESPONSE, COMMAND_SWITCH, COMMAND_RECEIVE];
  NSLog(@"Received switch data: %@", theCommand);
  // If the beginning of the string contains the sniff command
  if ([[theCommand substringToIndex:[cmdPrefix length]] containsString:cmdPrefix]) {
    // Store the tristate
    NSString *tristate = [theCommand substringFromIndex:[cmdPrefix length]];
    // if the tristate is equal to us, switch
    if ([tristate containsString:cmiTristate]) {
      NSLog(@"Activate switch tristate: %@", tristate);
        // Activate after 1 second to avoid that user presses at the same time
        [self performSelector:@selector(activate) withObject:nil afterDelay:1];
    }
  }
}
  
  
/*
 * Returns if the socket switcher is connected over serial.
 */
- (BOOL)isConnected {
  return [connectionHandler serialPortIsOpen];
}

/*
 * Called if the user want to sniff a CMI device
 */
- (void)sniffCMI {
  // Register to get notifications if the serialport responsed with the tristate
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(sniffReceived:)
                                               name:SerialConnectionHandlerSerialResponse
                                             object:nil];
  // Send the sniff Command
  NSString *command = [NSString stringWithFormat:@"%@%@",COMMAND_SWITCH, COMMAND_SNIFF_SWITCH];
  NSDictionary* commandDict = [NSDictionary dictionaryWithObjectsAndKeys:command , SerialConnectionHandlerCommand, nil];
  //[[NSNotificationCenter defaultCenter] postNotificationName:ConnectionHandlerSerialCommand object:commandDict];
  [connectionHandler sendSerialCommand:commandDict];
}

/*
 * If something is received over serial this function looks if it is a socket sniff command and if so, stores the sniffed
 * Tristate and informs delegates that sniff succeeded
 */
- (void)sniffReceived:(NSNotification *)notification {
  NSString *theCommand = [notification object];
  NSString *cmdPrefix = [NSString stringWithFormat:@"%@%@%@", COMMAND_RESPONSE, COMMAND_SWITCH, COMMAND_SNIFF_SWITCH];
  // If the beginning of the string contains the sniff command
  if ([[theCommand substringToIndex:[cmdPrefix length]] containsString:cmdPrefix]) {
    // Store the tristate
    cmiTristate = [theCommand substringFromIndex:[cmdPrefix length]];
    //NSLog(@"Heurika: %@", cmiTristate);
    // Remove the observer from the notificationcenter
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SerialConnectionHandlerSerialResponse object:nil];
    // And inform other that sniffing was successfull
    [[NSNotificationCenter defaultCenter] postNotificationName:SwitchSniffedSuccessfully object:nil];
  }
}

/*
 * If the user pressed cancel the sniffing is aborted.
 */
- (void)sniffCMIDismissed {
  // Remove the observer
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SerialConnectionHandlerSerialResponse object:nil];
  // Send something stupid over serial to stop the sniffing
  NSString *command = [NSString stringWithFormat:@"%@%@",COMMAND_SWITCH, COMMAND_CMI_OFF];
  NSDictionary* commandDict = [NSDictionary dictionaryWithObjectsAndKeys:command , SerialConnectionHandlerCommand, nil];
  //[[NSNotificationCenter defaultCenter] postNotificationName:ConnectionHandlerSerialCommand object:commandDict];
  [connectionHandler sendSerialCommand:commandDict];
}


-(BOOL)activate {
  // If we should activate a group
  if ([switchItem objectForKey:KeySwitchItemGroup]) {
    Group *group = [switchItem objectForKey:KeySwitchItemGroup];
    NSLog(@"Activating group %@ via switch device", group.name);
    return [group activate];
    // If we should perform an action for a device
  } else if ([switchItem objectForKey:KeySwitchItemDevice]) {
    IDevice *device = [switchItem objectForKey:KeySwitchItemDevice];
    NSString *selector = [switchItem objectForKey:KeySwitchItemSelector];
    if (selector) {
      // Get the response from exectuting the selector
      NSDictionary *responseDict = [device executeSelector:selector];
      NSLog(@"Activate selector %@ from device %@ via switch", selector, device.name);
      NSLog(@"Response: %@", responseDict);
      
      if (!responseDict || ![[responseDict objectForKey:KeyVoiceCommandExecutedSuccessfully] boolValue]) {
        NSLog(@"Execution of Selector %@ failed", selector);
        return false;
      } else {
        // If this contains a response string get it
        if ([responseDict objectForKey:KeyVoiceCommandResponseString]) {
          NSString *speakIt = [responseDict objectForKey:KeyVoiceCommandResponseString];
          // If it contains an extra speek friendly string take this instead
          if ([responseDict objectForKey:KeyVoiceCommandResponseSpeechString]) {
            speakIt = [responseDict objectForKey:KeyVoiceCommandResponseSpeechString];
          }
          SynthesizedSpeechHandler *synthSpeechHandler = [SynthesizedSpeechHandler sharedSynthesizedSpeechHandler];
          [synthSpeechHandler speakStringIfReady:speakIt];
        }
      }
      return true;
    } else {
      NSLog(@"Error can not read selector from switch device %@", device.name);
    }
  }
  return false;
}

@end
