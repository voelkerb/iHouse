//
//  EditSensorViewController.m
//  iHouse
//
//  Created by Benjamin Völker on 16/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "EditSensorViewController.h"
#import "TCPServer.h"

#define DEBUG_SENSOR_EDIT_VIEW true

#define HOST_NOT_SET_LABEL @"not chosen yet"
#define ID_NOT_SET_LABEL @"not chosen yet"
#define ALERT_BUTTON_SAVE @"Save"
#define ALERT_BUTTON_OK @"Save"
#define ALERT_BUTTON_CANCEL @"Cancel"
#define ALERT_BUTTON_IDENTIFY @"Identify"
#define ALERT_ID_MESSAGE_HOST @"Select the Sensor Host"
#define ALERT_ID_MESSAGE_HOST_INFORMAL @"Select the sensor host from the list of non bound main sensor nodes."
#define ALERT_ID_MESSAGE_ID @"Select the Sensor ID"
#define ALERT_ID_MESSAGE_ID_INFORMAL @"Select the sensor id from the list of sensors that are connected to the main sensor node."

@interface EditSensorViewController ()

@end

@implementation EditSensorViewController
@synthesize sensor;
@synthesize hostAlertPopup, idAlertPopup, idLabel, hostLabel, saveButton;

- (id)initWithSensor:(Sensor *)theSensor {
  if (self = [super init]) {
    sensor = (Sensor *) theSensor;
  }
  return self;
}


- (void)viewDidLoad {
  [super viewDidLoad];
  // Set the id and host label and indicate if no was set yet
  if (![sensor host] || [[sensor host] isEqualToString:@""]) [hostLabel setStringValue:HOST_NOT_SET_LABEL];
  else [hostLabel setStringValue:[NSString stringWithFormat:@"%@", [sensor host]]];
  if ([sensor sensorID] == 0) [idLabel setStringValue:ID_NOT_SET_LABEL];
  else [idLabel setStringValue:[NSString stringWithFormat:@"%li", [sensor sensorID]]];
}


/*
 * Called if the user wants to change the Host
 */
- (IBAction)changeMainSensorHost:(id)sender {
  // Add an observer to get devices
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newSensorHostDiscovered:)
                                               name:TCPServerNewSocketDiscovered
                                             object:nil];
  
  // Start discovering
  TCPServer *tcpServer = [TCPServer sharedTCPServer];
  [tcpServer discoverSockets:[sensor discoverCommandResponse]];
  // And show the uppopping alert sheet
  [self showEditHostAlert];

}


/*
 * Show an alert where new devices are presented in a popup button.
 */
-(void)showEditHostAlert {
  
  // The accessory view of the alert sheet
  NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 280, 24)];
  // Add the PopUp button to the accessory view of the alert sheet
  hostAlertPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 150, 24)];
  // Init with available main nodes
  SensorHostHandler *sensorHostHandler = [SensorHostHandler sharedSensorHostHandler];
  if ([sensorHostHandler isConnected]) [hostAlertPopup addItemWithTitle:[[[sensorHostHandler tcpConnectionHandler] socket] connectedHost]];

  // Add a spinner as well to indicate that the search process has started
  NSProgressIndicator *spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(160, 3, 18, 18)];
  [spinner setStyle:NSProgressIndicatorSpinningStyle];
  [spinner startAnimation:self];
  NSArray *array = [NSArray arrayWithObjects:hostAlertPopup, spinner, nil];
  [view setSubviews:array];
  
  // Init the alert sheet with buttons, text and accessory view
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:ALERT_ID_MESSAGE_HOST];
  [alert setInformativeText:ALERT_ID_MESSAGE_HOST_INFORMAL];
  [alert addButtonWithTitle:ALERT_BUTTON_SAVE];
  [alert addButtonWithTitle:ALERT_BUTTON_CANCEL];
  [alert setAccessoryView:view];
  
  // Get the save button from the alert sheet and disable it
  NSArray *buttons = [alert buttons];
  for (NSButton *theButton in buttons) {
    if ([theButton.title isEqualToString:ALERT_BUTTON_SAVE]) saveButton = theButton;
  }
  if (![sensorHostHandler isConnected]) [saveButton setEnabled:NO];
  
  long returnCode = [alert runModal];
  // If the user pressed save, the host is stored and the label is updated
  if (returnCode == 1000) {
    // TODO
    //[sensor freeSocket];
    sensor.host = [[hostAlertPopup selectedItem] title];
    [hostLabel setStringValue:[NSString stringWithFormat:@"%@", [sensor host]]];
    // Get the socket for the host
    TCPServer *tcpServer = [TCPServer sharedTCPServer];
    [tcpServer stopDiscovering];
    if (DEBUG_SENSOR_EDIT_VIEW) NSLog(@"took sensor host with host %@", [[tcpServer getSocketWithHost:[sensor host]] connectedHost]);
    [sensor deviceConnected:[tcpServer getSocketWithHost:[sensor host]]];
    
  } // if the user pressed cancel, nothing is done
  
  // Remove the observer for new devices
  [[NSNotificationCenter defaultCenter] removeObserver:self name:TCPServerNewSocketDiscovered object:nil];
}

/*
 * If the user want to change the sensor ID
 */
- (IBAction)changeSensorID:(id)sender {
  // Add the observer for new sensors
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newSensorDiscovered:)
                                               name:SensorHostHasNewSensor
                                             object:nil];
  
  // And show the uppopping alert sheet
  [self showEditIDAlert];
}

/*
 * Show an alert where new devices are presented in a popup button.
 */
-(void)showEditIDAlert {
  SensorHostHandler *sensorHostHandler = [SensorHostHandler sharedSensorHostHandler];
 
  // The accessory view of the alert sheet
  NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 280, 24)];
  // Add the PopUp button to the accessory view of the alert sheet
  idAlertPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 150, 24)];
  // Init with unbound sensor devices that are known yet
  for (NSNumber *theID in [sensorHostHandler unboundSensors]) {
    [idAlertPopup addItemWithTitle:[NSString stringWithFormat:@"%li", [theID integerValue]]];
  }
  
  // Add a spinner as well to indicate that the search process has started
  NSProgressIndicator *spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(160, 3, 18, 18)];
  [spinner setStyle:NSProgressIndicatorSpinningStyle];
  [spinner startAnimation:self];
  NSArray *array = [NSArray arrayWithObjects:idAlertPopup, spinner, nil];
  [view setSubviews:array];
  
  // Init the alert sheet with buttons, text and accessory view
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:ALERT_ID_MESSAGE_ID];
  [alert setInformativeText:ALERT_ID_MESSAGE_ID_INFORMAL];
  [alert addButtonWithTitle:ALERT_BUTTON_SAVE];
  [alert addButtonWithTitle:ALERT_BUTTON_CANCEL];
  [alert setAccessoryView:view];
  
  // Get the save button from the alert sheet and disable it
  NSArray *buttons = [alert buttons];
  for (NSButton *theButton in buttons) {
    if ([theButton.title isEqualToString:ALERT_BUTTON_SAVE]) saveButton = theButton;
  }
  
  if (![[sensorHostHandler unboundSensors] count]) [saveButton setEnabled:NO];
  
  long returnCode = [alert runModal];
  // If the user pressed save, the id is stored and the label is updated
  if (returnCode == 1000) {
    // TODO
    //[sensor freeSocket];
    sensor.sensorID = [[[idAlertPopup selectedItem] title] intValue];
    [[sensorHostHandler unboundSensors] removeAllObjects];
    [idLabel setStringValue:[NSString stringWithFormat:@"%li", [sensor sensorID]]];
    if (DEBUG_SENSOR_EDIT_VIEW) NSLog(@"took sensor with id %li", [sensor sensorID]);
  } // if the user pressed cancel, nothing is done
  
  // Remove the observer for new devices
  [[NSNotificationCenter defaultCenter] removeObserver:self name:SensorHostHasNewSensor object:nil];
}

/*
 * If a new Sensor host was discovered.
 */
-(void)newSensorHostDiscovered:(NSNotification*)notification {
  if (DEBUG_SENSOR_EDIT_VIEW) NSLog(@"newSensorHostDiscovered: %@", [notification object]);
  [hostAlertPopup addItemWithTitle:[notification object]];
  if (![saveButton isEnabled]) [saveButton setEnabled:YES];
}

/*
 * If a new Sensor was discovered. TODO: this is not working atm because perform selector in SensorHostHandler is blocked by runModal.
 */
-(void)newSensorDiscovered:(NSNotification*)notification {
  if (DEBUG_SENSOR_EDIT_VIEW) NSLog(@"newSensorDiscovered: %@", [notification object]);
  [idAlertPopup addItemWithTitle:[notification object]];
  if (![saveButton isEnabled]) [saveButton setEnabled:YES];
}




@end
