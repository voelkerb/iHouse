#include <SPI.h>
#include <Audio.h>
#include <SD.h>
#include <Wire.h>
#include <RF24.h>
#include "printf.h"
#include "AudioBuffer.h"
#include "KeyWordDetector.h"

#define DEBUG true

//------------------------------SD_CARD-----------------------------//
#define SDCARD_CS_PIN    10


//------------------------------POTI--------------------------------//
#define VOLUME_POTI_PIN A1


//------------------------------BUTTON------------------------------//
// Defines for the button pin and the delays for the actions
#define BUTTON_PIN A7
#define BUTTON_ACTION_DELAY_STREAM 100
#define BUTTON_ACTION_DELAY_PROGRAM 1000
#define BUTTON_ACTION_DELAY_ERASE_ALL 4000
#define BUTTON_ACTION_DELAY_NONE 6000


//------------------------------LED---------------------------------//
// TODO: Insert RGB LED for coloring
#define LED_PIN_R 20
#define LED_PIN_G 17//17
#define LED_PIN_B 16//22
#define RED   0
#define GREEN 1
#define BLUE  2
#define WHITE 3
#define BLACK 4
#define VIOLET 5


//------------------------------SERIAL------------------------------//
// SerialSpeed and easyVR speed
#define SERIAL_COMSPEED 115200


//------------------------------WUW--------------------------------//
// How strict the match must be
#define RECOGNITION_STRICTNESS 0

AudioBuffer audioBuffer;
KeyWordDetector keyWordDetector;



//------------------------------WAV-FILES---------------------------//
#define SOUND_ADD "add.WAV"
#define SOUND_DELETED "deleted.WAV"
#define SOUND_DIDNT_GET_THAT "didntGet.WAV"
#define SOUND_DONE "done.WAV"
#define SOUND_NOISE "noise.WAV"
#define SOUND_READY "ready.WAV"
#define SOUND_SERVER "server.WAV"
#define SOUND_SIMILAR "similar.WAV"
#define SOUND_SPEAK_NOW "speakNow.WAV"
#define SOUND_SPEAK_AGAIN "speakA.WAV"
#define SOUND_SIRI_START "siriSt.WAV"
#define SOUND_SIRI_STOP "siriStop.WAV"
#define SOUND_SIRI_DISCARD "siriDis.WAV"


//------------------------------AUDIO_BOARD-------------------------//
// GUItool: begin automatically generated code
AudioInputI2S            audioInput;           //xy=105,63
AudioRecordQueue         audioRecorder;         //xy=281,63
AudioOutputI2S           audioOutput;           //xy=470,120
AudioEffectBitcrusher    bitCrusher;
AudioPlayQueue           audioPlayer;
AudioPlaySdWav           memorySound;
AudioMixer4              mixAudioOut;
AudioConnection          c1(memorySound, 0, mixAudioOut, 0);
AudioConnection          c4(audioPlayer, 0, mixAudioOut, 1);
AudioConnection          lineInMonoConn1(audioInput, 1, bitCrusher, 0);
AudioConnection          lineInMonoConn2(bitCrusher, audioRecorder);
AudioConnection          lineOutL(mixAudioOut, 0, audioOutput, 0);
AudioConnection          lineOutR(mixAudioOut, 0, audioOutput, 1);
AudioControlSGTL5000     sgtl5000;     //xy=265,212
// GUItool: end automatically generated code
// Input on the audio shield



//------------------------------MICRO-------------------------------//
bool streamMic = false;
#define MIC_GAIN 50
//const int audioInputSource = AUDIO_INPUT_LINEIN;
const int audioInputSource = AUDIO_INPUT_MIC;


//------------------------------NRF24-------------------------------//
// The CE and CSN pins of the NRF24
#define CE_PIN  5
#define CSN_PIN 6
// The radio channel and data rate
#define AUDIO_STREAM_CHANNEL 1
#define AUDIO_STREAM_DATA_RATE RF24_1MBPS
// The radio number of this Micro
uint8_t radioNumber = 3; //(1-5)
// Define the transmit pipes
const uint64_t readPipe[5] = { 0xF0F0F0F0D2LL, 0xF0F0F0F0C3LL, 0xF0F0F0F0B4LL, 0xF0F0F0F0A5LL, 0xF0F0F0F096LL };
const uint64_t writePipe[5] = { 0x3A3A3A3AD2LL, 0x3A3A3A3AC3LL, 0x3A3A3A3AB4LL, 0x3A3A3A3AA5LL, 0x3A3A3A3A96LL };
const uint64_t broadcastPipe = { 0xF0F0F0F087LL };
// Create a Radio
RF24 audioStream(CE_PIN, CSN_PIN);


//------------------------------AUDIO_REC----------------------------//
// Audio buffer and its indices
#define AUDIO_BUFFER_SIZE 256
#define RADIO_BUFFER_SIZE 32
#define RADIO_NUMB_BUFFERS 2
// Buffer for one audio block
byte audioRecordBuffer[AUDIO_BUFFER_SIZE];
byte audioBlockBuffer[AUDIO_BUFFER_SIZE];
// Radio Buffer holding two payloads
uint8_t radioBuffer[RADIO_NUMB_BUFFERS][RADIO_BUFFER_SIZE];
uint8_t whichRadioBuffer = 0;
#define STREAM_TIMEOUT 10000
#define INCOMING_STREAM_TIMEOUT 200
elapsedMillis streamTime;
elapsedMillis incomingStreamTime;

bool streamIncoming = false;


bool keywordStored = true;

//------------------------------SETUP-------------------------------//
void setup() {
  // Set button pin as input
  pinMode(BUTTON_PIN, INPUT);
  pinMode(LED_PIN_R, OUTPUT);
  pinMode(LED_PIN_G, OUTPUT);
  pinMode(LED_PIN_B, OUTPUT);
  // Enable serial communication
  Serial.begin(SERIAL_COMSPEED);

  // Init the audio Board
  initAudioBoard();

  // Init the audioStream
  initAudioStream();

  // Init the SD Card
  SD.begin(SDCARD_CS_PIN);

  // Init the keyword detector with the handling functions
  keyWordDetector.init(&keywordDetected, &templateLearned);

  if (DEBUG) Serial.println(F("Setup done"));

  // Start the audio recorder
  audioRecorder.begin();
  
  // Set LEDs white in the beginning
  setLED(WHITE);
}

elapsedMicros calculationTimePerWindow;

//------------------------------LOOP--------------------------------//
void loop() {
  // Updates the volume of the speaker if needed
  updateSpeakerVolume();

  // Recognize command
  handleCommandDetection();

  // Handle button presses
  handleButton();

  // Read data if available
  handleIncomingStream();

  // Stream data if needed
  handleOutgoingStream();
}

// Handles WUW detector
void handleCommandDetection() {
  if (streamMic) return;
  
  // Sample new Audio data
  if (audioRecorder.available()) {
    int16_t *p = audioRecorder.readBuffer();
    audioBuffer.sampleAudio(p);
    // Free this audio Block
    audioRecorder.freeBuffer();
  }

  // If new window is available
  if (audioBuffer.available()) {
    // Get the latest audioWindow as pointer
    int8_t *audioWindow = audioBuffer.getBuffer();
    //printVector(audioWindow, WINDOW_LENGTH, true);
    // Perform calculation on this audioWindow
    keyWordDetector.update(audioWindow);
  }
}


// Streams Mic data if needed
void handleOutgoingStream() {
  if (!streamMic) return;
  // Automatically stop streaming after timeout
  if (streamTime > STREAM_TIMEOUT) {
    stopStreamingMicDiscard();
  }
  // If the audio recorder has new data
  if (audioRecorder.available()) {
    if (DEBUG) Serial.println("Outgoing audio data");
    // Fetch one audioBlock
    memcpy(audioRecordBuffer, audioRecorder.readBuffer(), AUDIO_BUFFER_SIZE);
    // Free this audio Block
    audioRecorder.freeBuffer();
    int j = 0;

    // ********* 8BIT, 22KHz *********** //
    /*
    for (int i = 1; i < 128; i += 4) {
      radioBuffer[0][j] = audioRecordBuffer[i];
      j++;
    }
    j = 0;
    for (int i = 129; i < 256; i += 4) {
      radioBuffer[1][j] = audioRecordBuffer[i];
      j++;
    }*/
    
    // ********* 8BIT, 11KHz *********** //
    for (int i = 1; i < 256; i += 8) {
      radioBuffer[0][j] = audioRecordBuffer[i];
      j++;
    }

    // Stop listening for radio Data
    audioStream.stopListening();
    // Write the complete buffers at once (much more efficient than to write single bytes)
    // Beware we can only send as much as 3 payloads at once, otherwise the data is flushed
    // before it is send
    audioStream.writeFast(radioBuffer[0], RADIO_BUFFER_SIZE); // writeFast
    //audioStream.writeFast(radioBuffer[1], RADIO_BUFFER_SIZE); // writeFast
    audioStream.txStandBy();
    // Enable reading again
    audioStream.startListening();
  }
}


// Reads data from the incoming stream if available
void handleIncomingStream() {
  // If Serial data is available and greater equal the buffer size
  if (audioStream.available()) {
    // Clear record buffer if streaming started
    if (!streamIncoming) {
      audioRecorder.end();
      audioRecorder.clear();
      setLED(VIOLET);
      streamIncoming = true;
    }
    
    // Reset incoming stream timer 
    incomingStreamTime = 0;
    
    // If was currently streaming, stop streaming, start listening
    if (streamMic) {
      stopStreamingMic();
      if (DEBUG) Serial.println("Stop streaming");
    }

    if (DEBUG) Serial.println("Incoming audio data");
    // Read the complete buffer at once (faster than to read single bytes)audioStream.read(radioBuffer[whichRadioBuffer], RADIO_BUFFER_SIZE);
    audioStream.read(radioBuffer[whichRadioBuffer], RADIO_BUFFER_SIZE);
    // Increment buffer index
    whichRadioBuffer++;
    // If buffer index greater than # buffers reset buffer index
    if (whichRadioBuffer >= RADIO_NUMB_BUFFERS) {
      whichRadioBuffer = 0;
      // Get a buffer for the audi samples
      int16_t *p = audioPlayer.getBuffer();

      // Map 64 Byte from radio to 256 Byte for audio block
      // Audio Block(0, 2, 4, 6 ...) is LSB,
      // Audio Block(1, 3, 5, 7 ...) is MSB,
      // -> For 8 Bit-audio write 128 MSB's,
      // Since we only have 64 Payloads from radio we decrease audio sample rate
      // from 44.1kHz to 22.05kHz -> write every two MSB's the same value

      // *********** 8Bit, 22kHz ********** //
      // Build array from first 32 Byte
      int j = 0;
      for (int i = 0; i < RADIO_BUFFER_SIZE; i++) {
        // LSB = 0 on 8 Bit
        audioBlockBuffer[j] = 0;
        // MSB = Radio value
        audioBlockBuffer[j + 1] = radioBuffer[0][i];
        // LSB = 0 on 8 Bit
        audioBlockBuffer[j + 2] = 0;
        // MSB = Radio value -> here map to 22.05 kHz
        audioBlockBuffer[j + 3] = radioBuffer[0][i];
        j += 4;
      }
      // Concate second 32 Byte to the array
      for (int i = 0; i < RADIO_BUFFER_SIZE; i++) {
        // LSB = 0 on 8 Bit
        audioBlockBuffer[j] = 0;
        // MSB = Radio value
        audioBlockBuffer[j + 1] = radioBuffer[1][i];
        // LSB = 0 on 8 Bit
        audioBlockBuffer[j + 2] = 0;
        // MSB = Radio value -> here map to 22.05 kHz
        audioBlockBuffer[j + 3] = radioBuffer[1][i];
        j += 4;
      }
      // Copy the audio block to the playBuffer
      memcpy(p, audioBlockBuffer, AUDIO_BUFFER_SIZE);
      // Play the buffer
      audioPlayer.playBuffer();
    }
  }
 
  // Start audio recorder if nothing came in a while 
  if (incomingStreamTime > INCOMING_STREAM_TIMEOUT && streamIncoming) {
    setLED(WHITE);
    audioRecorder.begin();
    streamIncoming = false;
  }
  
}


// Handle all button presses
elapsedMillis buttonTime;
int buttonState = 0;
void handleButton() {
  if (!digitalRead(BUTTON_PIN)) {
    Serial.println(F("Pressed"));
    // Stop the easy vr recognition
    // TODO: easyvr.stop();
    // Debounce delay
    delay(BUTTON_ACTION_DELAY_STREAM);
    if (!digitalRead(BUTTON_PIN)) {
      delay(200);
      // Waited enough for action 1 -> streaming
      if (DEBUG) Serial.print(F("1..."));
      // LED Color to GREEN -> Streaming
      setLED(GREEN);
      // Reset variables
      buttonTime = 0;
      buttonState = 0;
      // Will wait till Button is released
      while (!digitalRead(BUTTON_PIN)) {
        // If waited enough for action 2 -> adding
        if (buttonTime > BUTTON_ACTION_DELAY_PROGRAM && buttonState == 0) {
          buttonState = 1;
          if (DEBUG) Serial.print(F("2..."));
          // LED Color to BLUE -> Adding
          setLED(BLUE);
          // If waited enough for action 3 -> deleting
        } else if (buttonTime > BUTTON_ACTION_DELAY_ERASE_ALL && buttonState == 1) {
          buttonState = 2;
          if (DEBUG) Serial.print(F("3..."));
          // LED Color to RED -> Deleting
          setLED(RED);
          // If waited enough for action 4 -> nothing
        } else if (buttonTime > BUTTON_ACTION_DELAY_NONE && buttonState == 2) {
          buttonState = 3;
          if (DEBUG) Serial.println(F("4"));
          setLED(WHITE);
        }
      }
      // Handle actions after button is realesed here
      switch (buttonState) {
        // Handle toggle streaming
        case 0:
          if (!streamMic) {
            startStreamingMic();
          } else {
            stopStreamingMicDiscard();
          }
          break;
        case 1:
          stopStreamingMic();
          if (DEBUG) Serial.println(F("Add new command"));
          addWakeupWord();
          setLED(WHITE);
          break;
        case 2:
          stopStreamingMic();
          if (DEBUG) Serial.println(F("Delete all commands"));
          deleteAllWakeupWords();
          setLED(WHITE);
          break;
        case 3:
          if (DEBUG) Serial.println(F("Misspressed"));
          setLED(WHITE);
          break;
      }
    }
    // TODO: Restart recognition
    //easyvr.recognizeCommand(GROUP);
  }
}

// Add a new wakeup word
void addWakeupWord() {
  // Clear all recorded audio
  audioRecorder.end();
  audioRecorder.clear();
  memorySound.play(SOUND_SPEAK_NOW);
  delay(50);
  while (memorySound.isPlaying()) {}
  delay(50);
  audioRecorder.clear();
  keywordStored = false;
  Serial.println(F("Start learning new keyword"));
  // Enable audioRecorder before learning keyword to solve problem
  // with energy detection multiplier since longterm energy will be 
  // very small
  audioRecorder.clear();
  audioBuffer.clearBuffer();
  audioRecorder.begin();
  keyWordDetector.startLearningKeyword();
}


// Deletes all wakeup words from the easy vr module
void deleteAllWakeupWords() {
  // Clear all recorded audio
  audioRecorder.end();
  audioRecorder.clear();
  if (DEBUG) Serial.print(F("Remove all commands...."));

  keyWordDetector.deleteAllTemplates();

  memorySound.play(SOUND_DELETED);
  if (DEBUG) Serial.println(F("All commands removed"));
  setLED(BLACK);
  delay(200);
  setLED(RED);
  delay(200);
  while (memorySound.isPlaying()) {}
  setLED(WHITE);
  // Enable audioRecorder
  audioRecorder.begin();
}



// Start streaming mic data
void startStreamingMic() {
  if (streamMic) return;
  streamMic = true;

  if (DEBUG) Serial.println(F("Start streaming"));

  // Look if the Station is currently streaming to us
  delay(2);
  // If so don't stream mic
  if (audioStream.available()) {
    if (DEBUG) Serial.println(F("Stop Streaming, Station is still streaming"));
    stopStreamingMic();
    return;
  }
  // Clear all recorded audio
  audioRecorder.end();
  audioRecorder.clear();
  // Stop listening
  audioStream.stopListening();
  // Play start sound
  memorySound.play(SOUND_SIRI_START);
  // Set LED
  setLED(GREEN);
  delay(200);
  setLED(BLACK);
  delay(200);
  // Set LED back to green
  setLED(GREEN);
  while (memorySound.isPlaying()) {}
  // Stop listening
  audioStream.stopListening();
  // Reset streamtimer
  streamTime = 0;
  // Enable audioRecorder
  audioRecorder.begin();
}

// Stop streaming mic data
void stopStreamingMic() {
  if (!streamMic) return;
  streamMic = false;
  if (DEBUG) Serial.println(F("Stop streaming"));
  delay(100);
  // Set LED back to white
  setLED(WHITE);
  audioStream.startListening();
}


// Stop streaming mic data
void stopStreamingMicDiscard() {
  if (!streamMic) return;
  // Clear all recorded audio
  audioRecorder.end();
  audioRecorder.clear();
  streamMic = false;
  memorySound.play(SOUND_SIRI_DISCARD);
  if (DEBUG) Serial.println(F("Stop streaming discarded"));
  setLED(RED);
  delay(200);
  setLED(BLACK);
  delay(200);
  // Set LED back to white
  setLED(WHITE);
  while (memorySound.isPlaying()) {}
  audioStream.startListening();
  // Enable audioRecorder
  audioRecorder.begin();
}


// Updates the speaker volume of the line out
elapsedMillis volmsec = 0;
void updateSpeakerVolume() {
  // Every 50 ms, adjust the volume
  if (volmsec > 50) {
    float vol = analogRead(VOLUME_POTI_PIN);
    vol = 1 - (vol / 1023.0);
    // If volume is turned very low, mute lineout and set volume
    // On headphone to max
    sgtl5000.dacVolume(1.0);
    sgtl5000.volume(vol);
    sgtl5000.unmuteLineout();
    volmsec = 0;
  }
}

// Init the audio Stream
void initAudioStream() {
  // Since the audio board uses different spi pins, we need to change those here
  SPI.setMOSI(7);
  SPI.setSCK(14);
  // Settings of the NRF24
  // Begin radio
  audioStream.begin();
  // Set rf-channel (must be same on receiver side)
  audioStream.setChannel(AUDIO_STREAM_CHANNEL);
  // Disable Acknowledgement to fasten communication
  // TODO: it is enabled here to get acknowledge for every write fast
  audioStream.setAutoAck(1);
  // Set speed to fastest possible
  audioStream.setDataRate(AUDIO_STREAM_DATA_RATE);//RF24_1MBPS//RF24_2MBPS//RF24_250KBPS
  // Set crc check length
  audioStream.setCRCLength(RF24_CRC_8);
  // Open the reading pipeline
  audioStream.openReadingPipe(2, broadcastPipe);
  audioStream.openReadingPipe(1, readPipe[radioNumber - 1]);
  audioStream.openWritingPipe(writePipe[radioNumber - 1]);
  // Leave low poer mode
  audioStream.powerUp();
  // Show configuration of the RF Module on startup
  if (DEBUG) audioStream.printDetails();
  // Begin listening
  audioStream.startListening();
}


// Inits the audio board
void initAudioBoard() {
  // Audio connections require memory, and the record queue
  // uses this memory to buffer incoming audio.
  AudioMemory(40);

  // Enable the audio shield, select input, and enable output
  sgtl5000.enable();
  sgtl5000.inputSelect(audioInputSource);
  sgtl5000.lineInLevel(5);
  sgtl5000.micGain(40);
  // Disable auto Volume
  sgtl5000.autoVolumeDisable();
  // Set up bitcrusher for 16 Bit and 44.1kHz (TODO: bitcrusher does not do anything atm)
  bitCrusher.bits(16);
  bitCrusher.sampleRate(44100);
}



// Set the color of the LED
void setLED(int theColor) {
  switch (theColor) {
    case RED:
      digitalWrite(LED_PIN_R, HIGH);
      digitalWrite(LED_PIN_G, LOW);
      digitalWrite(LED_PIN_B, LOW);
      break;
    case GREEN:
      digitalWrite(LED_PIN_R, LOW);
      digitalWrite(LED_PIN_G, HIGH);
      digitalWrite(LED_PIN_B, LOW);
      break;
    case BLUE:
      digitalWrite(LED_PIN_R, LOW);
      digitalWrite(LED_PIN_G, LOW);
      digitalWrite(LED_PIN_B, HIGH);
      break;
    case VIOLET:
      digitalWrite(LED_PIN_R, HIGH);
      digitalWrite(LED_PIN_G, LOW);
      digitalWrite(LED_PIN_B, HIGH);
      break;
    case WHITE:
      digitalWrite(LED_PIN_R, HIGH);
      digitalWrite(LED_PIN_G, HIGH);
      digitalWrite(LED_PIN_B, HIGH);
      break;
    case BLACK:
      break;
  }
}

// This function is calles if a keyword was detected
void keywordDetected(int keyword) {
  Serial.println(keyword);
  startStreamingMic();
}


// This function is calles if a keyword was detected
void templateLearned(int success) {
  audioRecorder.end();
  audioRecorder.clear();
  delay(200);
  Serial.print(F("Template learned: "));
  Serial.println(success);
  memorySound.play(SOUND_DONE);
  delay(200);
  while (memorySound.isPlaying()) {}
  delay(200);
  audioRecorder.begin();
  keywordStored = true;
}
