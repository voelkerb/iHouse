//
//  GroupRow.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 04.02.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>
#import "Group.h"

@interface GroupRow : NSObject

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *groupImage;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *groupName;

@end
