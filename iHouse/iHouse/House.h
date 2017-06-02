//
//  House.h
//  iHouse
//
//  Created by Benjamin Völker on 18/07/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Room.h"
#import "Settings.h"
#import "Group.h"
#import "VoiceCommand.h"

@interface House : NSObject <NSCoding> {
  NSString *name;
  NSArray *rooms;
  NSArray *groups;
  NSArray *voiceCommands;
}

// The name of the House
@property (nonatomic, retain) NSString *name;

// The rooms of the House in an array
@property (nonatomic, retain) NSArray *rooms;

// The rooms of the House in an array
@property (nonatomic, retain) NSArray *groups;

// The voice commands of the House in an array
@property (nonatomic, retain) NSArray *voiceCommands;

+ (id)sharedHouse;

// Adding a room to the house
- (BOOL)addRoom:(NSString*) roomName : (NSColor*) theColor : (NSImage*) theImage : (id)sender;

// Adding a room to the house
- (BOOL)addRoom:(Room*) theRoom : (id)sender;

// Remove a room of the house
- (BOOL)removeRoom:(NSString*) roomName : (id)sender;

// Adding a group to the house
- (BOOL)addGroup:(Group*) theGroup : (id)sender;

// Adding a group to the house
- (BOOL)removeGroup:(NSString*) theGroupName : (id)sender;

// Adding a voiceCommand to the house
- (BOOL)addVoiceCommand:(VoiceCommand*) theVoiceCommand : (id)sender;

// Remove a voiceCommand of the house
- (BOOL)removeVoiceCommand:(NSString*) theVoiceCommandName : (id)sender;

// Store the House data
- (BOOL)store:(id)sender;

@end
