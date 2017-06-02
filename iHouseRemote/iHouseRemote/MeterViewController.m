//
//  MeterViewController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 27/02/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import "MeterViewController.h"
#import "Constants.h"
#define DEBUG_METER_VIEW 1
#define VOLTAGE_UNIT_STRING @" V"
#define CURRENT_UNIT_STRING @" mA"
#define POWER_UNIT_STRING @" W"
#define ENERGY_UNIT_STRING @" kWh"

@interface MeterViewController ()

@end

@implementation MeterViewController
@synthesize deviceImage, meterDataLabel;

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
    if (DEBUG_METER_VIEW) NSLog(@"Redraw %@ view", [notification object]);
    [self viewDidLoad];
  }
}


- (void)viewDidLoad {
  [super viewDidLoad];
  
  if (device == nil) device = [[Device alloc] init];
  
  [deviceImage setImage:device.image];
  
  NSDictionary *deviceInfo = device.info;
  
  NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
  [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
  [numberFormatter setDecimalSeparator:@"."];
  [numberFormatter setMaximumFractionDigits:2];
  [numberFormatter setMinimumFractionDigits:0];
  
  NSString *voltageLabel = @"";
  NSString *currentLabel = @"";
  NSString *powerLabel = @"";
  NSString *energyLabel = @"";
  NSString *lastUpdateLabel = @"";
  if ([deviceInfo objectForKey:MeterKeyVoltage]) {
    voltageLabel = [NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:[deviceInfo objectForKey:MeterKeyVoltage]], VOLTAGE_UNIT_STRING];
  }
  if ([deviceInfo objectForKey:MeterKeyCurrent]) {
    currentLabel = [NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:[deviceInfo objectForKey:MeterKeyCurrent]], CURRENT_UNIT_STRING];
  }
  if ([deviceInfo objectForKey:MeterKeyPower]) {
    powerLabel = [NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:[deviceInfo objectForKey:MeterKeyPower]], POWER_UNIT_STRING];
  }
  if ([deviceInfo objectForKey:MeterKeyEnergy]) {
    energyLabel = [NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:[deviceInfo objectForKey:MeterKeyEnergy]], ENERGY_UNIT_STRING];
  }
  if ([deviceInfo objectForKey:MeterKeyTimeStamp]) {
    // Get the time of the last update
    NSTimeInterval time = [[deviceInfo objectForKey:MeterKeyTimeStamp] doubleValue];
    // Restore time from time interval
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    // Format the time nicely
    [format setDateFormat:@"MMM dd, HH:mm:ss"];
    
    lastUpdateLabel = [NSString stringWithFormat:@"%@", [format stringFromDate:date]];
  }
  
  meterDataLabel.text = [NSString stringWithFormat:@"Last Update: \t%@\nVoltage: \t\t%@\nCurrent: \t\t%@\nPower: \t\t%@\nEnergy: \t\t%@",
                         lastUpdateLabel, voltageLabel, currentLabel, powerLabel, energyLabel];
}


@end
