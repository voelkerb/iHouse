//
//  Settings.h
//  KickIt
//
//  Created by Benjamin Völker on 01/03/16.
//  Copyright © 2016 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Settings : NSObject<NSCoding>

@property NSString *serverIP;

+ (id)sharedSettings;

- (BOOL)store:(id) sender;

@end
