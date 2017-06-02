//
//  InteractiveVoiceCommand.h
//  iHouse
//
//  Created by Benjamin Völker on 22/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@class Room;

// If new voice command added
extern NSString* const VoiceCommandAdded;
// If voice command was removed
extern NSString* const VoiceCommandRemoved;
// If the name of a voice command changed
extern NSString* const VoiceCommandChanged;
// If the name of a voice command changed (no need to reinit command)
extern NSString* const VoiceCommandNameChanged;
// String for Execution possible in any room
extern NSString* const VoiceCommandAnyRoom;

// Key to get command response
extern NSString * const KeyVoiceCommandResponseString;
// Key to get command response readed
extern NSString * const KeyVoiceCommandResponseSpeechString;
// Key to get successfull execution
extern NSString * const KeyVoiceCommandExecutedSuccessfully;
// Key to get command response view controller (if there is any)
extern NSString * const KeyVoiceCommandResponseViewController;
// Key to get command response view (if there is any)
extern NSString * const KeyVoiceCommandResponseView;

// Notification for opening voice command view
extern NSString* const StartVoiceCommandDetection;

// Notification for discarding voice command view
extern NSString* const VoiceCommandDetectionDiscarded;

// Notification for succesfull voice command recognition
extern NSString* const VoiceCommandDetectedSuccesfully;

// Notification for command response finished speaking
extern NSString* const VoiceCommandResponseFinished;

// Enum for the return view. (no view, device view or custom image)
typedef NS_ENUM(NSUInteger, CommandView) {
  voiceCommand_no_view,
  voiceCommand_device_view,
  voiceCommand_custom_view
};

@interface VoiceCommand : NSObject<NSCoding>

// The name of the command
@property (strong) NSString *name;

// The imageView of the command
@property (strong) NSImage *image;
// What view should be returned
@property CommandView commandView;
// The command
@property (strong) NSString *command;
// The commands active room
@property (strong) Room *room;
// The command responses
@property (strong) NSArray *responses;
// The command Handler
@property (strong) NSObject *handler;
// The command Handlers selector
@property (strong) NSString *selector;

// Execute on voice command detection
- (NSDictionary*)execute;

@end
