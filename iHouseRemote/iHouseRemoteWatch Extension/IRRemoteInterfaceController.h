//
//  IRRemoteInterfaceController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 21/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "PhoneConnector.h"
#import "House.h"
#import "IRRemoteRow.h"

@interface IRRemoteInterfaceController : WKInterfaceController <IRRemoteRowProtocol>

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *irCommandsTable;
@property (strong) Device* irDevice;

@end
