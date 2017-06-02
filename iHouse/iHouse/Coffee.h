//
//  Coffee.h
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "TCPConnectionHandler.h"

#define AROMA_MAX 6
#define BRIGHTNESS_MAX 10

@interface Coffee : NSObject <NSCoding, TCPConnectionHandlerDelegate> {
  BOOL waitingForDone;
  BOOL waterEmpty;
  BOOL containerOpen;
  BOOL beansEmpty;
  BOOL noCups;
  BOOL waterFull;
}

// The different possible beverages as an ENUM
typedef NS_ENUM(NSUInteger, CoffeeBeverage) {
  coffeeMashine_coffee,
  coffeeMashine_cappuccino,
  coffeeMashine_latte,
  coffeeMashine_espresso,
  coffeeMashine_milk,
  coffeeMashine_water,
  coffeeMashine_numberOfBeverages
};

// The different possible errors as an ENUM
typedef NS_ENUM(NSUInteger, CoffeeError) {
  no_error,
  error_waiting_for_done,
  error_water_empty,
  error_water_full,
  error_beans_empty,
  error_container_open,
  error_no_cups,
  error_not_connected
};

// The host ip adress of the display
@property NSString *host;
// A connection handler object for the tcp connection
@property (strong) TCPConnectionHandler *tcpConnectionHandler;

// The currently set aroma of the coffe mashine
@property NSInteger aroma;
// The currently set display brightness of the mashine
@property NSInteger brightness;

// If the mashine is connected
- (BOOL)isConnected;

// Making a sweet beverage
- (CoffeeError)makeBeverage:(CoffeeBeverage) theBeverage : (BOOL)withCup;
// Make a factory reset
- (CoffeeError)factoryReset;
// Toggle mashine on or off
- (CoffeeError)toggleMashine:(BOOL)toOn;
// Set Aroma
- (CoffeeError)setTheAroma:(NSInteger)theAroma;
// Set the brightness level
- (CoffeeError)setTheBrightness:(NSInteger)theBrightness;
// Make calc clean
- (CoffeeError)makeCalcClean;


- (NSString*)coffeeBeverageToString:(CoffeeBeverage) theType;

// If the display device connected successfully
- (void)deviceConnected:(GCDAsyncSocket *)sock;

// Get the discovering response of displays
- (NSString*)discoverCommandResponse;
- (void) freeSocket;

// Respond to detected voice commands
- (NSDictionary*)respondToCommand:(NSString*) command;

// Return the standard voice commands
- (NSArray*)standardVoiceCommands;
// Return the available selectors for voice commands
- (NSArray*)selectors;
// Return the available voice actions
- (NSArray*)readableSelectors;
@end
