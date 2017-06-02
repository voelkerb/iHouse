//
//  InteractiveVoiceCommand.m
//  iHouse
//
//  Created by Benjamin Völker on 22/08/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "VoiceCommand.h"
#import "VoiceCommandHandler.h"
#import "Room.h"

#define DEBUG_VOICE_COMMAND 0

// Response on error while execution
#define VOICE_RESPONSES_WENT_WRONG @"Something went wrong.", @"Connection problem.", @"Sorry, but the device is not connected."

NSString* const VoiceCommandAdded = @"VoiceCommandAdded";
NSString* const VoiceCommandRemoved = @"VoiceCommandRemoved";
NSString* const VoiceCommandChanged = @"VoiceCommandChanged";
NSString* const VoiceCommandNameChanged = @"VoiceCommandNameChanged";
NSString* const VoiceCommandAnyRoom = @"VoiceCommandAnyRoom";

// Key to get command response readed
NSString * const KeyVoiceCommandResponseSpeechString = @"KeyVoiceCommandResponseSpeechString";
// Key to get command response
NSString * const KeyVoiceCommandResponseString = @"KeyVoiceCommandResponseString";
// Key to get successfull execution
NSString * const KeyVoiceCommandExecutedSuccessfully = @"KeyVoiceCommandExecutedSuccessfully";
// Key to get command response view controller (if there is any)
NSString * const KeyVoiceCommandResponseViewController = @"KeyVoiceCommandResponseViewController";
// Key to get command response view (if there is any)
NSString * const KeyVoiceCommandResponseView = @"KeyVoiceCommandResponseView";


// Notification for opening voice command view
NSString* const StartVoiceCommandDetection = @"StartVoiceCommandDetection";

// Notification for discarding voice command view
NSString* const VoiceCommandDetectionDiscarded = @"VoiceCommandDetectionDiscarded";

// Notification for succesfull voice command recognition
NSString* const VoiceCommandDetectedSuccesfully = @"VoiceCommandDetectedSuccesfully";

// Notification for command response finished speaking
NSString* const VoiceCommandResponseFinished = @"VoiceCommandResponseFinished";

@implementation VoiceCommand
@synthesize command, name, responses, image, handler, selector, room, commandView;

-(id)init {
  if (self = [super init]) {
    // Init all variables on new command
    name = @"new command";
    command = @"";
    selector = @"";
    // Dummy room
    Room *theRoom = [[Room alloc] init];
    theRoom.name = VoiceCommandAnyRoom;
    room = theRoom;
    responses = [[NSArray alloc] init];
    commandView = voiceCommand_device_view;
  }
  return self;
}

// Encoding for saving in File
- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.command forKey:@"command"];
  [encoder encodeObject:self.responses forKey:@"responses"];
  [encoder encodeObject:self.image forKey:@"image"];
  [encoder encodeObject:self.handler forKey:@"handler"];
  [encoder encodeObject:self.selector forKey:@"selector"];
  [encoder encodeObject:self.room forKey:@"room"];
  [encoder encodeInteger:self.commandView forKey:@"commandView"];
}

// Decoding from stored file
- (id)initWithCoder:(NSCoder *)decoder {
  if((self = [super init])) {
    self.name = [decoder decodeObjectForKey:@"name"];
    self.command = [decoder decodeObjectForKey:@"command"];
    self.responses = [decoder decodeObjectForKey:@"responses"];
    self.image = [decoder decodeObjectForKey:@"image"];
    self.handler = [decoder decodeObjectForKey:@"handler"];
    self.selector = [decoder decodeObjectForKey:@"selector"];
    self.room = [decoder decodeObjectForKey:@"room"];
    self.commandView = [decoder decodeIntegerForKey:@"commandView"];
  }
  return self;
}


/*
 * Is called if the command is detected.
 */
- (NSDictionary *)execute {
  bool stringAdded = false;
  // Dictionary with all responses (text and view)
  NSMutableDictionary *executionResponse = [[NSMutableDictionary alloc] init];
  
  // If a handler exist and has the execute selector
  if (handler && [handler respondsToSelector:@selector(executeSelector:)]) {
    // Store successfull execution in the dictionary
    [executionResponse addEntriesFromDictionary:
     [handler performSelector:@selector(executeSelector:) withObject:selector]];
  }
  // If not executed successfully add error message
  if (![[executionResponse objectForKey:KeyVoiceCommandExecutedSuccessfully] boolValue] && handler) {
    [executionResponse addEntriesFromDictionary:[self errorText]];
  // On succesfull execution add random response text
  } else {
    if (![executionResponse objectForKey:KeyVoiceCommandResponseString]) {
      // If the device did not attach a voice response, attach it here
      [executionResponse addEntriesFromDictionary:[self respondText]];
      stringAdded = true;
    }
    // If a voice answer exist and a custom string was added at the settings as well
    // add it to the answer
    /*
    if ([self respondText] && !stringAdded) {
      [executionResponse setObject:[NSString stringWithFormat:@"%@ %@", [executionResponse objectForKey:KeyVoiceCommandResponseString],
                                  [[self respondText] objectForKey:KeyVoiceCommandResponseString]]
                              forKey:KeyVoiceCommandResponseString];
      if ([executionResponse objectForKey:KeyVoiceCommandResponseSpeechString]) {
        [executionResponse setObject:[NSString stringWithFormat:@"%@ %@", [executionResponse objectForKey:KeyVoiceCommandResponseSpeechString],
                                  [[self respondText] objectForKey:KeyVoiceCommandResponseString]]
                              forKey:KeyVoiceCommandResponseSpeechString];
      }
    }*/
    
  }
  
  if (DEBUG_VOICE_COMMAND) NSLog(@"Handler: %@, execution: %@, Response: %@", handler, [executionResponse objectForKey:KeyVoiceCommandExecutedSuccessfully], executionResponse);
  
  // A view or viewController or image is appended here:
  // If a custom view should be appended
  if (commandView == voiceCommand_custom_view) {
    // If image exists
    if (image) {
      // Make image view container and add to the exectution response dictionary
      NSImageView *imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, image.size.width, image.size.height)];
      [imageView setImage:image];
      [executionResponse addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:imageView, KeyVoiceCommandResponseView, nil]];
    }
  // If a device view should be attached and the device did not attach it by own
  } else if (commandView == voiceCommand_device_view && ![executionResponse objectForKey:KeyVoiceCommandResponseView]
             && ![executionResponse objectForKey:KeyVoiceCommandResponseViewController]) {
    // Look if the handler responses to this selector
    if (handler && [handler respondsToSelector:@selector(deviceView)]) {
      // Get the viewControler of the response view
      NSViewController *viewController = [handler performSelector:@selector(deviceView) withObject:nil];
      // If this is not nil, add it to the dictionary
      if (viewController) {
        [executionResponse addEntriesFromDictionary:
         [NSDictionary dictionaryWithObjectsAndKeys:
          viewController, KeyVoiceCommandResponseViewController, nil]];
      }
    }
  }
  // Return the response
  return executionResponse;
}

/*
 * Returns one single random response string from all responses.
 */
- (NSDictionary *)respondText {
  NSString *response = @"";
  if ([responses count]) response = [responses objectAtIndex:arc4random_uniform((int)[responses count])];
  // Repsonse dictionary should be a text
  return [NSDictionary dictionaryWithObjectsAndKeys:response, KeyVoiceCommandResponseString, nil];
}

/*
 * Returns one single random response string from all error responses.
 */
- (NSDictionary *)errorText {
  NSString *response = @"";
  NSArray *wentWrongText = [NSArray arrayWithObjects:VOICE_RESPONSES_WENT_WRONG, nil];
  if ([wentWrongText count]) response = [wentWrongText objectAtIndex:arc4random_uniform((int)[wentWrongText count])];
  // Repsonse dictionary should be a text
  return [NSDictionary dictionaryWithObjectsAndKeys:response, KeyVoiceCommandResponseString, nil];
}


@end
