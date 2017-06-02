//
//  GroupItem.h
//  iHouse
//
//  Created by Benjamin Völker on 15/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDevice.h"

@interface GroupItem : NSObject<NSCoding>

// Group item has a device which is referenced via its id since the name is not unique
// and might change
@property (strong) IDevice *device;
// The Selector determines the action which should be performed. This depends on the device
// and the available actions of the device
@property (strong) NSString *selector;

// Activates this group item by performing the selector on the device
-(BOOL)performTheSelector;

@end
