/****************************************************
TODO
 ****************************************************/

#include "AudioBuffer.h"


// _______________________________________________________
AudioBuffer::AudioBuffer() {
  whichWindowBuffer = 0;
  windowIndex = 0;
  completedWindow = -1;
}


// _______________________________________________________
bool AudioBuffer::available() {
  if (completedWindow == -1) return false;
  else return true;
}

// _______________________________________________________
int8_t* AudioBuffer::getBuffer() {
  uint8_t buf = 0;
  if (completedWindow != -1) buf = (uint8_t)completedWindow;
  completedWindow = -1;
  return &audioWindow[buf][0];
}

// _______________________________________________________
void AudioBuffer::clearBuffer() {
  completedWindow = -1;
  for (int i = 0; i < NUMB_WINDOWS; i++) {
    for (int j = 0; j < WINDOW_LENGTH; j++) {
      audioWindow[i][j] = 0;
    }
  }
  for (int i = 0; i < AUDIO_RECORD_BUFFER_SIZE; i++) audioRecordBuffer[i] = 0;
}

// _______________________________________________________
void AudioBuffer::sampleAudio(int16_t *p) {
  // Fetch one audioBlock
  memcpy(audioRecordBuffer, p, AUDIO_RECORD_BUFFER_SIZE);
    
  // Break the sampling frequency down to the desired Frequency
  // Audio Block(0, 2, 4, 6 ...) is LSB,
  // Audio Block(1, 3, 5, 7 ...) is MSB,
  unsigned int j = 0;
  j = 1;
  // Take every 2.75 sample for 16kHz
  float index = 1.0;
  while (j < AUDIO_RECORD_BUFFER_SIZE) {
    
    audioWindow[whichWindowBuffer][windowIndex] = (int8_t)audioRecordBuffer[j];
    windowIndex++;
    // If reaches end of window buffer
    if (windowIndex >= WINDOW_LENGTH) {
      windowIndex = WINDOW_LENGTH-FRAME_LENGTH;
      // Increment window buffer
      unsigned int nextWindowBuffer = whichWindowBuffer + 1;
      nextWindowBuffer %= NUMB_WINDOWS;
        
        
      //loat *p = &audioWindow[whichWindowBuffer][FRAME_LENGTH];
      // Copy the audio block to the playBuffer
      memcpy(audioWindow[nextWindowBuffer], audioWindow[whichWindowBuffer] + FRAME_LENGTH, WINDOW_LENGTH-FRAME_LENGTH);
   /*
      int k = 0;
      for (int i = FRAME_LENGTH; i < WINDOW_LENGTH; i++) {
        audioWindow[nextWindowBuffer][k] = audioWindow[whichWindowBuffer][i];
        k++;
      }
     */
      // Set the completed window pointer
      completedWindow = whichWindowBuffer;
      
      // Set the next window buffer
      whichWindowBuffer = nextWindowBuffer;
    }
      
    index += 5.5;
    j = (int) index;
    if (j % 2 != 1) j--;   
  }
}
