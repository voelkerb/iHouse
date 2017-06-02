//
//  Switch.h
//  iHouse
//
//  Created by Benjamin Völker on 11.02.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SerialConnectionHandler.h"

extern NSString * const SwitchSniffedSuccessfully;
extern NSString * const KeySwitchItemGroup;
extern NSString * const KeySwitchItemDevice;
extern NSString * const KeySwitchItemSelector;

@interface Switch : NSObject <NSCoding>
// The different possible devices as an ENUM
typedef NS_ENUM(NSUInteger, SwitchType) {
  cmi_switch
};


// The socket type (see enums from above)
@property SwitchType type;

// The connection handler object
@property (strong) SerialConnectionHandler *connectionHandler;

// The CMI tristate code
@property NSString *cmiTristate;

// A dictionary holding the group or device
@property (strong) NSMutableDictionary *switchItem;


// The current state
@property (nonatomic) BOOL state;

// Return if device is connected over serial
- (BOOL)isConnected;
// Learn a new CMI device
- (void)sniffCMI;
// If sniffing was dismissed
- (void)sniffCMIDismissed;

// Activate the switchitem
-(BOOL)activate;

@end
