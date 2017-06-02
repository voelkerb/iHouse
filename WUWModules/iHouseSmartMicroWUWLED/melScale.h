//
//  MelScale.h
//  MFCC
//
//  Created by Benjamin Völker on 05/10/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#ifndef melScale_h
#define melScale_h

#if defined(ARDUINO) && ARDUINO >= 100
  #include "Arduino.h"
#else
  #include "WProgram.h"
#endif



/**
 * Converts a given frequency to mel scale
 * @param float frequency, Frequency in Hz
 * @return float frequency converted to Mel scale
 */
float frequencyToMel(float frequency) {
  return 1125*log(1+frequency/700.0);
}

/**
 * Converts a given mel scale value to the corresponding frequency
 * @param float mel, Mel-scale value
 * @return float frequency converted
 */
float melToFrequency(float mel) {
  return 700*(exp(mel/1125.0) - 1);
}

/**
 * Converts a given frequency to the corresponding fft bin
 * @param float freq, Frequency to convert
 * @param int fftSize, the size of the FFT (not halfSize)
 * @param int sampleRate, the sampling rate of the FFT
 * @return int FFT bin that correspond to give frequency
 */
int frequencyToBin(float freq, int fftSize, float sampleRate) {
  // Round this down, since bins are integer domain
  return (int)floor((fftSize+1)*freq/sampleRate);
}


/**
 * Converts a given mel scale vector to the corresponding frequency vector
 * @param float *mel, Mel-scale vector
 * @param size_t size, size of the Mel-scale vector
 * @return float* frequency vector
 */
float* melsToFrequencies(float *mel, size_t size) {
  float *freq = (float*)malloc(size*(sizeof(float)));
  if (freq == NULL) {
    Serial.println("No Memory left");
    return freq;
  }
  for (size_t i = 0; i < size; i++) {
    freq[i] = melToFrequency(mel[i]);
  }
  return freq;
}


/**
 * Converts a given frequncy vector to the corresponding mel-scale vector
 * @param float *freq, frequency vector
 * @param size_t size, size of the frequency vector
 * @return float* frequency vector
 */
float* frequenciesToMels(float *freq, size_t size) {
  float *mel = (float*)malloc(size*(sizeof(float)));
  if (mel == NULL) {
    Serial.println("No Memory left");
    return mel;
  }
  for (size_t i = 0; i < size; i++) {
    mel[i] = frequencyToMel(freq[i]);
  }
  return mel;
}

/**
 * Converts a given frequency vector to the corresponding fft-bins
 * @param float *freq, frequency vector
 * @param size_t freqSize, size of the frequency vector
 * @param int fftSize, the size of the FFT (not halfSize)
 * @param int sampleRate, the sampling rate of the FFT
 * @return int* fft_bins vector
 */
int* frequenciesToBins(float *freq, size_t freqSize, int fftSize, int sampleRate) {
  int *bins = (int*)malloc(freqSize*(sizeof(int)));
  if (bins == NULL) {
    Serial.println("No Memory left");
    return bins;
  }
  for (size_t i = 0; i < freqSize; i++) {
    bins[i] = frequencyToBin(freq[i], fftSize, sampleRate);
  }
  return bins;
}

/**
 * Converts a given frequency vector to the corresponding fft-bins
 * @param int *bins, the fft bin vector the result is stored in
 * @param float *freq, frequency vector
 * @param size_t freqSize, size of the frequency vector
 * @param int fftSize, the size of the FFT (not halfSize)
 * @param int sampleRate, the sampling rate of the FFT
 */
void frequenciesToBins(int *bins, float *freq, size_t freqSize, int fftSize, int sampleRate) {
  for (size_t i = 0; i < freqSize; i++) {
    bins[i] = frequencyToBin(freq[i], fftSize, sampleRate);
  }
}

/**
 * Creates melScale points needed for creating filter banks.
 * @param float minFreq, the lowest frequency of the mel bank
 * @param float maxFreq, the uppest frequency of the mel bank
 * @param int numbOfMelFilterBanks, the number of of filterbanks used
 * @return float* vector with mel-scaled frequencies of the size: numbOfMelFilterBanks
 */
float* melPoints(float minFreq, float maxFreq, size_t numbOfMelFilterBanks) {
  // Since we need 2 additional point to create a filter bank of size: numbOfMelFilterBanks  
  float *melFreq = (float*)malloc((numbOfMelFilterBanks+2)*(sizeof(float)));
  if (melFreq == NULL) {
    Serial.println("No Memory left");
    return melFreq;
  }
  // Set the min and max frequencies
  melFreq[0] = frequencyToMel(minFreq);
  melFreq[numbOfMelFilterBanks+1] = frequencyToMel(maxFreq);
  // Linear map all other points
  float linearSpacer = (melFreq[numbOfMelFilterBanks+1] - melFreq[0])/(numbOfMelFilterBanks + 1);
  for (size_t i = 1; i < numbOfMelFilterBanks+1; i++) {
    melFreq[i] = melFreq[i-1] + linearSpacer;
  }
  return melFreq;
}


/**
 * Maps the given values to a triangle function.
 * NOTE: Be sure that triangle start-stop.mid are all different!
 * @param int k, the independet variable of the function
 * @param int triangleStart, the start x coordinate of the triangle -> still 0
 * @param int triangleMid, the mid x coordinate of the triangle -> 1
 * @param int triangleEnd, the end x coordinate of the triangle -> again 0
 * @return float a value element (0.0:1.0) dependent of K
 */
float triangleValue(int k, int triangleStart, int triangleMid, int triangleEnd) {
  /*              /\
   *             /  \
   * Case __*___/    \______
   */
  if (k < triangleStart) return 0.0f;
  /*              /\
   *             *  \
   * Case ______/    \______
   */
  if (k <= triangleMid) return (float)((float)(k-triangleStart)/(float)(triangleMid-triangleStart));
  /*              /\
   *             /  *
   * Case ______/    \______
   */
  if (k <= triangleEnd) return (float)((float)(triangleEnd - k)/(float)(triangleEnd-triangleMid));
  /*              /\
   *             /  \
   * Case ______/    \___*__
   */
  return 0.0f;
}

/**
 * Calculates the mel energy from a power Spectrum and the corresponding melBins
 * @return float* melEnergy, logarithm of the melScaled Energy of the Power Spectrum that will be returned
 * @param float> *powerSpectrum, the PS of a Signal
 * @param size_t powerSpectrumSize, the size of the power spectrum
 * @param int *melBins, the bins at which the melScaling is applied
 * @param size_t melBinsSize, the size of the melbin array
 */
void melEnergy(float *melEnergy, float *powerSpectrum, size_t powerSpectrumSize, int *melBins, size_t melBinsSize) {
  // Index for the melEnergy array
  int index = 0;
  //  Loop over the number of melFilters 1 - (sizeOfMelBins-1)
  for (size_t i = 1 ; i < (melBinsSize - 1); i++) {
    // For each bin in bettween the melBins, compute the triangleValue of the melfilter and multiply this with the power spectrum
    // to get the mel filter power spectrum for this melfilter number.
    int a1 = melBins[i-1];
    int a2 = melBins[i];
    int a3 = melBins[i+1];
    for (int j = a1; j < a3; j++) {
      // Sum all values to get the energy
      melEnergy[index] += powerSpectrum[j]*triangleValue(j, a1, a2, a3);
    }
    // Apply the logarithm to the energy since humans hear soundVolume not linear but logarithmic
    // TODO: Crashed here sometimes 
    // Fixed by looking for zero with offset
    if (melEnergy[index] > 0.001f) {
      melEnergy[index] = (float)log(melEnergy[index]);
    }
    index++;
  }
}

#endif /* MelScale_h */
