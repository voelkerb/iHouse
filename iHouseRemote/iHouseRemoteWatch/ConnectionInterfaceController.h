//
//  ConnectionInterfaceController.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 05/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "PhoneConnector.h"


@interface ConnectionInterfaceController : WKInterfaceController {
  PhoneConnector* phoneConnector;
}
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *connectButton;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *indicator;

@end
