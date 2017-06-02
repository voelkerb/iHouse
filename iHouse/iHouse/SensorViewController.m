//
//  SensorViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 16/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "SensorViewController.h"
#import "IDevice.h"

#define HUMIDITY_UNIT_STRING @" \%"
#define TEMPERATURE_UNIT_STRING @" °C"
#define BRIGHTNESS_UNIT_STRING @" lux"
#define PRESSURE_UNIT_STRING @" hPa"
#define MOVEMENT_DETECTED_STRING @"yes"
#define MOVEMENT_NOT_DETECTED_STRING @"no"


#define POPUP_TITLE_HUMIDITY @"Humidity"
#define POPUP_TITLE_TEMPERATURE @"Temperature"
#define POPUP_TITLE_BRIGHTNESS @"Brightness"
#define POPUP_TITLE_PRESSURE @"Pressure"
#define POPUP_TITLE_MOVEMENT @"Movement"


#define ALERT_BUTTON_OK @"Ok"
#define ALERT_NO_CONNECTION_MESSAGE @"Receiver not connected"
#define ALERT_NO_CONNECTION_MESSAGE_INFORMAL @"Connect an iHouse sensor receiver to enable this feature."

@interface SensorViewController ()

@end

@implementation SensorViewController
@synthesize iDevice, sensorImage, sensorName, backView;
@synthesize idLabel, tempLabel, lastUpdateLabel, humidityLabel, pressureLabel, brightnessLabel, movementLabel;
@synthesize plotSideView, frontView, plotView, plotViewController;
@synthesize valuePopUp, timePopUp, backView2;

/*
 * For copying this view
 */
-(id)copyWithZone:(NSZone *)zone {
  SensorViewController *copy = [[SensorViewController allocWithZone: zone] initWithDevice:iDevice];
  return copy;
}

- (id)initWithDevice:(IDevice *)theSensorDevice {
  self = [super init];
  if (self && (theSensorDevice.type == sensor)) {
    // Get the pointer of the device
    iDevice = theSensorDevice;
    // Add observer for device edit change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reDraw:) name:iDeviceDidChange object:nil];
  }
  return self;
}

// If the device was dedited, we need to redraw
-(void)reDraw:(NSNotification*)notification {
  if ([iDevice isEqualTo:[notification object]]) [self viewDidLayout];
}

- (void)viewDidLayout {
  // Add the frontView to the view
  //[self.view addSubview:frontView];
  [frontView setFrame:self.view.frame];
  
  // Set the name
  [sensorName setStringValue:[iDevice name]];
  
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
  [super viewDidLoad];
  // Remove all items in the popups
  [valuePopUp removeAllItems];
  [timePopUp removeAllItems];
  // Init the time popup with all available times
  for (SensorTimeInterval time = sensor_month; time <= sensor_minute; time++) {
    [timePopUp addItemWithTitle:[(Sensor*)[iDevice theDevice] timeIntervalToString:time]];
  }
  // Select minute as default time
  [timePopUp selectItemWithTitle:[(Meter*)[iDevice theDevice] timeIntervalToString:meter_minute]];
  // Set all available values for the value popup
  [valuePopUp addItemWithTitle:POPUP_TITLE_HUMIDITY];
  [valuePopUp addItemWithTitle:POPUP_TITLE_TEMPERATURE];
  [valuePopUp addItemWithTitle:POPUP_TITLE_BRIGHTNESS];
  [valuePopUp addItemWithTitle:POPUP_TITLE_PRESSURE];
  [valuePopUp addItemWithTitle:POPUP_TITLE_MOVEMENT];
  // Select Temperature as default value
  [valuePopUp selectItemWithTitle:POPUP_TITLE_TEMPERATURE];
  
  
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
  [sensorName setStringValue:[iDevice name]];
  [sensorImage setImage:[iDevice image]];
  [sensorImage setAllowDrag:false];
  [sensorImage setAllowDrop:false];
  
  // Set the background color accordingly
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:[[iDevice color] CGColor]];
  [backView setWantsLayer:YES];
  [backView setLayer:viewLayer];
  
  // Add an observer to update the data of the meter if new data is available
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newSensorData:)
                                               name:SensorHasNewData
                                             object:nil];
  // Set the id label
  [idLabel setStringValue:[NSString stringWithFormat:@"%li", [(Sensor*)[iDevice theDevice] sensorID]]];
  
  // Set last Data
  [self newSensorData:[NSNotification notificationWithName:SensorHasNewData object:(Sensor*)[iDevice theDevice]]];
  
  
  // Init the plotviewController and add its view
  plotViewController = [[PlotViewController alloc] init];
  [plotViewController.view setFrame:plotView.frame];
  [plotView addSubview:plotViewController.view];
}


- (void)newSensorData:(NSNotification*)notification {
  if (![[notification object] isEqualTo:(Sensor*)[iDevice theDevice]]) return;
  // Make the number readable
  NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
  [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
  [numberFormatter setDecimalSeparator:@"."];
  [numberFormatter setMaximumFractionDigits:2];
  [numberFormatter setMinimumFractionDigits:0];
  
  // Get the last stored data of the meter
  NSDictionary *lastValues = [[(Sensor*)[iDevice theDevice] storedDataHourMinute] lastObject];
  // If data exists, add them to the corresponding label with the Unit at the end
  if ([lastValues objectForKey:SensorKeyTemperature]) {
    [tempLabel setStringValue:[NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:[lastValues objectForKey:SensorKeyTemperature]], TEMPERATURE_UNIT_STRING]];
  }
  if ([lastValues objectForKey:SensorKeyHumidity]) {
    [humidityLabel setStringValue:[NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:[lastValues objectForKey:SensorKeyHumidity]], HUMIDITY_UNIT_STRING]];
  }
  if ([lastValues objectForKey:SensorKeyBrightness]) {
    [brightnessLabel setStringValue:[NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:[lastValues objectForKey:SensorKeyBrightness]], BRIGHTNESS_UNIT_STRING]];
  }
  if ([lastValues objectForKey:SensorKeyPressure]) {
    [pressureLabel setStringValue:[NSString stringWithFormat:@"%@%@", [numberFormatter stringFromNumber:
                                                                       [NSNumber numberWithInteger:[[lastValues objectForKey:SensorKeyPressure] integerValue]/100]],
                                                                        PRESSURE_UNIT_STRING]];
  }
  // Look if movement was detected
  if ([lastValues objectForKey:SensorKeyMovement]) {
    NSString *movementString = MOVEMENT_DETECTED_STRING;
    if ([[lastValues objectForKey:SensorKeyMovement] intValue] == 0) movementString = MOVEMENT_NOT_DETECTED_STRING;
    [movementLabel setStringValue:movementString];
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
    [lastUpdateLabel setStringValue:[NSString stringWithFormat:@"%@", [format stringFromDate:date]]];
  }
}


/*
 * Checks if the Sensor is connected over tcp.
 */
- (BOOL)checkConnected {
  if ([(Sensor*)[iDevice theDevice] isConnected]) return true;
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
  for (SensorTimeInterval time = sensor_month; time <= sensor_minute; time++) {
    if ([[[timePopUp selectedItem] title] isEqualToString:[(Sensor*)[iDevice theDevice] timeIntervalToString:time]]) {
      NSLog(@"Choosed: %@ in time: %@", [[valuePopUp selectedItem] title], [(Sensor*)[iDevice theDevice] timeIntervalToString:time]);
      
      NSArray *yData;
      NSString *name = @"";
      
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateFormat:@"HH:mm"];
      NSTimeInterval timeInterval = [(Sensor*)[iDevice theDevice] getTimeIntervalForPlot:time];
      
      if ([[[valuePopUp selectedItem] title] isEqualToString: POPUP_TITLE_HUMIDITY]) {
        yData = [(Sensor*)[iDevice theDevice] getData:time :SensorKeyHumidity];
        name = POPUP_TITLE_HUMIDITY;
      } else if ([[[valuePopUp selectedItem] title] isEqualToString: POPUP_TITLE_TEMPERATURE]) {
        yData = [(Sensor*)[iDevice theDevice] getData:time :SensorKeyTemperature];
        name = POPUP_TITLE_TEMPERATURE;
      } else if ([[[valuePopUp selectedItem] title] isEqualToString: POPUP_TITLE_BRIGHTNESS]) {
        yData = [(Sensor*)[iDevice theDevice] getData:time :SensorKeyBrightness];
        name = POPUP_TITLE_BRIGHTNESS;
      } else if ([[[valuePopUp selectedItem] title] isEqualToString: POPUP_TITLE_PRESSURE]) {
        yData = [(Sensor*)[iDevice theDevice] getData:time :SensorKeyPressure];
        name = POPUP_TITLE_PRESSURE;
      } else {
        yData = [(Sensor*)[iDevice theDevice] getData:time :SensorKeyMovement];
        name = POPUP_TITLE_MOVEMENT;
      }
      [plotViewController.view removeFromSuperview];
      plotViewController = [[PlotViewController alloc] init];
      
      [plotViewController.view setFrame:plotView.frame];
      [plotView addSubview:plotViewController.view];
      
      [plotViewController removeAllPlots];
      if (![yData count]) {
        NSLog(@"No data sorry");
        [plotViewController loadPlotNamed:name
                             withTimeData:[[NSArray alloc] initWithObjects:[NSNumber numberWithInteger:0], nil]
                                    yData:[[NSArray alloc] initWithObjects:[NSNumber numberWithInteger:0],
                                           [NSNumber numberWithInteger:1], nil]
                                lineColor:[NSColor redColor]
                             timeInterval:timeInterval];
      } else {
        [plotViewController loadPlotNamed:name
                             withTimeData:[(Sensor*)[iDevice theDevice] getTimeData:time]
                                    yData:yData
                                lineColor:[NSColor redColor]
                             timeInterval:timeInterval];
      }
      
    }
  }
}

@end