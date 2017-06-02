//
//  roomRowController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 05/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>
#import "Room.h"

@interface RoomRow: NSObject
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *roomImage;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *roomName;

@end
