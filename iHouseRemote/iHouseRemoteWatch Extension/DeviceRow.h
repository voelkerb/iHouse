//
//  DeviceRow.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 05/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface DeviceRow : NSObject

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *deviceImage;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *deviceName;

@end
