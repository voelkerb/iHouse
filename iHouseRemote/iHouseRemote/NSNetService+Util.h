//
//  NSNetService+Util.h
//  AmbiRemote
//
//  Created by Benjamin Völker on 02/01/2017.
//  Copyright © 2017 Karthik Abram. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNetService (Util)

- (NSArray*) addressesAndPorts;

@end


@interface AddressAndPort : NSObject

@property (nonatomic, assign) int port;
@property (nonatomic, strong)  NSString *address;

@end
