//
//  PreferenceWindowController.h
//  iHouse
//
//  Created by Benjamin Völker on 08/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
// The Functions the delegate has to implement
@protocol PreferenceWindowControllerDelegate <NSObject>

// The delegate needs to change something
- (void) preferencesDidClose;

@end

@interface PreferenceWindowController : NSWindowController

// The delegate variable
@property (weak) id<PreferenceWindowControllerDelegate> delegate;


@end
