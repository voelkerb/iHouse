//
//  MeterViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 24/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "MeterViewController.h"
#import "IDevice.h"

#define DEBUG_METER_VIEW_CON false

#define POPUP_TITLE_VOLTAGE @"Voltage"
#define POPUP_TITLE_CURRRENT @"Current"
#define POPUP_TITLE_POWER @"Power"

#define VOLTAGE_UNIT_STRING @" V"
#define CURRENT_UNIT_STRING @" mA"
#define POWER_UNIT_STRING @" W"
#define ENERGY_UNIT_STRING @" kWh"

#define AVG_OVER_SECONDS 60*10 //10minutes

#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NO_CONNECTION_MESSAGE @"Receiver not connected"
#define ALERT_NO_CONNECTION_MESSAGE_INFORMAL @"Connect an iHouse energy receiver over USB to enable this feature."

@interface MeterViewController ()

@end

@implementation MeterViewController
@synthesize plotViewController;
@synthesize meterImage, meterName, iDevice, backView;
@synthesize lastUpdateLabel, idLabel, voltageLabel, currentLabel, powerLabel, energyLabel, avgPowerLabel;
@synthesize plotSideView, frontView, plotView;
@synthesize valuePopUp, timePopUp, backView2;

/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  MeterViewController *copy = [[MeterViewController allocWithZone: zone] initWithDevice:iDevice];
  
  copy.plotViewController = plotViewController;
  copy.backView = backView;
  copy.plotSideView = plotSideView;
  copy.frontView = frontView;
  copy.plotView = plotView;
  copy.valuePopUp = valuePopUp;
  copy.timePopUp = timePopUp;
  copy.backView2 = backView2;
  return copy;
}

- (id)initWithDevice:(IDevice *)theMeterDevice {
  self = [super init];
  if (self && (theMeterDevice.type == meter)) {
    // Get the pointer of the device
    iDevice = theMeterDevice;
    // Add observer for device edit change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:iDeviceDidChange object:nil];
  }
  return self;
}

// If the device was dedited, we need to redraw
-(void)reDraw:(NSNotification*)notification {
  if ([iDevice isEqualTo:[notification object]]) {
    [self viewDidLayout];
  }
}

- (void)viewDidLayout {
  // Add the frontView to the view
  //[self.view addSubview:frontView];
  [frontView setFrame:self.view.frame];
  
  // Set the name of the device
  [meterName setStringValue:[iDevice name]];
  
  // Set frame of the plotside view
  [plotSideView setFrame:self.view.frame];
  //[frontView setBounds:self.view.bounds];
  //[plotSideView setBounds:self.view.bounds];/
  // Workaround for flipper view
  CGPoint org = {0.5,0.5};
  fliper.origin = org;
  fliper.prespect = 280;
  
  // Workaround for clearcolor bug
  // Clearcolor will not display nicely in the plot
  CALayer *viewLayer = [CALayer layer];
  CALayer *viewLayer2 = [CALayer layer];
  if ([[iDevice color] isEqualTo:[NSColor clearColor]]) {
    [viewLayer setBackgroundColor:[[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.05] CGColor]];
    [viewLayer2 setBackgroundColor:[[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.05] CGColor]];
  } else {
    [viewLayer2 setBackgroundColor:[[iDevice color] CGColor]];
  }
  // Set the background color accordingly
  [backView setWantsLayer:YES];
  [backView setLayer:viewLayer];
  // Set the background color of the second side accordingly
  [backView2 setWantsLayer:YES];
  [backView2 setLayer:viewLayer2];
}

- (void)viewDidLoad {
  // Remove all items in the popups
  [valuePopUp removeAllItems];
  [timePopUp removeAllItems];
  // Init the time popup with all available times
  for (MeterTimeInterval time = meter_month; time <= meter_minute; time++) {
    [timePopUp addItemWithTitle:[(Meter*)[iDevice theDevice] timeIntervalToString:time]];
  }
  // Select minute as default time
  [timePopUp selectItemWithTitle:[(Meter*)[iDevice theDevice] timeIntervalToString:meter_minute]];
  // Set all available values for the value popup
  [valuePopUp addItemWithTitle:POPUP_TITLE_VOLTAGE];
  [valuePopUp addItemWithTitle:POPUP_TITLE_CURRRENT];
  [valuePopUp addItemWithTitle:POPUP_TITLE_POWER];
  // Select Power as default value
  [valuePopUp selectItemWithTitle:POPUP_TITLE_POWER];
  
  // Init the fliper view
  fliper = [[mbFliperViews alloc] init];
  // Add both sides to the view
  [fliper addView:frontView];
  [fliper addView:plotSideView];
  // Our view is the superview of the fliper
  fliper.superView = self.view;
  // Activate the first side
  [fliper setActiveViewAtIndex:0];
  // Set defaut flip time
  fliper.time = 0.5;
  
  // Set name and image of the device
  [meterName setStringValue:[iDevice name]];
  [meterImage setImage:[iDevice image]];
  
  // Add an observer to update the data of the meter if new data is available
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newMeterData:)
                                               name:MeterHasNewData
                                             object:nil];
  // Set the id label
  [idLabel setStringValue:[NSString stringWithFormat:@"%li", [(Meter*)[iDevice theDevice] meterID]]];
  
  
  // Set last Data
  [self newMeterData:nil];
  
  // Init the plotviewController and add its view
  plotViewController = [[PlotViewController alloc] init];
  [plotViewController.view setFrame:plotView.frame];
  [plotView addSubview:plotViewController.view];
  
  [super viewDidLoad];
}


- (void)newMeterData:(NSNotification*)notification {
  // Make the number readable
  NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
  [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
  [numberFormatter setDecimalSeparator:@"."];
  [numberFormatter setMaximumFractionDigits:2];
  [numberFormatter setMinimumFractionDigits:0];
  
  // Get the last stored data of the meter
  NSDictionary *lastValues = [[(Meter*)[iDevice theDevice] storedDataHourMinute] lastObject];
  // If data exists, add them to the corresponding label with the Unit at the end
  if ([lastValues objectForKey:MeterKeyVoltage]) {
    [voltageLabel setStringValue:[NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:[lastValues objectForKey:MeterKeyVoltage]], VOLTAGE_UNIT_STRING]];
  }
  if ([lastValues objectForKey:MeterKeyCurrent]) {
    [currentLabel setStringValue:[NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:[lastValues objectForKey:MeterKeyCurrent]], CURRENT_UNIT_STRING]];
  }
  if ([lastValues objectForKey:MeterKeyPower]) {
    [powerLabel setStringValue:[NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:[lastValues objectForKey:MeterKeyPower]], POWER_UNIT_STRING]];
  }
  if ([lastValues objectForKey:MeterKeyEnergy]) {
    [energyLabel setStringValue:[NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:[lastValues objectForKey:MeterKeyEnergy]], ENERGY_UNIT_STRING]];
  }
  if ([lastValues objectForKey:MeterKeyTimeStamp]) {
    // Get the time of the last update
    NSTimeInterval time = [[lastValues objectForKey:MeterKeyTimeStamp] doubleValue];
    // Restore time from time interval
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    // Format the time nicely
    [format setDateFormat:@"MMM dd, HH:mm:ss"];

    [lastUpdateLabel setStringValue:[NSString stringWithFormat:@"%@", [format stringFromDate:date]]];
    
    float avgPower = 0;
    int i = 0;
    for (NSDictionary *dict in [(Meter*)[iDevice theDevice] storedDataHourMinute]) {
      //NSLog(@"time = %.2f", (time - [[dict objectForKey:MeterKeyTimeStamp] doubleValue]));
      if ((time - [[dict objectForKey:MeterKeyTimeStamp] doubleValue]) < AVG_OVER_SECONDS) {
        avgPower += [[dict objectForKey:MeterKeyPower] floatValue];
        i++;
      }
    }
    avgPower /= i;
    if (DEBUG_METER_VIEW_CON) NSLog(@"Avg Power = %.2f over %i", avgPower, i);
    [avgPowerLabel setStringValue:[NSString stringWithFormat:@"%.2f%@", avgPower, POWER_UNIT_STRING]];
  }
  
}


/*
 * Checks if the Meter device is connected over USB.
 */
- (BOOL)checkConnected {
  if ([(Meter*)[iDevice theDevice] isConnected]) return true;
  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:ALERT_BUTTON_OK];
  [alert setMessageText:ALERT_NO_CONNECTION_MESSAGE];
  [alert setInformativeText:ALERT_NO_CONNECTION_MESSAGE_INFORMAL];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
  return false;
}




/*
 * Flips the view from front (Labels) to back (plot).
 */
- (IBAction)flipView:(id)sender {
  [fliper flipLeft:self];
  [self redrawPlot];
}

/*
 * Flips the view from back (plot) to front (labels).
 */
- (IBAction)flipBack:(id)sender {
  [fliper flipRight:self];
}

/*
 * The user changed the value popup.
 */
- (IBAction)valuePopupChanged:(id)sender {
  [self redrawPlot];
}

/*
 * The user changed the time popup.
 */
- (IBAction)timePopupChanged:(id)sender {
  [self redrawPlot];
}

/*
 * Redraws the complete plot.
 */
-(void)redrawPlot {
  for (MeterTimeInterval time = meter_month; time <= meter_minute; time++) {
    if ([[[timePopUp selectedItem] title] isEqualToString:[(Meter*)[iDevice theDevice] timeIntervalToString:time]]) {
      if (DEBUG_METER_VIEW_CON) NSLog(@"Choosed: %@ in time: %@", [[valuePopUp selectedItem] title], [(Meter*)[iDevice theDevice] timeIntervalToString:time]);
      
      NSArray *yData;
      NSString *name = @"";
      
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateFormat:@"HH:mm"];
      NSTimeInterval timeInterval = [(Meter*)[iDevice theDevice] getTimeIntervalForPlot:time];
      
      if ([[[valuePopUp selectedItem] title] isEqualToString: POPUP_TITLE_VOLTAGE]) {
        yData = [(Meter*)[iDevice theDevice] getData:time :MeterKeyVoltage];
        name = POPUP_TITLE_VOLTAGE;
      } else if ([[[valuePopUp selectedItem] title] isEqualToString: POPUP_TITLE_CURRRENT]) {
        yData = [(Meter*)[iDevice theDevice] getData:time :MeterKeyCurrent];
        name = POPUP_TITLE_CURRRENT;
      } else {
        yData = [(Meter*)[iDevice theDevice] getData:time :MeterKeyPower];
        name = POPUP_TITLE_POWER;
      }
      [plotViewController.view removeFromSuperview];
      plotViewController = [[PlotViewController alloc] init];
      
      [plotViewController.view setFrame:plotView.frame];
      [plotView addSubview:plotViewController.view];
      
      [plotViewController removeAllPlots];
      [plotViewController loadPlotNamed:name
                           withTimeData:[(Meter*)[iDevice theDevice] getTimeData:time]
                                  yData:yData
                              lineColor:[NSColor redColor]
                           timeInterval:timeInterval];
      
    }
  }
}

@end
