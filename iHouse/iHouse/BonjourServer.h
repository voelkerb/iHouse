//
//  BonjourServer.h
//  LivingHome
//
//  Created by Benjamin Völker on 17.05.13.
//
//

#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
@protocol BonjourServerDelegate
-(void) connectionReceived:(NSDictionary*) dict;
@end

@interface BonjourServer : NSObject {
    NSNetService	*netService;
    NSFileHandle	*listeningSocket;
	bool			serviceStarted;
    id <BonjourServerDelegate> delegate;
}

@property (retain, nonatomic) id <BonjourServerDelegate> delegate;


- (void) startServer;
- (void) stopServer;
- (void) connection:(NSNotification *)aNotification;

@end
