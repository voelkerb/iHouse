//
//  GroupInterfaceController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 04.02.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "House.h"

@interface GroupInterfaceController : WKInterfaceController

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *groupsTable;
@property (strong) House* house;

@end
