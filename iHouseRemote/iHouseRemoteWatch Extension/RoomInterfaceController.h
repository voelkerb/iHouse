//
//  RoomInterfaceController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 04/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "PhoneConnector.h"
#import "House.h"

@interface RoomInterfaceController : WKInterfaceController

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *devicesTable;

@property (strong) Room* room;

@end
