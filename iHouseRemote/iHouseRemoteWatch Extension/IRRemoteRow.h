//
//  IRRemoteRow.h
//  iHouseRemote
//
//  Created by Benjamin Völker on 21/01/2017.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>
@protocol IRRemoteRowProtocol <NSObject>
@optional
-(void)commandToggledWithName:(NSString*)name;
@end


@interface IRRemoteRow : NSObject


@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *leftButton;
@property (nonatomic, retain) NSString *leftName;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *middleButton;
@property (nonatomic, retain) NSString *middleName;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *rightButton;
@property (nonatomic, retain) NSString *rightName;

@property (nonatomic,weak) WKInterfaceController<IRRemoteRowProtocol> *delegate;

@end
