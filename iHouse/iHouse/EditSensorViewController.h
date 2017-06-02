//
//  EditSensorViewController.h
//  iHouse
//
//  Created by Benjamin Völker on 16/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Sensor.h"

@interface EditSensorViewController : NSViewController

@property (strong) Sensor *sensor;

// The label displaying the id of the sensor
@property (weak) IBOutlet NSTextField *idLabel;
// The label displaying the host of the main sensor node
@property (weak) IBOutlet NSTextField *hostLabel;
// A popup button which is displayed in a alert window
@property (strong) NSPopUpButton *idAlertPopup;
// A popup button which is displayed in a alert window
@property (strong) NSPopUpButton *hostAlertPopup;
// The save button of the alert window (must be disabled if nothing selected)
@property (strong) NSButton *saveButton;


- (id) initWithSensor:(Sensor*) theSensor;


// If the user wants to change the sensorID or the main sensor host
- (IBAction)changeMainSensorHost:(id)sender;
- (IBAction)changeSensorID:(id)sender;

@end
