#include "AudioBuffer.h"
#include "KeyWordDetector.h"
#include <SPI.h>
#include <Audio.h>
#include <SD.h>
#include <Wire.h>

#define DEBUG 1
#define DEBUG_LOOP_TIME 0
#define DEBUG_WINDOW_TIME 0
#define DELETE_OLD_KEYWORDS

//------------------------------BUTTON------------------------------//
// Defines for the button pin and the delays for the actions
#define BUTTON_PIN A7
#define BUTTON_ACTION_DELAY_PROGRAM 100
#define BUTTON_ACTION_DELAY_ERASE_ALL 4000
#define BUTTON_ACTION_DELAY_NONE 6000

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


//------------------------------LED---------------------------------//
// TODO: Insert RGB LED for coloring
#define LED_PIN_R 20
#define LED_PIN_G 17
#define LED_PIN_B 16
#define RED   0
#define GREEN 1
#define BLUE  2
#define WHITE 3
#define BLACK 4

AudioBuffer audioBuffer;
KeyWordDetector keyWordDetector;

// GUItool: begin automatically generated code
AudioOutputI2S           audioOutput;           //xy=470,120
AudioPlaySdWav           memorySound;
AudioConnection          c1(memorySound, 0, audioOutput, 0);
AudioConnection          c2(memorySound, 0, audioOutput, 1);
AudioInputI2S            audioInput;           //xy=105,63
AudioRecordQueue         audioRecorder;         //xy=281,63
//AudioConnection          lineInMonoRecordConn(audioInput, 1, audioRecorder, 0);
AudioConnection          lineInMonoRecordConn(audioInput, audioRecorder);
AudioControlSGTL5000     sgtl5000;     //xy=265,212

// Which input on the audio shield will be used?
//#define INPUT_LINEIN
#define INPUT_MIC
#define MIC_GAIN 50

bool keywordStored = true;
elapsedMillis loops = 0;
int keyword = 0;
elapsedMicros calculationTimePerWindow;

/*******************************************************
 ***********************SETUP***************************
 *******************************************************/
void setup() {
  
  // Set button pin as input
  pinMode(BUTTON_PIN, INPUT);
  pinMode(LED_PIN_R, OUTPUT);
  pinMode(LED_PIN_G, OUTPUT);
  pinMode(LED_PIN_B, OUTPUT);
  
  Serial.begin(115200);
  delay(2000);
  Serial.println("Begin of program.");
  
  // Init the keyword detector with the handling functions
  keyWordDetector.init(&keywordDetected, &templateLearned);
  
  #ifdef DELETE_OLD_KEYWORDS
  // Delete all templates
  keyWordDetector.deleteAllTemplates();
  #endif
  
  // Init the audio shield and start the audio recording
  initAudioShield();
  
  // Start the audio recorder
  audioRecorder.begin();
  
  Serial.println("Setup done");
  loops = 0;
}

elapsedMillis delayTimer;

/*******************************************************
 ************************LOOP***************************
 *******************************************************/
void loop() {
  
  // Handle button presses
  handleButton();
  
  
  // Sample new Audio data
  sampleAudio();
  
  // If new window is available
  if (audioBuffer.available()) {
    elapsedMicros windowCalcTime = 0;
    // Get the latest audioWindow as pointer
    int8_t *audioWindow = audioBuffer.getBuffer();
    //printVector(audioWindow, WINDOW_LENGTH, true);
    // Perform calculation on this audioWindow
    keyWordDetector.update(audioWindow);
    
    if (DEBUG_WINDOW_TIME) {
      Serial.print("Window calcTime: ");
      Serial.print(windowCalcTime);
      Serial.println("us");
    }
    
    if (DEBUG_LOOP_TIME) {
      Serial.print("Loop update: ");
      Serial.print(calculationTimePerWindow);
      Serial.println("us");
    }
    calculationTimePerWindow = 0;
  }
  
  // TODO: on button press start learning keyword
  
}


// Handle all button presses
elapsedMillis buttonTime;
int buttonState = 0;
void handleButton() {
  if (!digitalRead(BUTTON_PIN)) {
    Serial.println("Pressed");
    // Stop the easy vr recognition
    // TODO: easyvr.stop();
    // Debounce delay
    delay(BUTTON_ACTION_DELAY_PROGRAM);
    if (!digitalRead(BUTTON_PIN)) {
      delay(200);
      // Waited enough for action 1 -> streaming
      if (DEBUG) Serial.print("1...");
      // LED Color to GREEN -> Streaming
      setLED(BLUE);
      // Reset variables
      buttonTime = 0;
      buttonState = 0;
      // Will wait till Button is released
      while (!digitalRead(BUTTON_PIN)) {
        // If waited enough for action 2 -> deleting    
        if (buttonTime > BUTTON_ACTION_DELAY_ERASE_ALL && buttonState == 0) {
          buttonState = 1;
          if (DEBUG) Serial.print("2...");
          // LED Color to RED -> Deleting
          setLED(RED);
        // If waited enough for action 4 -> nothing    
        } else if (buttonTime > BUTTON_ACTION_DELAY_NONE && buttonState == 1) {
          buttonState = 2;
          if (DEBUG) Serial.println("3");
          setLED(WHITE);
        }
      }
      // Handle actions after button is realesed here
      switch (buttonState) {
        // Handle toggle streaming
        case 0:
          if (DEBUG) Serial.println("Add new command");

          audioRecorder.clear();
          // TODO:
          memorySound.play(SOUND_SPEAK_NOW);
          delay(50);
          while(memorySound.isPlaying()) {}
          delay(50);
          audioRecorder.clear();
          keyWordDetector.startLearningKeyword();
          keywordStored = false;
          Serial.println("Start learning new keyword");
          setLED(WHITE);
          audioRecorder.begin();
  
          break;
        case 1:
          audioRecorder.clear();
          if (DEBUG) Serial.println("Delete all commands");
          keyWordDetector.deleteAllTemplates();
          memorySound.play(SOUND_DELETED);
          if (DEBUG) Serial.println("All commands removed");
          setLED(BLACK);
          delay(200);
          setLED(RED);
          delay(200);
          while(memorySound.isPlaying()) {}
          setLED(WHITE);
          audioRecorder.begin();
          break;
        case 2:
          if (DEBUG) Serial.println("Misspressed");
          setLED(WHITE);
          break;
      }
    }
  }
}


// Init the teensy audio shield
void initAudioShield() {
  // Audio connections require memory, and the record queue
  // uses this memory to buffer incoming audio.
  AudioMemory(50);
  
  // Enable the audio shield, select input, and enable output
  sgtl5000.enable();
  
#ifdef INPUT_LINEIN
  sgtl5000.inputSelect(AUDIO_INPUT_LINEIN);
#else
  sgtl5000.inputSelect(AUDIO_INPUT_MIC);
  // Set the Gain of the microphone amplifier (0-63 dB)
  sgtl5000.micGain(MIC_GAIN);
#endif
  
  // Set volume to lossless 0.8 corresponding to 0 dB
  sgtl5000.volume(0.7);
  // Disable auto Volume
  sgtl5000.autoVolumeDisable();
}

// Samples audio data
void sampleAudio() {
  if (audioRecorder.available()) {
    int16_t *p = audioRecorder.readBuffer();
    audioBuffer.sampleAudio(p);
    // Free this audio Block
    audioRecorder.freeBuffer();
  }
}

// This function is calles if a keyword was detected
void keywordDetected(int keyword) {
  audioRecorder.end();
  audioRecorder.clear();
  Serial.println(keyword);
  setLED(keyword);
  memorySound.play(SOUND_SIRI_START);
  delay(40);
  while(!memorySound.isPlaying()) {}
  while(memorySound.isPlaying()) {}
  delay(40);
  audioRecorder.begin();
}


// This function is calles if a keyword was detected
void templateLearned(int success) {
  audioRecorder.end();
  audioRecorder.clear();
  Serial.print("Template learned: ");
  Serial.println(success);
  memorySound.play(SOUND_DONE);
  delay(40);
  while(!memorySound.isPlaying()) {}
  while(memorySound.isPlaying()) {}
  
  delay(40);
  setLED(success);
  
  audioRecorder.begin();
  keywordStored = true;
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
    case WHITE:
      digitalWrite(LED_PIN_R, HIGH);
      digitalWrite(LED_PIN_G, HIGH);
      digitalWrite(LED_PIN_B, HIGH);
      break;
    case BLACK:
      digitalWrite(LED_PIN_R, LOW);
      digitalWrite(LED_PIN_G, LOW);
      digitalWrite(LED_PIN_B, LOW);
      break;
  }
}
