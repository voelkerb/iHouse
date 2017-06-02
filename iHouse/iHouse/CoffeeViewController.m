//
//  CoffeeViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "CoffeeViewController.h"
#import "IDevice.h"

#define DEBUG_COFFE_VIEW true

#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NO_WATER_MESSAGE @"No Water"
#define ALERT_NO_WATER_MESSAGE_INFORMAL @"You need to refill the water tank."
#define ALERT_NO_BEANS_MESSAGE @"No Beans"
#define ALERT_NO_BEANS_MESSAGE_INFORMAL @"You need to refill the Beans."
#define ALERT_NO_CUPS_MESSAGE @"No Cups"
#define ALERT_NO_CUPS_MESSAGE_INFORMAL @"You need to refill the Cups."
#define ALERT_WATER_FULL_MESSAGE @"Water full"
#define ALERT_WATER_FULL_MESSAGE_INFORMAL @"You need to empty the water."
#define ALERT_CONTAINER_OPEN_MESSAGE @"Container open"
#define ALERT_CONTAINER_OPEN_MESSAGE_INFORMAL @"You need to close the container first."
#define ALERT_WAITING_FOR_DONE_MESSAGE @"Previous Task"
#define ALERT_WAITING_FOR_DONE_MESSAGE_INFORMAL @"The mashine needs to finish the current task first."
#define ALERT_NO_CONNECTION_MESSAGE @" CoffeeMashine not connected"
#define ALERT_NO_CONNECTION_MESSAGE_INFORMAL1 @"Connect the "
#define ALERT_NO_CONNECTION_MESSAGE_INFORMAL2 @" CoffeeMashine over Wifi to enable this feature."
#define STATUS_FINE @"Ready"

@interface CoffeeViewController ()

@end

@implementation CoffeeViewController
@synthesize iDevice;
@synthesize coffeeImage, nameLabel, backView;
@synthesize beveragePopUp, statusMsgLabel, aromaSlider, brightnessSlider, withCupCheckBox;

/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  CoffeeViewController *copy = [[CoffeeViewController allocWithZone: zone] initWithDevice:iDevice];
  
  copy.statusMsgLabel = statusMsgLabel;
  copy.brightnessSlider = brightnessSlider;
  copy.aromaSlider = aromaSlider;
  copy.withCupCheckBox = withCupCheckBox;
  copy.beveragePopUp = beveragePopUp;
  return copy;
}

- (id)initWithDevice:(IDevice *)theCoffeeDevice {
  self = [super init];
  if (self && (theCoffeeDevice.type == coffee)) {
    // Get the pointer of the device
    iDevice = theCoffeeDevice;
    // Add observer for device edit change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:iDeviceDidChange object:nil];
  }
  return self;
}

// If the device was dedited, we need to redraw
-(void)reDraw:(NSNotification*)notification {
  if ([iDevice isEqualTo:[notification object]]) {
    [self viewDidLoad];
  }
}


- (void)viewDidLoad {
  [super viewDidLoad];
  // Do view setup here.
  // Set name and image of the device
  [nameLabel setStringValue:[iDevice name]];
  [coffeeImage setImage:[iDevice image]];
  
  // Set the background color accordingly
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[[iDevice color] CGColor]];
  [backView setWantsLayer:YES];
  [backView setLayer:viewLayer];
  
  // Init the beverage popup button with the available beverages
  [beveragePopUp removeAllItems];
  for (int i = 0; i < coffeeMashine_numberOfBeverages; i++) {
    [beveragePopUp addItemWithTitle:[(Coffee*)[iDevice theDevice] coffeeBeverageToString:i]];
    [[beveragePopUp itemWithTitle:[(Coffee*)[iDevice theDevice] coffeeBeverageToString:i]] setTag:i];
  }
  
  // Init the sliders
  [aromaSlider setMinValue:0];
  [brightnessSlider setMinValue:0];
  [aromaSlider setMaxValue:AROMA_MAX];
  [aromaSlider setNumberOfTickMarks:AROMA_MAX+1];
  [aromaSlider setAllowsTickMarkValuesOnly:YES];
  [aromaSlider setContinuous:NO];
  [aromaSlider setIntegerValue:[(Coffee*)[iDevice theDevice] aroma]];
  [brightnessSlider setMinValue:0];
  [brightnessSlider setMaxValue:BRIGHTNESS_MAX];
  [brightnessSlider setNumberOfTickMarks:BRIGHTNESS_MAX+1];
  [brightnessSlider setAllowsTickMarkValuesOnly:YES];
  [brightnessSlider setContinuous:NO];
  [brightnessSlider setIntegerValue:[(Coffee*)[iDevice theDevice] brightness]];
  
  // Init the status msg
  [statusMsgLabel setStringValue:STATUS_FINE];
}


/*
 * Makes the currently set beverage.
 */
- (IBAction)makeBeverage:(id)sender {
  CoffeeBeverage baverage = [[beveragePopUp selectedItem] tag];
  if (DEBUG_COFFE_VIEW) NSLog(@"Make a sweet %@ now", [(Coffee*)[iDevice theDevice] coffeeBeverageToString:baverage]);
  if ([self checkConnected]) {
    CoffeeError theError = [(Coffee*)[iDevice theDevice] makeBeverage:baverage:[withCupCheckBox state]];
    [self handleError:theError];

  }
}

/*
 * Changes the aroma to the slider value.
 */
- (IBAction)changeAroma:(id)sender {
  if (DEBUG_COFFE_VIEW) NSLog(@"Change aroma to: %li", [aromaSlider integerValue]);
  if ([self checkConnected]) {
    CoffeeError theError = [(Coffee*)[iDevice theDevice] setTheAroma:[aromaSlider integerValue]];
    [self handleError:theError];
  }
  [aromaSlider setIntegerValue:[(Coffee*)[iDevice theDevice] aroma]];
}

/*
 * Changes the brightness to the given value.
 */
- (IBAction)changeBrightness:(id)sender {
  if (DEBUG_COFFE_VIEW) NSLog(@"Change brightness to: %li", [brightnessSlider integerValue]);
  if ([self checkConnected]) {
    CoffeeError theError = [(Coffee*)[iDevice theDevice] setTheBrightness:[brightnessSlider integerValue]];
    [self handleError:theError];
  }
  [brightnessSlider setIntegerValue:[(Coffee*)[iDevice theDevice] brightness]];
}

/*
 * Makes a factory reset of the mashine.
 */
- (IBAction)factoryReset:(id)sender {
  if (DEBUG_COFFE_VIEW) NSLog(@"Factory Reset");
  if ([self checkConnected]) {
    CoffeeError theError = [(Coffee*)[iDevice theDevice] factoryReset];
    [self handleError:theError];
  }
}

/*
 * Toggles the machine on or off.
 */
- (IBAction)toggleMachineOnOff:(id)sender {
  if ([self checkConnected]) {
    CoffeeError theError = [(Coffee*)[iDevice theDevice] toggleMashine:true];
    [self handleError:theError];
  }
}

/*
 * Checks if the Coffe Mashine is connected over tcp.
 */
- (BOOL)checkConnected {
  if ([(Coffee*)[iDevice theDevice] isConnected]) return true;
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:ALERT_BUTTON_OK];
  [alert setMessageText:[NSString stringWithFormat:@"%@%@", [iDevice name], ALERT_NO_CONNECTION_MESSAGE]];
  [alert setInformativeText:[NSString stringWithFormat:@"%@%@%@", ALERT_NO_CONNECTION_MESSAGE_INFORMAL1,
                             [iDevice name], ALERT_NO_CONNECTION_MESSAGE_INFORMAL2]];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
  return false;
}

/*
 * Handle the error that comes from the mashine.
 */
- (void)handleError:(CoffeeError)theError {
  if (theError == no_error) {
    [statusMsgLabel setStringValue:STATUS_FINE];
    return;
  }
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:ALERT_BUTTON_OK];
  switch (theError) {
    case error_water_empty: {
      [statusMsgLabel setStringValue:ALERT_NO_WATER_MESSAGE];
      [alert setMessageText:ALERT_NO_WATER_MESSAGE];
      [alert setInformativeText:ALERT_NO_WATER_MESSAGE_INFORMAL];
      break;
    }
    case error_water_full: {
      [statusMsgLabel setStringValue:ALERT_WATER_FULL_MESSAGE];
      [alert setMessageText:ALERT_WATER_FULL_MESSAGE];
      [alert setInformativeText:ALERT_WATER_FULL_MESSAGE_INFORMAL];
      break;
    }
    case error_container_open: {
      [statusMsgLabel setStringValue:ALERT_CONTAINER_OPEN_MESSAGE];
      [alert setMessageText:ALERT_CONTAINER_OPEN_MESSAGE];
      [alert setInformativeText:ALERT_CONTAINER_OPEN_MESSAGE_INFORMAL];
      break;
    }
    case error_waiting_for_done: {
      [statusMsgLabel setStringValue:ALERT_WAITING_FOR_DONE_MESSAGE];
      [alert setMessageText:ALERT_WAITING_FOR_DONE_MESSAGE];
      [alert setInformativeText:ALERT_WAITING_FOR_DONE_MESSAGE_INFORMAL];
      break;
    }
    case error_beans_empty: {
      [statusMsgLabel setStringValue:ALERT_NO_BEANS_MESSAGE];
      [alert setMessageText:ALERT_NO_BEANS_MESSAGE];
      [alert setInformativeText:ALERT_NO_BEANS_MESSAGE_INFORMAL];
      break;
    }
    case error_no_cups: {
      [statusMsgLabel setStringValue:ALERT_NO_CUPS_MESSAGE];
      [alert setMessageText:ALERT_NO_CUPS_MESSAGE];
      [alert setInformativeText:ALERT_NO_CUPS_MESSAGE_INFORMAL];
      break;
    }
      
    default:
      [alert setMessageText:@"Ups"];
      [alert setInformativeText:@"Something went wrong"];
      break;
  }
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
}

@end
