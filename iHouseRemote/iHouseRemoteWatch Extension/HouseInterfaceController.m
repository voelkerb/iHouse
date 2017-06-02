//
//  HouseInterfaceController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 05/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "HouseInterfaceController.h"
#import "RoomRow.h"
#import "Constants.h"

@interface HouseInterfaceController ()

@end

@implementation HouseInterfaceController

@synthesize roomsTable, house;


- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  house = [House sharedHouse];
  NSLog(@"From Watch ROOMS: %@", [[House sharedHouse] roomList]);
  [self configureTable];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureTable) name:NCNewRoomImage object:nil];
}

- (void)configureTable {
  NSLog(@"config room table");
  // Plus the group
  [roomsTable setNumberOfRows:[[[House sharedHouse] roomList] count] + 1  withRowType:@"roomRowType"];
  
  
  for (NSInteger i = 0; i < [[[House sharedHouse] roomList] count]; i++) {
    RoomRow* theRow = [self.roomsTable rowControllerAtIndex:i];
    Room* roomObj = [[[House sharedHouse] roomList] objectAtIndex:i];
    
    [theRow.roomName setText:roomObj.name];
    [theRow.roomImage setImage:roomObj.image];
    NSLog(@"Handled room: %@", roomObj.name);
  }
  
  // Add groups at last index
  RoomRow* theRow = [self.roomsTable rowControllerAtIndex:self.roomsTable.numberOfRows-1];
  
  [theRow.roomName setText:@"Groups"];
  [theRow.roomImage setImage:[UIImage imageNamed:@"devices_256"]];
  
}

-(void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
  if (rowIndex < self.roomsTable.numberOfRows - 1) {
    Room* room = [house.roomList objectAtIndex:rowIndex];
    [self presentControllerWithName:@"Devices" context:room];
  } else {
    [self presentControllerWithName:@"Groups" context:nil];
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



