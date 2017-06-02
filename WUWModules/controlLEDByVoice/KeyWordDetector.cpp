/****************************************************
TODO
 ****************************************************/

#include "KeyWordDetector.h"
#include "arrayFunctions.h"
#include "melScale.h"
#include "fft.h"
#include "dct.h"
#include "dtw.h"
#include "signal.h"

// This is equal to 1,5s of speech
#define TEST_TEMPLATE_FRAME_SIZE 110


// _______________________________________________________
void KeyWordDetector::dumpInfo() {
  Serial.print("SamplingRate: ");
  Serial.print(SAMPLING_RATE);
  Serial.println("Hz");
  
  Serial.print("Window length: ");
  Serial.print(WINDOW_LENGTH_MS);
  Serial.print("ms -> ");
  Serial.print(WINDOW_LENGTH);
  Serial.println("samples");
  
  Serial.print("Frame length: ");
  Serial.print(FRAME_LENGTH_MS);
  Serial.print("ms -> ");
  Serial.print(FRAME_LENGTH);
  Serial.println("samples");
  
  Serial.print("FFT Size: ");
  Serial.println(FFT_SIZE);
  
  
  
  Serial.print("Mel Frequencies: ");
  Serial.print(MEL_MIN_FREQUENCY);
  Serial.print("Hz - ");
  Serial.print(MEL_MAX_FREQUENCY);
  Serial.print("Hz, with : ");
  Serial.print(NUM_MEL_FILTER_BANKS);
  Serial.println(" Filter Banks");
  
  
  Serial.print("Preemphasis: ");
  Serial.println(A_PREEMPHASIS);
  
  Serial.print("DTW Comparisons: ");
  Serial.println(NUMBER_OF_DTW_COMPARISONS);
  
  Serial.print("Match threshold: ");
  Serial.println(MATCH_THRESHOLD);
}

// _______________________________________________________
KeyWordDetector::KeyWordDetector() {
  
  windowNormS1 = 0.0f;
  windowNormS2 = 0.0f;
  powerSpectrumScale = 0.0f;
  
  templateKeywordFrameCount = 0;
  potentiallKeywordFrameCount = 0;
  
  activated = false;
  
  // Must be inited greater the silence threshold
  frameSilenceCount = FRAME_SILENCE_THRESHOLD + 1;
  // Long term energy must be inited with -1
  longTermEnergy = -1;
  
  
  // Is incremented on none silence parts to length match potential keywords
  frameCount = 0;
  
  // Start index for energy calcualtion
  energyIndex = 0;
  
  // The size of the template
  templateKeywordFrameCount = 0;
  
  // Reset is used if a keyword was too short, no closer match perfomed
  reset = false;
  
  // Waiting for next silence is used if a keyword is too long, no closer match is performed
  waitForNextSilence = false;
  
  // Is not learning keyword at beginning
  learnKeyword = false;
  
  // The number of histwindows is 0 for the beginning
  histWindow = 0;
  firstHistBins = 0;
  
  // Assume low noise at the beginning
  bgNoise = LOW_NOISE_THRESHOLD;
  
  // This number is set correctly in the init
  numberOfStoredTemplates = 0;
  
  
  // Must be inited with their maximal opposite
  shortestTemplateSize = INFINITY;
  longestTemplateSize = 0;
}

// _______________________________________________________
KeyWordDetector::~KeyWordDetector() {
  // The energies and mfccs of the template and test
  free(templateEnergies);
  //free(templateMFCCs);
  
  free(testEnergies);
  //free(testMFCCs);
}


// _______________________________________________________
void KeyWordDetector::init(void (*keywordHandler)(int), void (*templateHandler)(int)) {
  // Store the handler function
  keywordHandlerFunction = keywordHandler;
  templateHandlerFunction = templateHandler;
  
  // Since the audio board uses different spi pins, we need to change those here
  SPI.setMOSI(7);
  SPI.setSCK(14);
  // Init the SD card
  if (DEBUG_KD_MORE) Serial.print("Initializing SD card...");
  pinMode(SD_CS, OUTPUT);
  if (!SD.begin(SD_CS)) {
    if (DEBUG_KD_MORE) Serial.println("initialization failed!");
  } else {
    if (DEBUG_KD_MORE) Serial.println("initialization done.");
  }
  
  
  // Read all available MFCC data from SD card
  for (int i = 0; i < 100; i++) {
    if (SD_readMFCCData(i)) {
      if (DEBUG_KD_MORE) {
        Serial.print("Template size: ");
        Serial.print(templateKeywordFrameCount);
        Serial.println(" frames");
        //printV(templateMFCCs, templateKeywordFrameCount*NUM_MFCCS, true);
      }
      
      // Determine the longest and shortes keyword
      if (templateKeywordFrameCount < shortestTemplateSize)  shortestTemplateSize = templateKeywordFrameCount;
      if (templateKeywordFrameCount > longestTemplateSize)  longestTemplateSize = templateKeywordFrameCount; 
    } else {
      numberOfStoredTemplates = i;
      break;
    }
  }
  
  if (DEBUG_KD) {
    Serial.print("Total number of templates: ");
    Serial.println(numberOfStoredTemplates);
    Serial.print("Longest template: ");
    Serial.println(longestTemplateSize);
    Serial.print("Shortest template: ");
    Serial.println(shortestTemplateSize);
  }
  
  // Calculate the size of the needed FFT
  initFFT();
  // Generate the Mel filter bank
  generateMelFilterBank();
  // Geneerate the window function
  generateWindowFunction();
  // Calculate needed DCT coefficients
  computeDCTCoeff26(dctCoeff);
  
  if (DEBUG_KD) dumpInfo();
}

// _______________________________________________________
void KeyWordDetector::startLearningKeyword() {
  learnKeyword = true;
  
  activated = false;
  potentiallKeywordFrameCount = 0;
}

// _______________________________________________________
void KeyWordDetector::update(int8_t *audioWindow) {
  int histIndex = 0;
  for (int i = 0; i < WINDOW_LENGTH; i++) {
    vReal[i] = (short)audioWindow[i];
    histIndex = abs(audioWindow[i])/HIST_STEP;
    if (histIndex <= FIRST_HIST_BINS) firstHistBins++;
  }
  // If currently learning keyword
  if (learnKeyword) {
    getNewTemplate();
  } else {
    // If no template is available, we don't have to do anything
    if (!numberOfStoredTemplates) return;
    testForKeyword();
  }
  
  // If number of hist windows exceeds threshold, recalculate the bg noise estimation
  histWindow++;
  if (histWindow >= NUM_WINDOWS_HIST) {
    bgNoise = (float)firstHistBins/(float)(NUM_WINDOWS_HIST*WINDOW_LENGTH);
    if (DEBUG_KD_MORE) {
      if (bgNoise >= LOW_NOISE_THRESHOLD) Serial.println("Low Noise");
      else if (bgNoise >= MEDIUM_NOISE_THRESHOLD) Serial.println("Medium Noise");
      else Serial.println("High Noise");
    }
    firstHistBins = 0;
    histWindow = 0;
  }
  
}


// _______________________________________________________
bool KeyWordDetector::deleteAllTemplates() {
  bool success = true;
  for (int i = 0; i < numberOfStoredTemplates; i++) {
     // Get the filename beginning
    char fileName[15] = FILENAME;
    // The number to append to the filename (e.g. MFCCs_3) 
    // Is is not allowed to exceed 99 stored templates
    char fileNum[3];
    
    // Get the index where to append the filenumber
    int appendAtIndex = sizeof(FILENAME)-1;
    // Safety check, that filename is large enough to hold characters
    if (appendAtIndex > -1 && appendAtIndex < (int)sizeof(fileName)) {
      sprintf(fileNum, "%i", i);
    } else {
      Serial.println("Error with append index.");
      return false;
    }
    
    strcat(fileName, fileNum);
    strcat(fileName, FILEENDING);
    
    if (DEBUG_KD) {
      Serial.print("Try to remove file: ");
      Serial.println(fileName);
    }
    // If file already exist, remove it first
    if (SD.exists(fileName)) {
      SD.remove(fileName);
      Serial.println("Delete old template data.");
    } else {
      success = false;
    }
  }
  numberOfStoredTemplates = 0;
  shortestTemplateSize = INFINITY;
  longestTemplateSize = 0;
  return success;
  
}


// _______________________________________________________
void KeyWordDetector::initFFT() {
  /*
  // Increase FFT size until it is a power of 2
  FFT_SIZE = WINDOW_LENGTH;
  if ((WINDOW_LENGTH & (WINDOW_LENGTH - 1)) != 0) {
    while ((FFT_SIZE & (FFT_SIZE - 1)) != 0) FFT_SIZE++;
  }
  
  if (DEBUG_KD) {
    Serial.print("FFT_SIZE: ");
    Serial.println(FFT_SIZE);
  }
  
  
  // Construct imaginary vector and fill 0s in
  vImag = (float*)malloc(FFT_SIZE*(sizeof(float)));
  vReal = (float*)malloc(FFT_SIZE*(sizeof(float)));

  if (vImag == NULL) Serial.println("Not enough memory for vImag");
  if (vReal == NULL) Serial.println("Not enough memory for vReal");
  */
  // Init vImag and vReal to 0
  for (size_t i = 0; i < FFT_SIZE; i++) {
    vImag[i] = 0;
    vReal[i] = 0;
  }
}


// _______________________________________________________
void KeyWordDetector::generateMelFilterBank() {
  // Generate mel points
  int arraySize = NUM_MEL_FILTER_BANKS+2;
  float* mel = melPoints(MEL_MIN_FREQUENCY, MEL_MAX_FREQUENCY, NUM_MEL_FILTER_BANKS);
  // Calculate frequencies of this mel points
  float* freq = melsToFrequencies(mel, arraySize);
  // Map the frequencies to bins
  frequenciesToBins(melBins, freq, arraySize, FFT_SIZE, SAMPLING_RATE);
   
  #ifdef DEBUG_KD_MEL
    Serial.print("Mel-Scaled Points:\n");
    printV(mel, arraySize, true);
    Serial.print("Mel-Scaled Frequencies:\n");
    printV(freq, arraySize, true);
    Serial.print("FFT Bins:\n");
    printV(melBins, arraySize, true);
  #endif
  
  // Only the melbins are required, free the rest
  free(freq);
  free(mel);
}



// _______________________________________________________
void KeyWordDetector::generateWindowFunction() {
  computeWindow(window, WINDOW_LENGTH, FFT_WIN_TYP_HAMMING);
  
  // Compute window normalisation factors (weighing factors)
  for (int i = 0; i < WINDOW_LENGTH/2; i++){
    windowNormS1 += window[i];
    windowNormS2 += pow(window[i], 2);
  }
  // Multiply by two because we only store half of the window
  windowNormS1 *= 2;
  windowNormS2 *= 2;
  
  // Power spectrum scale is for perfomance resons calculated only once
  powerSpectrumScale = 1.0f;
  //powerSpectrumScale = 2/(pow(windowNormS1, 2));
  
#ifdef DEBUG_KD_WINDOW
  Serial.println("Window:");
  printV(window, WINDOW_LENGTH/2, true);
  Serial.print("Window normalisation: S1: ");
  Serial.print(windowNormS1);
  Serial.print(", S2: ");
  Serial.println(windowNormS2);
  Serial.print("PowerSpectrumScale: ");
  Serial.println(powerSpectrumScale);
#endif
}



// _______________________________________________________
void KeyWordDetector::applyPreemphasis() {
  float thisSignal = 0.0f;
  float lastSignal = 0.0f;
  for (size_t i = 1; i < WINDOW_LENGTH; i++) {
    thisSignal = vReal[i];
    vReal[i] -= lastSignal * A_PREEMPHASIS;
    lastSignal = thisSignal;
  }
}


// _______________________________________________________
void KeyWordDetector::performFFT() {
  // Apply the windowing on the vector
  //applyWindowing(vReal, window, WINDOW_LENGTH, true);
 // Apply the windowing on the vector
 // TODO: Seems to work way better without windowing (but why?)
 /*
 for (int i = 0; i < WINDOW_LENGTH/2; i++) {
    vReal[i] *= window[i];
    vReal[WINDOW_LENGTH - (i + 1)] *= window[i];
 
  } */
 
 
 
  // Padd with 0s at the end if FFT size is not the same as windowLength and reset imaginary vector
  for (size_t i = 0; i < FFT_SIZE; i++) {
    if (i >= WINDOW_LENGTH) vReal[i] = 0;
    vImag[i] = 0;
  }
  
  
  // Compute FFT (is done inPlace)
  computeFFT(vReal, vImag, FFT_SIZE);
  
  
  // Get the magnitude of the complex value (inPlace)
  //complexToMagnitude(vReal, vImag, FFT_SIZE);
  // Get the magnitude of the complex value and store in powerSpec 
  complexToMagnitude(vReal, vImag, powerSpec, FFT_SIZE);
  
  #ifdef DEBUG_KD_MAJOR_FREQUENCY
    // Compute the major peak for DEBUG_KDging
    double peak = majorPeak(vReal, FFT_SIZE, SAMPLING_RATE);
    Serial.print("Major peak at: ");
    Serial.print(peak);
    Serial.println("Hz");
  #endif

  #ifdef DEBUG_KD_FFT
    printV(vReal, FFT_SIZE, false);
    Serial.print("\n");
  #endif
}




// _______________________________________________________
void KeyWordDetector::powerSpectrum() {
  for (size_t i = 0; i < FFT_SIZE/2; i++) {
    // TODO: Why here abs? needed? since e.g. -2*-2 = 4
    powerSpec[i] = powerSpectrumScale*pow(powerSpec[i], 2);
  }
}

// _______________________________________________________
void KeyWordDetector::spectralNoiseGating() {
  for (int i = 0; i < FFT_SIZE/2; i++) {
    if (powerSpec[i] < noiseFloor[i] + NOISE_FLOOR_OFFSET) powerSpec[i] = 0.0f;
  }
}


// _______________________________________________________
void KeyWordDetector::getMFCCs() {
  // First perform the FFT
  performFFT();
  
  // Try to reduce noise by estimated noise floor subtraction
  spectralNoiseGating();
  
  
  // Only half of the powerSpec vector [0-FFT_SIZE/2] now contains relevant information
  
  // Calculate the power spectrum in place
  powerSpectrum();
  
  // Calculate the log mel energies will be size of NUM_MEL_FILTER_BANKS
  melEnergy(logMelEn, powerSpec, FFT_SIZE/2, melBins, NUM_MEL_FILTER_BANKS+2);
  
  
  // Compute the 12 needed mfccs by the adjusted discrete cosine transformation for 26
  performDCT26Unrolled12MFCCs(currentMFCCs, logMelEn, dctCoeff);
  
  
  //printV(logMelEn, 28, true);
  
}

// _______________________________________________________
void KeyWordDetector::noiseFloorCalculation() {
  // Padd with 0s at the end if FFT size is not the same as windowLength and reset imaginary vector
  for (size_t i = 0; i < FFT_SIZE; i++) {
    if (i >= WINDOW_LENGTH) vReal[i] = 0;
    vImag[i] = 0;
  }
  
  // Compute FFT (is done inPlace)
  computeFFT(vReal, vImag, FFT_SIZE);
  
  // Get the magnitude of the complex value (inPlace)
  //complexToMagnitude(vReal, vImag, FFT_SIZE);
  // Get the magnitude of the complex value and store in powerSpec 
  complexToMagnitude(vReal, vImag, powerSpec, FFT_SIZE);
  
  // Update old noise floor value
  for (int i = 0; i < FFT_SIZE/2; i++) {
    noiseFloor[i] = (1.0-NOISE_FLOOR_LOWPASS)*noiseFloor[i] + (NOISE_FLOOR_LOWPASS)*powerSpec[i];
  }
  
}

// _______________________________________________________
bool KeyWordDetector::getNewTemplate() {
  
  // Calculate the energy of this window
  double energy = getShortTimeEnergy(vReal, WINDOW_LENGTH);
  
  #ifdef DEBUG_KD_ENERGY
    Serial.print("Energy: ");
    Serial.println(energy);
  #endif
  
  // If beginning of longTerm energy calculation
  if (longTermEnergy == -1) longTermEnergy = energy;
    
  // If enough energies sampled to update longterm energy, do this
  if (energyIndex > LONGTERM_ENERGY_FRAME_COUNT) {
    longTermEnergy = getMean(energies, LONGTERM_ENERGY_FRAME_COUNT);
    // Reset energy index
    energyIndex = 0;
    #ifdef DEBUG_KD_ENERGY
      Serial.print("NewLongTermEnergy: ");
      Serial.println(longTermEnergy);
    #endif
  }
  
    
  // If energy is above certain threshold we don't have silence any more
  // The template keyword starts here!
  if (energy > (ENERGY_DETECTION_MULTIPLIER_BEGIN*longTermEnergy)) {
    // Store beginning of detection
    if (!activated) {
      // Set startIndex to start indexing
      templateKeywordFrameCount = 0;
      if (DEBUG_KD) Serial.println("Started");
      activated = true;
    }
    // Reset silence counter
    frameSilenceCount = 0;
  // Not enough energy is present
  } else if (energy < (ENERGY_DETECTION_MULTIPLIER_END*longTermEnergy)) {
    // Look if silenced frames is only short or above certain threshold
    if ((frameSilenceCount > FRAME_SILENCE_THRESHOLD)) {
      // Only if voice was present before
      if (activated) {
        if (DEBUG_KD) {
          Serial.print("Template finished, length: ");
          Serial.print(timeIndex(templateKeywordFrameCount, FRAME_LENGTH, SAMPLING_RATE), 3);
          Serial.print("s\n");
        }
        
        // TODO: look for enough phoneme info and so on
        
        // Write mfcc data to SD (overWrite if exist) as next keyword
        if (DEBUG_KD_MORE) printMFCCSequence(templateMFCCs, templateKeywordFrameCount);
        SD_writeMFCCData(numberOfStoredTemplates);
        // Increment number of templates and update shortest and longest template size
        numberOfStoredTemplates++;
        if (templateKeywordFrameCount < shortestTemplateSize)  shortestTemplateSize = templateKeywordFrameCount;
        if (templateKeywordFrameCount > longestTemplateSize)  longestTemplateSize = templateKeywordFrameCount;
                
        // Deactivate and reset
        learnKeyword = false;
        activated = false;
        
        // Indicate succesfully learned template
        if (templateHandlerFunction) templateHandlerFunction(numberOfStoredTemplates-1);
      }
    // If not enough silence frames, increment counter
    } else {
      frameSilenceCount++;
    }
  }
  
   
  // If not activated, update the noise Floor
  if (!activated && energy < (ENERGY_DETECTION_MULTIPLIER_END*longTermEnergy)) {
    noiseFloorCalculation();
    // Put new energy into long term energy array only if no silence
    energies[energyIndex] = energy;
    energyIndex++;
  }
  
  // If the start of the keyword was found perform actions accordingly
  if (activated) {
    // Look if potential keyword is too long
    if (templateKeywordFrameCount > MAX_MFCC_VECTOR_FRAMES) {
      if (DEBUG_KD) {
        Serial.print("Stopped after: ");
        Serial.print(timeIndex(templateKeywordFrameCount, FRAME_LENGTH, SAMPLING_RATE), 3);
        Serial.print("s, because longer than array\n");
      }
      learnKeyword = false;
      // Deactivate and reset
      activated = false;
    }
    
    // Store template energy of frame
    //testEnergies[potentiallKeywordFrameCount] = energy;
    // Apply preemphasis on the window
    //applyPreemphasis();
    // Calculate MFCCs
    getMFCCs();
    storeTemplateMFCCs(templateKeywordFrameCount);
    // Increment frameCounter
    templateKeywordFrameCount++;
    
  }
  return false;
}


// _______________________________________________________
bool KeyWordDetector::testForKeyword() {
  
  // Calculate the energy of this window
  double energy = getShortTimeEnergy(vReal, WINDOW_LENGTH);
  
  #ifdef DEBUG_KD_ENERGY
    Serial.print("Energy: ");
    Serial.println(energy);
  #endif
  
  // If beginning of longTerm energy calculation
  if (longTermEnergy == -1) longTermEnergy = energy;
    
  // If enough energies sampled to update longterm energy, do this
  if (energyIndex > LONGTERM_ENERGY_FRAME_COUNT) {
    longTermEnergy = getMean(energies, LONGTERM_ENERGY_FRAME_COUNT);
    // Reset energy index
    energyIndex = 0;
    #ifdef DEBUG_KD_ENERGY
      Serial.print("NewLongTermEnergy: ");
      Serial.println(longTermEnergy);
    #endif
  }
  
    
  // If energy is above certain threshold we don't have silence any more
  // The potential keyword starts here!
  if (energy > (ENERGY_DETECTION_MULTIPLIER_BEGIN*longTermEnergy)) {
    // Store beginning of detection
    if (!activated && !waitForNextSilence) {
      // Set startIndex to start indexing
      potentiallKeywordFrameCount = 0;
      if (DEBUG_KD) Serial.println("Started");
      activated = true;
    }
    // Reset silence counter
    frameSilenceCount = 0;
  // Not enough energy is present
  } else if (energy < (ENERGY_DETECTION_MULTIPLIER_END*longTermEnergy)) {
    // Look if silenced frames is only short or above certain threshold
    if ((frameSilenceCount > FRAME_SILENCE_THRESHOLD)) {
      // Only if voice was present before
      if (activated) {
        // Look if the potential keyword was way to short
        if ((float)potentiallKeywordFrameCount < (float)(shortestTemplateSize*TEMPLATE_MATCH_LOWER_LENGTH_LIMIT)) {
          // If so reset
          if (DEBUG_KD_MORE) {
            Serial.print("Stopped after: ");
            Serial.print(timeIndex(potentiallKeywordFrameCount, FRAME_LENGTH, SAMPLING_RATE), 3);
            Serial.print("s, because too short\n");
          }
          // Deactivate and reset
          activated = false;
          potentiallKeywordFrameCount = 0;
        // Else is potenitall a keyword, it could be too long
        } else {
          // Make final keyword test
          int keyword = testPotentialKeyword(potentiallKeywordFrameCount);
          // Deactivate and reset
          activated = false;
          potentiallKeywordFrameCount = 0;
          // Return true if keywprd
          if (DEBUG_KD) {
            if (keyword != -1) {
              Serial.print("****************************Keyword ");
              Serial.print(keyword);
              Serial.println(" detected*****************************");
            } else Serial.println("Stopped, no keyword.");
          }
          if (keyword > -1) {
            if (keywordHandlerFunction) keywordHandlerFunction(keyword);
            return true;
          } else {
            return false;
          }
        }
      // If not activated, the voice was too long to be a keyword
      // Waiting for next silence is active
      } else {
        // Reset the wait for next silence
        if (waitForNextSilence) waitForNextSilence = false;
      }
    // If not enough silence frames, increment counter
    } else {
      frameSilenceCount++;
    }
  }
  
  // If not activated, update the noise Floor
  if (!activated && energy < (ENERGY_DETECTION_MULTIPLIER_END*longTermEnergy)) {
    noiseFloorCalculation();
    // Put new energy into long term energy array only if no silence
    energies[energyIndex] = energy;
    energyIndex++;
  }
  
  // If the start of the keyword was found perform actions accordingly
  if (activated) {
    // Look if potential keyword is too long
    if ((float)potentiallKeywordFrameCount > (float)(longestTemplateSize*TEMPLATE_MATCH_UPPER_LENGTH_LIMIT)) {
      
      if (DEBUG_KD_MORE) {
        Serial.print("Stopped after: ");
        Serial.print(timeIndex(potentiallKeywordFrameCount, FRAME_LENGTH, SAMPLING_RATE), 3);
        Serial.print("s, because too long\n");
      }
      // Deactivate and reset
      activated = false;
      potentiallKeywordFrameCount = 0;
      waitForNextSilence = true;
    }
    
    // Store template energy of frame
    //testEnergies[potentiallKeywordFrameCount] = energy;
    // Apply preemphasis on the window
    //applyPreemphasis();
    // Calculate MFCCs
    getMFCCs();
    storeMFCCs(potentiallKeywordFrameCount);
    // Increment frameCounter
    potentiallKeywordFrameCount++;
    
  }
  return false;
}

// _______________________________________________________
int KeyWordDetector::testPotentialKeyword(size_t potentiallKeywordFrameCount) {
  //printMFCCSequence(testMFCCs, potentiallKeywordFrameCount);
  float score = INFINITY;
  int keyword = -1;
 
  // Prepare a vector for the distances of the subword distances
  float distances[NUMBER_OF_DTW_COMPARISONS];
  
  // This must be tested for all availables templates
  // These must be loaded from SD card sequentially since it is not enough memory left to store all
  // template files on mcu
  for (int k = 0; k < numberOfStoredTemplates; k++) {
    // If data was successfully read
    if (SD_readMFCCData(k)) {
      if (DEBUG_KD) {
        Serial.print("Comparison with template: ");
        Serial.println(k);
      }
      if (DEBUG_KD_MORE) {
        Serial.print("Template size: ");
        Serial.print(templateKeywordFrameCount);
        Serial.print("x");
        Serial.println(NUM_MFCCS);
        Serial.print("Potentiall Keyword size: ");
        Serial.print(potentiallKeywordFrameCount);
        Serial.print("x");
        Serial.println(NUM_MFCCS);
      }
  
      // Look if length match is okay for this keyword
      if ((float)potentiallKeywordFrameCount > (float)(templateKeywordFrameCount*TEMPLATE_MATCH_UPPER_LENGTH_LIMIT)) {
        if (DEBUG_KD_MORE) Serial.println("Potential keyword too long for template");
      } else if ((float)potentiallKeywordFrameCount < (float)(templateKeywordFrameCount*TEMPLATE_MATCH_LOWER_LENGTH_LIMIT)) {
        if (DEBUG_KD_MORE) Serial.println("Potential keyword too short for template");
      // Only if lenght matches, do the gifty stuff (DTW)
      } else {
        // Calculate the lengths of one vector sequence used for matching
        // TODO: this will cut serious informatione -> worst case: 129 Frames % 10 = 9*12 values are cut
        int steptemp = templateKeywordFrameCount/(float)NUMBER_OF_DTW_COMPARISONS;
        int steptest = potentiallKeywordFrameCount/(float)NUMBER_OF_DTW_COMPARISONS;
        // Index used to store the distances
        int distanceIndex = 0;
        // Loop over the number of comparisons
        for (int i = 0; i < NUMBER_OF_DTW_COMPARISONS; i++) {
          // Calulate and store ditance and increment index
          distances[distanceIndex] = performDTW(&templateMFCCs[i*steptemp*NUM_MFCCS], steptemp, &testMFCCs[i*steptest*NUM_MFCCS],
                                                steptest, NUM_MFCCS, MAX_DTW_WARPING_DISTANCE);
          distanceIndex++;
        }
        // Calculate the mean distance of all distances
        float meanDistance = getMean(distances, NUMBER_OF_DTW_COMPARISONS);
        if (DEBUG_KD) {
          Serial.print("Mean Distance: ");
          Serial.println(meanDistance);
        }
        // If below threshold this was a match
        if (meanDistance < MATCH_THRESHOLD) {
          if (COMPARE_ALL_KEYWORDS) {
            if (meanDistance < score) {
              score = meanDistance;
              keyword = k;
            } 
          } else {
            return k;
          }
        }
      }
    }
  }
  return keyword;
}


// _______________________________________________________
void KeyWordDetector::storeMFCCs(size_t index) {
  // Get the start index of the mfcc vector
  size_t offset = getMFCCIndex(index);
  // If beyond bounds return
  if ((offset + NUM_MFCCS) > MAX_MFCC_VECTOR_SIZE) return;
  // Else store current vector
  for (size_t i = 0; i < NUM_MFCCS; i++) testMFCCs[offset+i] = currentMFCCs[i];
}

// _______________________________________________________
void KeyWordDetector::storeTemplateMFCCs(size_t index) {
  // Get the start index of the mfcc vector
  size_t offset = getMFCCIndex(index);
  // If beyond bounds return
  if ((offset + NUM_MFCCS) > MAX_MFCC_VECTOR_SIZE) return;
  // Else store current vector
  for (size_t i = 0; i < NUM_MFCCS; i++) templateMFCCs[offset+i] = currentMFCCs[i];
}

// _______________________________________________________
size_t KeyWordDetector::getMFCCIndex(size_t index) {
  return NUM_MFCCS*index;
}

// _______________________________________________________
void KeyWordDetector::printMFCCSequence(float *sequence, size_t size) {
  for (size_t i = 0; i < NUM_MFCCS; i++) {
    for (size_t j = 0; j < size; j++) {
      if (getMFCCIndex(j)+i < MAX_MFCC_VECTOR_SIZE) { 
        Serial.print(sequence[getMFCCIndex(j)+i]);
        Serial.print("\t");
      }
    }
    Serial.print("\n");
  }
}




// _______________________________________________________
void KeyWordDetector::SD_writeFloat(float value) {
  byte* p = (byte*)(void*)&value;
  for (size_t i = 0; i < sizeof(value); i++) {
    templateDataFile.write(*p++);
  }
}

// _______________________________________________________
float KeyWordDetector::SD_readFloat() {
  float value = 0.0;
  byte* p = (byte*)(void*)&value;
  for (size_t i = 0; i < sizeof(value); i++) {
    *p++ = templateDataFile.read();
  }
  return value;
}

// _______________________________________________________
void KeyWordDetector::SD_writeInt(int value) {
  byte* p = (byte*)(void*)&value;
  for (size_t i = 0; i < sizeof(value); i++) {
    templateDataFile.write(*p++);
  }
}

// _______________________________________________________
int KeyWordDetector::SD_readInt() {
  int value = 0;
  byte* p = (byte*)(void*)&value;
  for (size_t i = 0; i < sizeof(value); i++) {
    *p++ = templateDataFile.read();
  }
  return value;
}

// _______________________________________________________
bool KeyWordDetector::SD_writeMFCCData(int fileNumber) {
  // Get the filename beginning
  char fileName[15] = FILENAME;
  // The number to append to the filename (e.g. MFCCs_3) 
  // Is is not allowed to exceed 99
  char fileNum[3];
  
  // Get the index where to append the filenumber
  int appendAtIndex = sizeof(FILENAME)-1;
  // Safety check, that filename is large enough to hold characters
  if (appendAtIndex > -1 && appendAtIndex < (int)sizeof(fileName)) {
    sprintf(fileNum, "%i", fileNumber);
  } else {
    Serial.println("Error with append index.");
    return false;
  }
  
  strcat(fileName, fileNum);
  strcat(fileName, FILEENDING);
  
  if (DEBUG_KD_MORE) {
    Serial.print("Try to open file: ");
    Serial.print(fileName);
    Serial.println(", to write new template mfcc data");
  }
  // If file already exist, remove it first
  if (SD.exists(fileName)) {
    SD.remove(fileName);
    Serial.println("Delete old template data.");
  }
  // Get the length of the data to write
  size_t size = templateKeywordFrameCount*NUM_MFCCS;
  if (DEBUG_KD_MORE) {
    Serial.print("Size of MFCC data: ");
    Serial.println(size);
  }
    
  // Open SD file for writing
  templateDataFile = SD.open(fileName, FILE_WRITE);
  
  // If the file opened okay, write to it
  if (templateDataFile) {
    if (DEBUG_KD_MORE) {
      Serial.print("Writing to ");
      Serial.println(fileName);
    }
    // The first bytes will be the size of the mfcc data
    SD_writeInt((int)size);
    // Appand the data 
    for (size_t i = 0; i < size; i++) {
      SD_writeFloat(templateMFCCs[i]);
      if (DEBUG_KD_MORE) {
        Serial.print(templateMFCCs[i]);
        Serial.print(" ");
      }  
    }
    // Close file
    templateDataFile.close();
    if (DEBUG_KD_MORE) Serial.println("done.");
    return true;
  } else {
    // If the file didn't open, print an error:
    if (DEBUG_KD_MORE) Serial.println("error opening file");
    return false;
  }
}


// _______________________________________________________
bool KeyWordDetector::SD_readMFCCData(int fileNumber) {
  // Get the filename beginning
  char fileName[15] = FILENAME;
  // The number to append to the filename (e.g. MFCCs_3) 
  // Is is not allowed to exceed 99
  char fileNum[3];
  
  // Get the index where to append the filenumber
  int appendAtIndex = sizeof(FILENAME)-1;
  // Safety check, that filename is large enough to hold characters
  if (appendAtIndex > -1 && appendAtIndex < (int)sizeof(fileName)) {
    sprintf(fileNum, "%i", fileNumber);
  } else {
    Serial.println("Error with append index.");
    return false;
  }
  
  strcat(fileName, fileNum);
  strcat(fileName, FILEENDING);
  
  if (DEBUG_KD_MORE) {
    Serial.print("Try to open file: ");
    Serial.print(fileName);
    Serial.println(", to read stored template mfcc data");
  }
  // Open the file for reading:
  templateDataFile = SD.open(fileName);
  // If the file is opened successfully
  if (templateDataFile) {
    if (DEBUG_KD_MORE) Serial.println(fileName);
    // Get the size of the data
    size_t size = 0;
    if (templateDataFile.available()) {
      size = (size_t)SD_readInt();
    } else {
      // If the file is not containing data print error and return 
      if (DEBUG_KD_MORE) Serial.println("error reading data");
      return false;
    }
    if (DEBUG_KD_MORE) {
      Serial.print("Size of MFCC data: ");
      Serial.println(size);
    }
    // Delete old data and allocate new space
    //free(testData);
    templateKeywordFrameCount = 0;
    //testData = (float*)malloc(size*(sizeof(float)));
    
    // Read from the file until there's nothing else or the array is full
    size_t i = 0;
    while (templateDataFile.available()) {
      templateMFCCs[i] = SD_readFloat();
      i++;
      // Break on full array
      if (i > size || i > MAX_MFCC_VECTOR_SIZE) break;
    }
    // Store number of frames
    templateKeywordFrameCount = i/NUM_MFCCS;
    // Close the file after reading and return success
    templateDataFile.close();
    return true;
  } else {
    // If the file didn't open, print an error and return false
    if (DEBUG_KD_MORE) Serial.println("error opening file");
    return false;
  }
}

