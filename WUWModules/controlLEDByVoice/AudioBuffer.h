/****************************************************
TODO
 ****************************************************/

#ifndef AudioBuffer_h
#define AudioBuffer_h

#if (ARDUINO >= 100)
#include "Arduino.h"
#else
#include "WProgram.h"
#endif

// Debug-messages.
#define DEBUG 1

#define AUDIO_RECORD_BUFFER_SIZE 256
#define NUMB_WINDOWS 2

// Sampling rate in HZ
#define SAMPLING_RATE 16000
// Window and Frame length in ms
#define WINDOW_LENGTH_MS 20
#define FRAME_LENGTH_MS 10

// Calculate number of samples for a window or frame
#define WINDOW_LENGTH WINDOW_LENGTH_MS * SAMPLING_RATE / 1000
#define FRAME_LENGTH FRAME_LENGTH_MS * SAMPLING_RATE / 1000

class AudioBuffer {
public:
    
  // Constructor
  AudioBuffer();
  
  // If a new Audio Window is available
  bool available();
  
  // Returns a pointer to the buffer
  int8_t* getBuffer();
  
  // Clears the buffer
  void clearBuffer();
  
  // Adds new audio samples to the audio array
  void sampleAudio(int16_t *p);
  
private:
  size_t whichWindowBuffer;
  size_t windowIndex;
  int completedWindow;
  // Buffer for one recorded audio block
  byte audioRecordBuffer[AUDIO_RECORD_BUFFER_SIZE];
  int8_t audioWindow[NUMB_WINDOWS][WINDOW_LENGTH];
};

#endif


