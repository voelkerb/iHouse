//
//  GroupInterfaceController.m
//  iHouseRemote
//
//  Created by Benjamin Völker on 04.02.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import "GroupInterfaceController.h"
#import "Constants.h"
#import "GroupRow.h"
#import "PhoneConnector.h"

@interface GroupInterfaceController ()

@end

@implementation GroupInterfaceController


@synthesize groupsTable, house;


- (void)awakeWithContext:(id)context {
  [super awakeWithContext:context];
  house = [House sharedHouse];
  NSLog(@"From Watch GROUPS: %@", [[House sharedHouse] groupList]);
  [self configureTable];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureTable) name:NCNewGroupImage object:nil];
}

- (void)configureTable {
  NSLog(@"config group table");
  [groupsTable setNumberOfRows:[[[House sharedHouse] groupList] count] withRowType:@"groupRowType"];
  
  
  for (NSInteger i = 0; i < self.groupsTable.numberOfRows; i++) {
    GroupRow* theRow = [self.groupsTable rowControllerAtIndex:i];
    Group* groupObj = [[[House sharedHouse] groupList] objectAtIndex:i];
    
    [theRow.groupName setText:groupObj.name];
    [theRow.groupImage setImage:groupObj.image];
    NSLog(@"Handled group: %@", groupObj.name);
  }
}

-(void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
  
  Group* group = [house.groupList objectAtIndex:rowIndex];
  NSLog(@"Selected Group: %@", group.name);
  NSLog(@"Send toggle command");
  [[PhoneConnector sharedPhoneConnector] sendCommand:ToggleCommand forGroup:group];
  
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



