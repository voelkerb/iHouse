//
//  AmbiLight.h
//  iHouse
//
//  Created by Benjamin Völker on 06.03.17.
//  Copyright © 2017 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "AmbilightService.h"

@interface Ambilight : NSObject {
  AmbilightService *ambilightService;
}


// Return if application is open
- (BOOL)isConnected;

// Change brightness
- (BOOL)brightnessChange:(float) brightness;

// Change brightness
- (BOOL)changeColor:(NSColor*)color;


- (BOOL)toggleAmbilight:(BOOL) theState;
- (BOOL)toggleFade:(BOOL) theState;

// Return the standard voice commands
- (NSArray*)standardVoiceCommands;
// Return the available selectors for voice commands
- (NSArray*)selectors;
// Return the available voice actions
- (NSArray*)readableSelectors;

@end
