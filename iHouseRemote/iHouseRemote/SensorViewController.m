//
//  SensorViewController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 27/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "SensorViewController.h"
#import "Constants.h"

#define DEBUG_SENSOR_VIEW 1

#define HUMIDITY_UNIT_STRING @" \%"
#define TEMPERATURE_UNIT_STRING @" °C"
#define BRIGHTNESS_UNIT_STRING @" lux"
#define PRESSURE_UNIT_STRING @" hPa"
#define MOVEMENT_DETECTED_STRING @"yes"
#define MOVEMENT_NOT_DETECTED_STRING @"no"

@interface SensorViewController ()

@end

@implementation SensorViewController

@synthesize deviceImage, dataLabel;


-(id)initWithDevice:(Device*)theDevice {
  if (self = [super init]) {
    device = theDevice;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:DeviceDidChange object:nil];
  }
  return self;
}

// If the device was dedited, we need to redraw
-(void)reDraw:(NSNotification*)notification {
  if ([device.name isEqualToString:[notification object]]) {
    if (DEBUG_SENSOR_VIEW) NSLog(@"Redraw %@ view", [notification object]);
    [self viewDidLoad];
  }
}


- (void)viewDidLoad {
  [super viewDidLoad];
  
  if (device == nil) device = [[Device alloc] init];
  
  [deviceImage setImage:device.image];
  
  
  NSDictionary *lastValues = device.info;
  
  NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
  [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
  [numberFormatter setDecimalSeparator:@"."];
  [numberFormatter setMaximumFractionDigits:2];
  [numberFormatter setMinimumFractionDigits:0];
  
  NSString *tempLabel = @"";
  NSString *humidityLabel = @"";
  NSString *brightnessLabel = @"";
  NSString *pressureLabel = @"";
  NSString *movementLabel = @"";
  NSString *lastUpdateLabel = @"";
  
  // If data exists, add them to the corresponding label with the Unit at the end
  if ([lastValues objectForKey:SensorKeyTemperature]) {
    tempLabel  = [NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:[lastValues objectForKey:SensorKeyTemperature]], TEMPERATURE_UNIT_STRING];
  }
  if ([lastValues objectForKey:SensorKeyHumidity]) {
    humidityLabel = [NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:[lastValues objectForKey:SensorKeyHumidity]], HUMIDITY_UNIT_STRING];
  }
  if ([lastValues objectForKey:SensorKeyBrightness]) {
    brightnessLabel = [NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:[lastValues objectForKey:SensorKeyBrightness]], BRIGHTNESS_UNIT_STRING];
  }
  if ([lastValues objectForKey:SensorKeyPressure]) {
    pressureLabel = [NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:
                                                              [NSNumber numberWithInteger:[[lastValues objectForKey:SensorKeyPressure] integerValue]/100]],
                                                              PRESSURE_UNIT_STRING];
  }
  // Look if movement was detected
  if ([lastValues objectForKey:SensorKeyMovement]) {
    NSString *movementString = MOVEMENT_DETECTED_STRING;
    if ([[lastValues objectForKey:SensorKeyMovement] intValue] == 0) movementString = MOVEMENT_NOT_DETECTED_STRING;
    movementLabel = movementString;
  }
  // Set the timestamp
  if ([lastValues objectForKey:SensorKeyTimeStamp]) {
    // Get the time of the last update
    NSTimeInterval time = [[lastValues objectForKey:SensorKeyTimeStamp] doubleValue];
    // Restore time from time interval
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    // Format the time nicely
    [format setDateFormat:@"MMM dd, HH:mm:ss"];
    lastUpdateLabel = [NSString stringWithFormat:@"%@", [format stringFromDate:date]];
  }
  
  dataLabel.text = [NSString stringWithFormat:@"Last Update: \t%@\nTemperature: \t\t%@\nHumidity: \t\t%@\nBrightness: \t\t%@\nPressure: \t\t%@\nMovement: \t\t%@",
                         lastUpdateLabel, tempLabel, humidityLabel, brightnessLabel, pressureLabel, movementLabel];

  
}


@end
