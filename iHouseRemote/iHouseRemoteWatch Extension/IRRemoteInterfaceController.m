//
//  IRRemoteInterfaceController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 21/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "IRRemoteInterfaceController.h"

@interface IRRemoteInterfaceController ()

@end

@implementation IRRemoteInterfaceController
@synthesize irDevice, irCommandsTable;

- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  self.irDevice = context;
  [self setTitle:irDevice.name];
  [self configureTable];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureTable) name:NCNewDeviceInfoImage object:nil];
  // Configure interface objects here.
}


- (void)configureTable {
  if (![irDevice.info objectForKey:KeyIRCommands]) {
    NSLog(@"Array empty %@", irDevice.info);
    return;
  }
  NSArray *irCommands = [irDevice.info objectForKey:KeyIRCommands];
  int rowCount = [irCommands count]/3;
  int irCount = [irCommands count];
  NSLog(@"config ir device table, rows: %i, devices: %i", rowCount, irCount);
  NSLog(@"info array %@", irCommands);
  
  NSMutableArray *sorted = [[NSMutableArray alloc] initWithCapacity:irCount];
  for (int i = 0; i < irCount; i++) {
    NSDictionary *dummy = @{KeyImage: [[UIImage alloc] init], KeyName : @""};
    [sorted addObject:dummy];
  }
  for (int i = 0; i < irCount; i++) {
    NSDictionary *dict = [irCommands objectAtIndex:i];
    int index = [[dict objectForKey:KeyIndex] integerValue];
    if (index >= 0 && index < irCount) {
      [sorted replaceObjectAtIndex:index withObject:dict];
    }
  }
  
  for (int i = 0; i < irCount; i++) {
    for (int i = 0; i < irCount; i++) {
      
    }
  }
  
  
  [irCommandsTable setNumberOfRows:rowCount withRowType:@"irDeviceRowType"];
  
  int cmdIndex = 0;
  for (NSInteger i = 0; i < self.irCommandsTable.numberOfRows; i++) {
    IRRemoteRow* theRow = [self.irCommandsTable rowControllerAtIndex:i];
    theRow.delegate = self;
    if (cmdIndex >= irCount) break;
    NSDictionary *dict = [sorted objectAtIndex:cmdIndex];
    [theRow.leftButton setBackgroundImage:[dict objectForKey:KeyImage]];
    theRow.leftName = [dict objectForKey:KeyName];
    NSLog(@"index: %i, name %@", cmdIndex, [dict objectForKey:KeyName]);
    cmdIndex++;
    if (cmdIndex >= irCount) break;
    NSDictionary *dict2 = [sorted objectAtIndex:cmdIndex];
    [theRow.middleButton setBackgroundImage:[dict2 objectForKey:KeyImage]];
    theRow.middleName = [dict2 objectForKey:KeyName];
    NSLog(@"index: %i, name %@", cmdIndex, [dict2 objectForKey:KeyName]);
    cmdIndex++;
    if (cmdIndex >= irCount) break;
    NSDictionary *dict3 = [sorted objectAtIndex:cmdIndex];
    [theRow.rightButton setBackgroundImage:[dict3 objectForKey:KeyImage]];
    theRow.rightName = [dict3 objectForKey:KeyName];
    NSLog(@"index: %i, name %@", cmdIndex, [dict3 objectForKey:KeyName]);
    cmdIndex++;
    if (cmdIndex >= irCount) break;
  }
}

-(void)commandToggledWithName:(NSString *)name {
  NSLog(@"Toggled Command: %@", name);
  NSLog(@"Send toggle command");
  [[PhoneConnector sharedPhoneConnector] sendCommand:IRToggleCommand forDevice:self.irDevice withInfo:name];
}

-(void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
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



