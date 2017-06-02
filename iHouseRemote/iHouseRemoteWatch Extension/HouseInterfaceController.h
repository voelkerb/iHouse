//
//  HouseInterfaceController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 05/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "House.h"

@interface HouseInterfaceController : WKInterfaceController
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *roomsTable;
@property (strong) House* house;

@end
