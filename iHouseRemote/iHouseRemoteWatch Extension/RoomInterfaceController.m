//
//  RoomInterfaceController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 04/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "RoomInterfaceController.h"
#import "DeviceRow.h"
#import "Constants.h"

@interface RoomInterfaceController ()

@end

@implementation RoomInterfaceController
@synthesize devicesTable, room;

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  self.room = context;
  [self setTitle:self.room.name];
  NSLog(@"From Watch Devices: %@", [room deviceList]);
  [self configureTable];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureTable) name:NCNewDeviceImage object:nil];
}

- (void)configureTable {
  NSLog(@"config room table");
  [devicesTable setNumberOfRows:[[room deviceList] count] withRowType:@"deviceRowType"];
  

  for (NSInteger i = 0; i < self.devicesTable.numberOfRows; i++) {
    DeviceRow* theRow = [self.devicesTable rowControllerAtIndex:i];
    Device* deviceObj = [[room deviceList] objectAtIndex:i];
    
    [theRow.deviceName setText:deviceObj.name];
    [theRow.deviceImage setImage:deviceObj.image];
    NSLog(@"Handled Device: %@", deviceObj.name);
  }
}

-(void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
  
  Device* device = [[room deviceList] objectAtIndex:rowIndex];
  NSLog(@"Selected Device: %@", device.name);
  //[self presentControllerWithName:@"Controll" context:device];
  
  if (device.type == light || device.type == switchableSocket) {
    NSLog(@"Send toggle command");
    [[PhoneConnector sharedPhoneConnector] sendCommand:ToggleCommand forDevice:device];
  } else if (device.type == ir) {
    [self presentControllerWithName:@"IRRemote" context:device];
  }
  
}

- (void)willActivate {
  // This method is called when watch view controller is about to be visible to user
  [super willActivate];
}

- (void)didDeactivate {
  // This method is called when watch view controller is no longer visible
  [super didDeactivate];
}

@end



