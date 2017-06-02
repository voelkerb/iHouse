//
//  Coffee.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "Coffee.h"
#import "TCPServer.h"
#import "VoiceCommand.h"

#define DEBUG_COFFEE true

#define DISCOVER_COMMAND_RESPONSE @"iHouseCoffee"
#define COFFEE_TYPE_NAME @"Coffee Mashine"


#define COMMAND_PREFIX @"/"
#define COMMAND_PREFIX_CUP @"q"
#define COMMAND_GET_CUP @"c"
#define DONE @"d"
#define ERROR_WATER_EMPTY_DELAY 12
#define ERROR_WATER_EMPTY @"f0"
#define ERROR_CONTAINER_OPEN @"f1"
#define ERROR_BEANS_EMPTY @"f2"
#define ERROR_WATER_FULL @"f3"
#define ERROR_CUPS_EMPTY @"f7"
#define COMMAND_ON @"o"
#define COMMAND_START @"b"
#define COMMAND_STOP @"s"
#define COMMAND_MENU @"?"
#define COMMAND_SET_BRIGHTNESS @"?2"
#define COMMAND_FACTORY_RESET @"?6"
#define COMMAND_AROMA @"a"
#define COMMAND_OBERRIDE_AROMA @"!"
#define COMMAND_COFFEE @"k"
#define COMMAND_LATTE @"l"
#define COMMAND_CAPPUCCINO @"c"
#define COMMAND_ESPRESSO @"e"
#define COMMAND_MILK @"m"
#define COMMAND_WATER @"w"
#define STANDARD_BRIGHTNESS 5
#define STANDARD_AROMA 3


#define VOICE_COMMAND_ON @"Turn coffee machine on"
#define VOICE_RESPONSES_ON @"The coffee machine turns on now.", @"Your coffee is just 10 seconds away.", @"Okay the machine will be ready soon."

#define VOICE_COMMAND_OFF @"Turn coffee machine off"
#define VOICE_RESPONSES_OFF @"The coffee machine turns off now.", @"Okay, no more coffee today.", @"Too bad, I like the smell of hot coffee."

#define VOICE_COMMAND_COFFEE @"Make Coffee"
#define VOICE_RESPONSES_COFFEE @"Okay, I will make a sweet coffee for you.", @"Hmm, I like the smell of hot coffee."
#define VOICE_RESPONSES_COFFEE_IMAGE @"coffee.bmp"

#define VOICE_COMMAND_ESPRESSO @"Make Espresso"
#define VOICE_RESPONSES_ESPRESSO @"Coffeine will run through your vains", @"Okay, I will make a sweet Espresso for you."
#define VOICE_RESPONSES_ESPRESSO_IMAGE @"espresso.bmp"

#define VOICE_COMMAND_LATTE @"Make Latte macchiato"
#define VOICE_RESPONSES_LATTE @"Okay, I will make a sweet Latte for you."
#define VOICE_RESPONSES_LATTE_IMAGE @"latte.bmp"

#define VOICE_COMMAND_CAPPUCCINO @"Make Cappuccino"
#define VOICE_RESPONSES_CAPPUCCINO @"Okay, I will make a sweet Cappuccino for you.", @"Milk, I need milk!"
#define VOICE_RESPONSES_CAPPUCCINO_IMAGE @"cappuccino.bmp"

#define VOICE_COMMAND_WATER @"Make hot water"
#define VOICE_RESPONSES_WATER @"Okay, hot water is brewing.", @"It's tea time."
#define VOICE_RESPONSES_WATER_IMAGE @"water.bmp"

#define VOICE_COMMAND_MILK @"Make hot milk"
#define VOICE_RESPONSES_MILK @"Okay, milk will be warmed."
#define VOICE_RESPONSES_MILK_IMAGE @"milk.bmp"


#define VOICE_RESPONSES_NO_WATER @"Sorry but you need to refill water first.", @"I would like to do so, but the machine has no water.", @"Sorry bro, but the water is empty."
#define VOICE_RESPONSES_NO_BEANS @"Warning: The beans seem to be emtpy."
#define VOICE_RESPONSES_CONTAINER @"Sorry but the container is open.", @"You should have closed the container, I can not do this for you."
#define VOICE_RESPONSES_WATER_FULL @"Warning: You need to empty the water reservoir."
#define VOICE_RESPONSES_NO_CUPS @"Warning: You don't have cups left in your machine."
#define VOICE_RESPONSES_WAIT @"We first have to wait, it seems that others like coffee too.", @"Sorry but other tasks are in the queue."
#define VOICE_RESPONSES_NOT_CONNECTED @"Connection problem.", @"Sorry but the Coffee machine is not connected."

@implementation Coffee
@synthesize tcpConnectionHandler, host, brightness, aroma;

- (id)init {
  self = [super init];
  if (self) {
    // Init stuff goes here
    brightness = STANDARD_BRIGHTNESS;
    aroma = STANDARD_BRIGHTNESS;
    host = @"";
    [self codingIndependentInits];
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  // Coding stuff goes here
  [encoder encodeObject:self.host forKey:@"host"];
  [encoder encodeInteger:self.aroma forKey:@"aroma"];
  [encoder encodeInteger:self.brightness forKey:@"brightness"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    // decoding stuff goes here
    self.host = [decoder decodeObjectForKey:@"host"];
    self.aroma = [decoder decodeIntegerForKey:@"aroma"];
    self.brightness = [decoder decodeIntegerForKey:@"brightness"];
    [self codingIndependentInits];
  }
  return self;
}

// Inits that must be done either if this object is newly inited or inted from file
- (void)codingIndependentInits {
  tcpConnectionHandler = [[TCPConnectionHandler alloc] init];
  tcpConnectionHandler.delegate = self;
  waitingForDone = false;
  waterEmpty = false;
  waterFull = false;
  containerOpen = false;
  beansEmpty = false;
  noCups = false;
}

/*
 * If the device connected successfully.
 */
-(void)deviceConnected:(GCDAsyncSocket *)sock {
  tcpConnectionHandler = [[TCPConnectionHandler alloc] initWithSocket:sock];
  tcpConnectionHandler.delegate = self;
}

/*
 * Returns if the Coffe mashine is connected over tcp or not.
 */
- (BOOL)isConnected {
  return [tcpConnectionHandler isConnected];
}

/*
 * Makes the given baverage.
 */
-(CoffeeError)makeBeverage:(CoffeeBeverage)theBeverage : (BOOL)withCup {
  // Look if there is any error yet
  CoffeeError theError = [self handleError];
  // On critical errors stop immidiately
  if (theError == error_water_empty || theError == error_container_open || theError == error_waiting_for_done) return theError;
  
  // According to the selected beverage select the proper command
  NSString *command = [[NSString alloc] init];
  command = @"";
  switch(theBeverage) {
    case coffeeMashine_coffee:
      command = COMMAND_COFFEE;
      break;
    case coffeeMashine_cappuccino:
      command = COMMAND_CAPPUCCINO;
      break;
    case coffeeMashine_espresso:
      command = COMMAND_ESPRESSO;
      break;
    case coffeeMashine_latte:
      command = COMMAND_LATTE;
      break;
    case coffeeMashine_milk:
      command = COMMAND_MILK;
      break;
    case coffeeMashine_water:
      command = COMMAND_WATER;
      break;
    default:
      [NSException raise:NSGenericException format:@"Unexpected MODE."];
  }
  
  // If a cup should be added, place it first under the machine
  if (withCup) {
    [self sendCupCommand:COMMAND_GET_CUP];
  }
  
  // We must wait until the machine is ready
  waitingForDone = true;
  // Send the command to execute beverage dispense
  [self sendCommand:command];
  // Return the error if sth happened
  return theError;
}

/*
 * Starts a calc clean on the mashine. This takes up to 30 min to finish.
 */
-(CoffeeError)makeCalcClean {
  // Look if there is any error yet
  CoffeeError theError = [self handleError];
  // On critical errors stop immidiately
  if (theError == error_water_empty || theError == error_container_open || theError == error_waiting_for_done) return theError;
  // TODO: implement
  
  return theError;
}

/*
 * Sets the brightnesslevel of the display
 */
-(CoffeeError)setTheBrightness:(NSInteger)theBrightness {
  // Look if there is any error yet
  CoffeeError theError = [self handleError];
  // On critical errors stop immidiately
  if (theError == error_water_empty || theError == error_container_open || theError == error_waiting_for_done) return theError;
  // We must wait for the task to finish afterwards
  waitingForDone = true;
  bool success = [self sendCommand:[NSString stringWithFormat:@"%@%li", COMMAND_SET_BRIGHTNESS, theBrightness]];
  // Update brightness on success
  if (success) brightness = theBrightness;
  return theError;
}


/*
 * Sets the aroma level of the mashine
 */
-(CoffeeError)setTheAroma:(NSInteger)theAroma {
  // Look if there is any error yet
  CoffeeError theError = [self handleError];
  // On critical errors stop immidiately
  if (theError == error_water_empty || theError == error_container_open || theError == error_waiting_for_done) return theError;
  // We must wait for the task to finish afterwards
  waitingForDone = true;
  bool success = [self sendCommand:[NSString stringWithFormat:@"%@%li", COMMAND_AROMA, theAroma]];
  if (success) aroma = theAroma;
  return theError;
}

/*
 * Make a factory reset
 */
-(CoffeeError)factoryReset {
  // Look if there is any error yet
  CoffeeError theError = [self handleError];
  // On critical errors stop immidiately
  if (theError == error_water_empty || theError == error_container_open || theError == error_waiting_for_done) return theError;
  waitingForDone = true;
  bool success = [self sendCommand:COMMAND_FACTORY_RESET];
  // Set values back to standard
  if (success) {
    brightness = STANDARD_BRIGHTNESS;
    aroma = STANDARD_BRIGHTNESS;
  }
  return theError;
}

/*
 * Convert the command to the data and send it with newline and prefix.
 */
-(BOOL)sendCommand:(NSString*)c {
  NSMutableData *data = [[NSMutableData alloc] init];
  NSString *command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX, c];
  [data appendData:[command dataUsingEncoding:NSUTF8StringEncoding]];
  return [tcpConnectionHandler sendData:data];
}

/*
 * Set a cup under the machine
 */
-(BOOL)sendCupCommand:(NSString*)c {
  NSMutableData *data = [[NSMutableData alloc] init];
  NSString *command = [NSString stringWithFormat:@"%@%@\n", COMMAND_PREFIX_CUP, c];
  [data appendData:[command dataUsingEncoding:NSUTF8StringEncoding]];
  return [tcpConnectionHandler sendData:data];
}

/*
 * Toggles the machine on or off
 */
-(CoffeeError)toggleMashine:(BOOL)toOn {
  // Look if there is any error yet
  CoffeeError theError = [self handleError];
  // Only if a task is performed, we can not turn the machine off
  // Stop here immidiately
  if (waitingForDone) return theError;
  // We must wait for completion afterwards
  waitingForDone = true;
  // Send on/off command (same for both)
  [self sendCommand:COMMAND_ON];
  
  return theError;
}

/*
 * Return string from beverage enum
 */
- (NSString*)coffeeBeverageToString:(CoffeeBeverage) theType {
  NSString *result = nil;
  switch(theType) {
    case coffeeMashine_coffee:
      result = @"Coffee";
      break;
    case coffeeMashine_cappuccino:
      result = @"Cappuccino";
      break;
    case coffeeMashine_espresso:
      result = @"Espresso";
      break;
    case coffeeMashine_latte:
      result = @"Latte Macchiato";
      break;
    case coffeeMashine_milk:
      result = @"Hot Milk";
      break;
    case coffeeMashine_water:
      result = @"Hot Water";
      break;
    default:
      [NSException raise:NSGenericException format:@"Unexpected MODE."];
  }
  return result;
}

/*
 * Handles an error of the mashine
 */
-(CoffeeError)handleError {
  // The order determines the weighting of the error (critical -> not critical)
  // We can not do anything if the device is not connected
  if (![self isConnected]) return (CoffeeError)error_not_connected;
  // If the water is empty, the machine is doing nothing except turn on/off
  if (waterEmpty) return (CoffeeError)error_water_empty;
  // The same if any container is opened
  if (containerOpen) return (CoffeeError)error_container_open;
  // If a task is performed we also can not turn the machine off
  if (waitingForDone) return (CoffeeError)error_waiting_for_done;
  // Some errors need to be resetted after showing error message one time
  if (waterFull) {
    waterFull = false;
    return (CoffeeError)error_water_full;
  }
  if (beansEmpty) {
    beansEmpty = false;
    return (CoffeeError)error_beans_empty;
  }
  if (noCups) {
    noCups = false;
    return (CoffeeError)error_no_cups;
  }
  return (CoffeeError)no_error;
}

/*
 * Water empty is reseted after a maximum of 10 seconds.
 */
-(void)resetWaterEmpty {
  waterEmpty = false;
}

/*
 * Water empty is reseted after a maximum of 10 seconds.
 */
-(void)resetContainerOpen {
  containerOpen = false;
}

/*
 * If the display sent a command to us.
 */
-(void)receivedCommand:(NSString *)theCommand {
  NSLog(@"Received Coffee Command: %@", theCommand);
  // Reset waiting for done, is set back to true if the command is a make command
  waitingForDone = false;
  // Done command
  if ([theCommand isEqualToString:DONE]) {
    waitingForDone = false;
  // Command for empty water
  } else if ([theCommand isEqualToString:ERROR_WATER_EMPTY]) {
    waterEmpty = true;
    // Stop the privious performed reset of waterEmpty
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetWaterEmpty) object:nil];
    [self performSelector:@selector(resetWaterEmpty) withObject:nil afterDelay:12];
  // Command for opened container
  } else if ([theCommand isEqualToString:ERROR_CONTAINER_OPEN]) {
    containerOpen = true;
    // Stop the privious performed reset of container open
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetContainerOpen) object:nil];
    [self performSelector:@selector(resetContainerOpen) withObject:nil afterDelay:12];
  // Command for beans empty
  } else if ([theCommand isEqualToString:ERROR_BEANS_EMPTY]) {
    beansEmpty = true;
  // Command for cups empty
  } else if ([theCommand isEqualToString:ERROR_CUPS_EMPTY]) {
    noCups = true;
  // Command for water full
  } else if ([theCommand isEqualToString:ERROR_WATER_FULL]) {
    waterFull = true;
  // Command for making coffee now
  } else if ([theCommand isEqualToString:COMMAND_COFFEE]) {
    waitingForDone = true;
  // Command for making cappuccino now
  } else if ([theCommand isEqualToString:COMMAND_CAPPUCCINO]) {
    waitingForDone = true;
  // Command for making espresso now
  } else if ([theCommand isEqualToString:COMMAND_ESPRESSO]) {
    waitingForDone = true;
  // Command for making latte now
  } else if ([theCommand isEqualToString:COMMAND_LATTE]) {
    waitingForDone = true;
  // Command for making milk now
  } else if ([theCommand isEqualToString:COMMAND_MILK]) {
    waitingForDone = true;
  // Command for making water now
  } else if ([theCommand isEqualToString:COMMAND_WATER]) {
    waitingForDone = true;
  }
}

/*
 * Returns the discovering command response for discovering coffee machines.
 */
-(NSString *)discoverCommandResponse {
  return DISCOVER_COMMAND_RESPONSE;
}

/*
 * To make the socket free if the device is deleted
 */
- (void) freeSocket {
  // Free the socket again
  if (DEBUG_COFFEE) NSLog(@"Free socket of coffee machine");
  if (!tcpConnectionHandler.socket) return;
  TCPServer *tcpServer = [TCPServer sharedTCPServer];
  [tcpServer freeSocket:tcpConnectionHandler.socket];
}




#pragma mark voice command functions

/*
 * Toggles the device on
 */
- (NSDictionary*)toggleOn {
  return [self respondToCommand:VOICE_COMMAND_ON];
}

/*
 * Toggles the device off
 */
- (NSDictionary*)toggleOff {
  return [self respondToCommand:VOICE_COMMAND_OFF];
}

/*
 * Makes Coffee.
 */
- (NSDictionary*)makeCoffee {
  return [self respondToCommand:VOICE_COMMAND_COFFEE];
}

/*
 * Makes Cappuccino.
 */
- (NSDictionary*)makeCappuccino {
  return [self respondToCommand:VOICE_COMMAND_CAPPUCCINO];
}

/*
 * Makes Espresso.
 */
- (NSDictionary*)makeEspresso {
  return [self respondToCommand:VOICE_COMMAND_ESPRESSO];
}

/*
 * Makes Latte Macchiato.
 */
- (NSDictionary*)makeLatte {
  return [self respondToCommand:VOICE_COMMAND_LATTE];
}

/*
 * Makes hot milk.
 */
- (NSDictionary*)makeMilk {
  return [self respondToCommand:VOICE_COMMAND_MILK];
}

/*
 * Makes hot water.
 */
- (NSDictionary*)makeWater {
  return [self respondToCommand:VOICE_COMMAND_WATER];
}

/*
 * Returns the standard voice commands of the device.
 */
-(NSArray *)standardVoiceCommands {
  VoiceCommand *onCommand = [[VoiceCommand alloc] init];
  [onCommand setName:VOICE_COMMAND_ON];
  [onCommand setCommand:VOICE_COMMAND_ON];
  [onCommand setSelector:@"toggleOn"];
  [onCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_ON, nil]];
  VoiceCommand *offCommand = [[VoiceCommand alloc] init];
  [offCommand setName:VOICE_COMMAND_OFF];
  [offCommand setCommand:VOICE_COMMAND_OFF];
  [offCommand setSelector:@"toggleOff"];
  [offCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_OFF, nil]];
  VoiceCommand *coffeeCommand = [[VoiceCommand alloc] init];
  [coffeeCommand setName:VOICE_COMMAND_COFFEE];
  [coffeeCommand setCommand:VOICE_COMMAND_COFFEE];
  [coffeeCommand setSelector:@"makeCoffee"];
  [coffeeCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_COFFEE, nil]];
  VoiceCommand *cappuccinoCommand = [[VoiceCommand alloc] init];
  [cappuccinoCommand setName:VOICE_COMMAND_CAPPUCCINO];
  [cappuccinoCommand setCommand:VOICE_COMMAND_CAPPUCCINO];
  [cappuccinoCommand setSelector:@"makeCappuccino"];
  [cappuccinoCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_CAPPUCCINO, nil]];
  VoiceCommand *espressoCommand = [[VoiceCommand alloc] init];
  [espressoCommand setName:VOICE_COMMAND_ESPRESSO];
  [espressoCommand setCommand:VOICE_COMMAND_ESPRESSO];
  [espressoCommand setSelector:@"makeEspresso"];
  [espressoCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_ESPRESSO, nil]];
  VoiceCommand *latteCommand = [[VoiceCommand alloc] init];
  [latteCommand setName:VOICE_COMMAND_LATTE];
  [latteCommand setCommand:VOICE_COMMAND_LATTE];
  [latteCommand setSelector:@"makeLatte"];
  [latteCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_LATTE, nil]];
  VoiceCommand *milkCommand = [[VoiceCommand alloc] init];
  [milkCommand setName:VOICE_COMMAND_MILK];
  [milkCommand setCommand:VOICE_COMMAND_MILK];
  [milkCommand setSelector:@"makeMilk"];
  [milkCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_MILK, nil]];
  VoiceCommand *waterCommand = [[VoiceCommand alloc] init];
  [waterCommand setName:VOICE_COMMAND_WATER];
  [waterCommand setCommand:VOICE_COMMAND_WATER];
  [waterCommand setSelector:@"makeWater"];
  [waterCommand setResponses:[NSArray arrayWithObjects:VOICE_RESPONSES_WATER, nil]];
  NSArray *commands = [[NSArray alloc] initWithObjects:onCommand, offCommand, coffeeCommand, cappuccinoCommand,
                       espressoCommand, latteCommand, milkCommand, waterCommand, nil];
  return commands;
}

/*
 * Return the available selectors for voice commands.
 */
-(NSArray *)selectors {
  return [[NSArray alloc] initWithObjects:@"toggleOn", @"toggleOff", @"makeCoffee", @"makeCappuccino",
          @"makeEspresso", @"makeLatte", @"makeMilk", @"makeWater", nil];
}

/*
 * Returns the voice command extensions the device should be sensitive to.
 */
-(NSArray *)readableSelectors {
  return [[NSArray alloc] initWithObjects:@"Turn Coffeemachine on", @"Turn Coffeemachine off", @"Make Coffee",
          @"Make Cappuccino", @"Make Espresso", @"Make Latte Macchiato", @"Make hot milk", @"Make hot water", nil];
}

/*
 * Responses to a recognized voice command.
 */
-(NSDictionary *)respondToCommand:(NSString *)command {
  
  if (![self isConnected]) return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:false],
                                   KeyVoiceCommandExecutedSuccessfully, nil];
  // The spoen response
  NSArray *responses = [[NSArray alloc] init];
  // The error while doing stuff
  CoffeeError theError = no_error;
  // The image that is displayed
  NSImage *image = nil;
  
  // Look what shoudl be done and do it
  if ([command containsString:VOICE_COMMAND_ON]) {
    theError = [self toggleMashine:true];
    if (theError != error_waiting_for_done) theError = no_error;
  } else if ([command containsString:VOICE_COMMAND_OFF]) {
    theError = [self toggleMashine:false];
    if (theError != error_waiting_for_done) theError = no_error;
  } else if ([command containsString:VOICE_COMMAND_COFFEE]) {
    theError = [self makeBeverage:coffeeMashine_coffee:true];
    image = [NSImage imageNamed:VOICE_RESPONSES_COFFEE_IMAGE];
  } else if ([command containsString:VOICE_COMMAND_CAPPUCCINO]) {
    theError = [self makeBeverage:coffeeMashine_cappuccino:true];
    image = [NSImage imageNamed:VOICE_RESPONSES_CAPPUCCINO_IMAGE];
  } else if ([command containsString:VOICE_COMMAND_ESPRESSO]) {
    theError = [self makeBeverage:coffeeMashine_espresso:true];
    image = [NSImage imageNamed:VOICE_RESPONSES_ESPRESSO_IMAGE];
  } else if ([command containsString:VOICE_COMMAND_LATTE]) {
    theError = [self makeBeverage:coffeeMashine_latte:true];
    image = [NSImage imageNamed:VOICE_RESPONSES_LATTE_IMAGE];
  } else if ([command containsString:VOICE_COMMAND_MILK]) {
    theError = [self makeBeverage:coffeeMashine_milk:true];
    image = [NSImage imageNamed:VOICE_RESPONSES_MILK_IMAGE];
  } else if ([command containsString:VOICE_COMMAND_WATER]) {
    theError = [self makeBeverage:coffeeMashine_water:true];
    image = [NSImage imageNamed:VOICE_RESPONSES_WATER_IMAGE];
  }
  
  // Handle errors if exit
  switch (theError) {
    // If no error, just return
    case no_error:
      break;
    // If the machine is not connected, display connection error
    case error_not_connected:
      image = nil;
      responses = [NSArray arrayWithObjects:VOICE_RESPONSES_NOT_CONNECTED, nil];
      break;
    // If the water is empty display water empty
    case error_water_empty:
      image = nil;
      responses = [NSArray arrayWithObjects:VOICE_RESPONSES_NO_WATER, nil];
      break;
    // If the container is open display container open
    case error_container_open:
      image = nil;
      responses = [NSArray arrayWithObjects:VOICE_RESPONSES_CONTAINER, nil];
      break;
    // If we are waiting for a done, display this
    case error_waiting_for_done:
      image = nil;
      responses = [NSArray arrayWithObjects:VOICE_RESPONSES_WAIT, nil];
      break;
    // If beans are empty, attach a warning message to the current response
    case error_beans_empty: {
      NSMutableArray *theResponses = [[NSMutableArray alloc] init];
      NSArray *beans = [NSArray arrayWithObjects:VOICE_RESPONSES_NO_BEANS, nil];
      int beansIndex = arc4random_uniform((int)[beans count]);
      NSString *beansString = [beans objectAtIndex:beansIndex];
      for (int i = 0; i < [responses count]; i++) {
        [theResponses addObject:[NSString stringWithFormat:@"%@ %@", [responses objectAtIndex:i], beansString]];
      }
      responses = [NSArray arrayWithArray:theResponses];
      break;
    }
    // If no cups are left, attach warning message
    case error_no_cups: {
      NSMutableArray *theResponses = [[NSMutableArray alloc] init];
      NSArray *beans = [NSArray arrayWithObjects:VOICE_RESPONSES_NO_CUPS, nil];
      int beansIndex = arc4random_uniform((int)[beans count]);
      NSString *beansString = [beans objectAtIndex:beansIndex];
      for (int i = 0; i < [responses count]; i++) {
        [theResponses addObject:[NSString stringWithFormat:@"%@ %@", [responses objectAtIndex:i], beansString]];
      }
      responses = [NSArray arrayWithArray:theResponses];
      break;
    }
    // If the water reservoir is full, display this
    case error_water_full: {
      NSMutableArray *theResponses = [[NSMutableArray alloc] init];
      NSArray *beans = [NSArray arrayWithObjects:VOICE_RESPONSES_WATER_FULL, nil];
      int beansIndex = arc4random_uniform((int)[beans count]);
      NSString *beansString = [beans objectAtIndex:beansIndex];
      for (int i = 0; i < [responses count]; i++) {
        [theResponses addObject:[NSString stringWithFormat:@"%@ %@", [responses objectAtIndex:i], beansString]];
      }
      responses = [NSArray arrayWithArray:theResponses];
      break;
    }
  }
  // Repsonse dictionary should be a text and a view
  NSMutableDictionary *responseDict = [[NSMutableDictionary alloc] init];
  // Make random response from array
  NSString *response = @"";
  if ([responses count]) {
    int responseIndex = arc4random_uniform((int)[responses count]);
    response = [responses objectAtIndex:responseIndex]; // Repsonse dictionary should be a text and a view
    [responseDict addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:response, KeyVoiceCommandResponseString, nil]];
  }
 
  // If an image should be attached, attach it
  if (image) {
    NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, image.size.width, image.size.height)];
    [imageView setImage:image];
    [responseDict addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:imageView, KeyVoiceCommandResponseView, nil]];
  }
  
  [responseDict addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithBool:[self isConnected]], KeyVoiceCommandExecutedSuccessfully, nil]];
  return responseDict;
}


@end
