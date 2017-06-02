//
//  AVBufferdPlayer.m
//  SpeechRecognitionWithAudioQueue
//
//  Created by Benjamin Völker on 15/12/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#import "AVBufferedPlayer.h"
#import "AudioDevice.h"
#import <Cocoa/Cocoa.h>
#include <vector>

// The sampling rate of the data streamed to this module
//#define DEFAULT_SAMPLING_RATE 22000
#define DEFAULT_SAMPLING_RATE 11000
// The Blocksize determines how many samples are buffered
// If this size is too low, you may have outages in playback
// If this size is too high, the signal may be shifted in time for
// various seconds
#define DEFAULT_BLOCK_SIZE 1000


@implementation AVBufferedPlayer

// Buffer holding the audio data (evil global variable)
static float bufferAVPlayer[2*DEFAULT_BLOCK_SIZE];
// Buffer indicating head and tail of the current audio data
unsigned int bufferAVPlayerHead;
unsigned int bufferAVPlayerTail;
unsigned int bufferAVPlayerSize = 2*DEFAULT_BLOCK_SIZE;

/*
 * Make this class singletone, so that it could be used from anywhere after init
 */
+ (id)sharedAVBufferedPlayer {
  static AVBufferedPlayer *sharedAVBufferedPlayer = nil;
  @synchronized(self) {
    if (sharedAVBufferedPlayer == nil) {
      sharedAVBufferedPlayer = [[self alloc] init];
    }
  }
  return sharedAVBufferedPlayer;
}

/*
 * Init with standard sampling rate and block size.
 */
- (id)init {
  if (self = [super init]) {
    blockSize = DEFAULT_BLOCK_SIZE;
    samplingRate = DEFAULT_SAMPLING_RATE;
  }
  return self;
}

/*
 * Init with a custom sampling rate and block size.
 */
-(id)initWithSamplingRate:(NSInteger)sr andBlockSize:(NSInteger)bs {
  if (self = [super init]) {
    blockSize = bs;
    samplingRate = sr;
  }
  return self;
}

/*
 * Toggle between play and pause.
 */
- (void)togglePlay {
  // If tone unit object exist, stop it and dealloc it
  if (toneUnit) {
    AudioOutputUnitStop(toneUnit);
    AudioUnitUninitialize(toneUnit);
    AudioComponentInstanceDispose(toneUnit);
    toneUnit = nil;
    // Reset buffer head and tail
    bufferAVPlayerHead = 0;
    bufferAVPlayerTail = 0;
  // If tone object does not exist, create it
  } else {
    [self createToneUnit];
    
    // It is not allowed to change parameters on the unit
    OSErr err = AudioUnitInitialize(toneUnit);
    // Print error if parameters were incorrect
    NSAssert1(err == noErr, @"Error initializing unit: %hd", err);
    // Start playback
    err = AudioOutputUnitStart(toneUnit);
    NSAssert1(err == noErr, @"Error starting unit: %hd", err);
  }
}

/*
 * Start playback.
 */
- (void)play {
  // If already started, nothing needs to be done
  if (toneUnit) {
    return;
  // Else create
  } else {
    [self createToneUnit];
    
    // It is not allowed to change parameters on the unit
    OSErr err = AudioUnitInitialize(toneUnit);
    // Print error if parameters were incorrect
    NSAssert1(err == noErr, @"Error initializing unit: %hd", err);
    // Start playback
    err = AudioOutputUnitStart(toneUnit);
    NSAssert1(err == noErr, @"Error starting unit: %hd", err);
  }
}

/*
 * Stop playback.
 */
- (void)stop {
  // If tone unit object exist, stop it and dealloc it
  if (toneUnit) {
    AudioOutputUnitStop(toneUnit);
    AudioUnitUninitialize(toneUnit);
    AudioComponentInstanceDispose(toneUnit);
    toneUnit = nil;
    // Reset buffer head and tail
    bufferAVPlayerHead = 0;
    bufferAVPlayerTail = 0;
  }
}

/*
 * Creating the tone unit object for playback and start audio callback function.
 */
- (void)createToneUnit {
  // Configure the search parameters to find the default playback output unit
  // (called the kAudioUnitSubType_RemoteIO on iOS but
  // kAudioUnitSubType_DefaultOutput on Mac OS X)
  AudioComponentDescription defaultOutputDescription;
  defaultOutputDescription.componentType = kAudioUnitType_Output;
  defaultOutputDescription.componentSubType = kAudioUnitSubType_DefaultOutput;
  defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
  defaultOutputDescription.componentFlags = 0;
  defaultOutputDescription.componentFlagsMask = 0;
  
  // Get the default playback output unit
  AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
  NSAssert(defaultOutput, @"Can't find default output");
  
  // Create a new unit based on the unit of the default output
  OSErr err = AudioComponentInstanceNew(defaultOutput, &toneUnit);
  NSAssert1(toneUnit, @"Error creating unit: %hd", err);
  
  // Set tone rendering function as a callback
  AURenderCallbackStruct input;
  input.inputProc = renderAudio;
  input.inputProcRefCon = (__bridge void * _Nullable)(self);
  err = AudioUnitSetProperty(toneUnit,
                             kAudioUnitProperty_SetRenderCallback,
                             kAudioUnitScope_Input,
                             0,
                             &input,
                             sizeof(input));
  NSAssert1(err == noErr, @"Error setting callback: %hd", err);
  
  // Set the format to 32 bit, single channel, floating point, linear PCM
  const int four_bytes_per_float = 4;
  const int eight_bits_per_byte = 8;
  // Change the audio unit object according to the sampling rate and format
  AudioStreamBasicDescription streamFormat;
  streamFormat.mSampleRate = samplingRate;
  streamFormat.mFormatID = kAudioFormatLinearPCM;
  streamFormat.mFormatFlags =	kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
  streamFormat.mBytesPerPacket = four_bytes_per_float;
  streamFormat.mFramesPerPacket = 1;
  streamFormat.mBytesPerFrame = four_bytes_per_float;
  streamFormat.mChannelsPerFrame = 1;
  streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
  err = AudioUnitSetProperty (toneUnit,
                              kAudioUnitProperty_StreamFormat,
                              kAudioUnitScope_Input,
                              0,
                              &streamFormat,
                              sizeof(AudioStreamBasicDescription));
  NSAssert1(err == noErr, @"Error setting stream format: %hd", err);
  
  // Search for the output device Soundflower
  // Soundflower is needed to create a virtual audio device the audio data is streamed to
  AudioDeviceID device = [self getSoundflowerAudioDeviceID];
  // If device is found, set the audio units property
  if (device != -1) {
    err = AudioUnitSetProperty(toneUnit,
                             kAudioOutputUnitProperty_CurrentDevice,
                             kAudioUnitScope_Global,
                             0,
                             &device,
                               sizeof(device));
    NSAssert1(err == noErr, @"Error setting stream format for soundlfower: %hd", err);
  } else {
    NSLog(@"Can not find Soundflower output device");
    // Display alert sheet that soundflower needs to be installed
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Ok"];
    [alert setMessageText:@"Soundflower Missing"];
    [alert setInformativeText:@"Soundflower is not installed on this system."];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
  }
}


// Audio Device struct has name and ID.
struct Device {
		char  mName[64];
		AudioDeviceID	mID;
};

// Vector holding all audio devices
std::vector<Device> DeviceList;

/*
 * Try to find the ID of the soundflower audio device
 */
-(AudioDeviceID) getSoundflowerAudioDeviceID {
  // If the device can not be found
  AudioDeviceID soundflower = -1;
  // Size of audio device properties
  UInt32 propsize;
  // Search for audio devices with the fiven properties
  AudioObjectPropertyAddress theAddress = { kAudioHardwarePropertyDevices,
    kAudioObjectPropertyScopeGlobal,
    kAudioObjectPropertyElementMaster };
  
  // Get size of properties of the audio devices
  AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &theAddress, 0, NULL, &propsize);
  int nDevices = propsize / sizeof(AudioDeviceID);
  // Create array holding the ids of all audio devices
  AudioDeviceID devids[nDevices];
  AudioObjectGetPropertyData(kAudioObjectSystemObject, &theAddress, 0, NULL, &propsize, devids);
  
  // Loop over all audio devices found
  for (int i = 0; i < nDevices; ++i) {
    // Create Audio Device object from it
    AudioDevice dev(devids[i], false);
    // If output channel exist
    if (dev.CountChannels() > 0) {
      // Get the name of the audio device
      Device d;
      d.mID = devids[i];
      dev.GetName(d.mName, sizeof(d.mName));
      // Convert name to string
      NSString *nameClean = [NSString stringWithCString:d.mName encoding:NSASCIIStringEncoding];
      //NSLog(@"%@", nameClean);
      // If device with name "Soundflower (2ch)" found, store device ID and break
      if ([nameClean isEqualToString:@"Soundflower (2ch)"]) {
        soundflower = d.mID;
        break;
      }
    }
  }
  return soundflower;
}

/*
 * Adds audio to the Queue
 */
-(void)addToQueue:(float *)samples :(int)size {
  // Don't add audio, if the no audio is currently playing
  if (!toneUnit) return;
  // Get current head (global varriable)
  unsigned int head = bufferAVPlayerHead;
  // Add floats to array
  for (int frame = 0; frame < size; frame++) {
    bufferAVPlayer[head] = samples[frame];
    head++;
    // Since this is a head and tail buffer, we need to
    // keep track if the head exceeds the buffer size
    if (head >= bufferAVPlayerSize) head = 0;
  }
  // Store back in member
  bufferAVPlayerHead = head;
}

// Values to ramp volume up and down to avoid pop sounds if no data available any more
// or new data incoming
// TODO: does not work for now
float rampIncrement = 0.001;
float rampValue = 0.0;

/*
 * Audio render function.
 */
OSStatus renderAudio( void *inRefCon,
                    AudioUnitRenderActionFlags 	*ioActionFlags,
                    const AudioTimeStamp 		*inTimeStamp,
                    UInt32 						inBusNumber,
                    UInt32 						inNumberFrames,
                    AudioBufferList 			*ioData) {
 
  // Get head and tail from buffer
  unsigned int tail = bufferAVPlayerTail;
  unsigned int head = bufferAVPlayerHead;
  
  // This is a mono tone generator so we only need the first audio buffer
  const int channel = 0;
  Float32 *audioBuff = (Float32 *)ioData->mBuffers[channel].mData;
  //NSLog(@"%u", (unsigned int)inNumberFrames);

  // For the requested number of frames, fill the buffer.
  for (UInt32 frame = 0; frame < inNumberFrames; frame++) {
    // If no audio data is in the buffer
    if (head == tail) {
      // If no audio data was put in yet, put in 0
      if (frame == 0) {
        audioBuff[frame] = 0;
      // Else we can use the last audio values
      } else {
        // Decrement volume of audio since, to avoid pop sounds
        if (rampValue > 0) rampValue -= rampIncrement;
        // Fill the last value with decreased volume in array
        audioBuff[frame] = rampValue*audioBuff[frame-1];
      }
    // If audio available
    } else {
      // Increase volume to avoid sudden pop sounds
      if (rampValue < 1.0f) rampValue += rampIncrement;
      // Fill buffer with audio data
      audioBuff[frame] = rampValue*bufferAVPlayer[tail];
    }
    // Remove old values
    // TODO: not needed since we keep track of head and tail
    bufferAVPlayer[tail] = 0;
    // keep track of new tail
    tail++;
    // Break if no new data available
    if (tail == head) break;
    // Keep track of the end of the array
    if (tail >= bufferAVPlayerSize) tail = 0;
  }
  // Store back in member
  bufferAVPlayerTail = tail;
  // Sure we did not do any error :D
  return noErr;
}

@end
