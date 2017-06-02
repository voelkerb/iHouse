//
//  signal.h
//  MFCC
//
//  Created by Benjamin Völker on 05/10/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#ifndef signal_h
#define signal_h

#if defined(ARDUINO) && ARDUINO >= 100
  #include "Arduino.h"
#else
  #include "WProgram.h"
#endif


/**
 * Swaps to given floats
 * @param float *x, the first value to be swaped 
 * @param float *y, the second value to be swaped
 */
void Swap(float *x, float *y) {
  float temp = *x;
  *x = *y;
  *y = temp;
}

/**
 * Will order a given value in an aray.
 * @param float *input, an input array
 * @param int p, the start index for partitioning
 * @param int r, the stop index for paritioning
 * @return int, the index of the value ordered
 */
int partition(float *input, int p, int r) {
  float pivot = input[r];
  while (p < r) {
    while (input[p] < pivot) p++;
    while (input[r] > pivot) r--;
    if (input[p] == input[r]) p++;
    else if (p < r) {
      float tmp = input[p];
      input[p] = input[r];
      input[r] = tmp;
    }
  }
  return r;
}

/**
 * Will select the kth element in a sorted array
 * @param float *input, an input array
 * @param int p, the start index for partitioning
 * @param int r, the stop index for paritioning
 * @param int k, the k'th elemnt in the sorted lust
 * @return float, the k'th value of the sorted array
 */
float quick_select(float *input, int p, int r, int k) {
  // If the index of p and r are equal
  if ( p == r ) return input[p];
  int j = partition(input, p, r);
  int length = j - p + 1;
  if ( length == k ) return input[j];
  else if ( k < length ) return quick_select(input, p, j - 1, k);
  else  return quick_select(input, j + 1, r, k - length);
}

/**
 * Calculates the median value of the vector
 * @param vector<int> theVector, the source vector
 * @return long, the mean of the vector
 */
float getMedian(float *theVector, size_t size) {
  return quick_select(theVector, 0, size - 1, size/2);
}

/**
 * Calculates the mean value of the vector
 * @param vector<float> theVector, the source vector
 * @return long, the mean of the vector
 */
float getMean(float *theVector, size_t size) {
  float mean = 0;
  // Mean = sum/size
  for (size_t i = 0; i < size; i++) {
    mean += theVector[i];
  }
  mean /= (float)size;
  return mean;
}

/**
 * Calculates the mean value of the vector
 * @param vector<float> theVector, the source vector
 * @return long, the mean of the vector
 */
float getMean(short *theVector, size_t size) {
  long mean = 0;
  // Mean = sum/size
  for (size_t i = 0; i < size; i++) {
    mean += theVector[i];
  }
  mean /= size;
  return mean;
}


/**
 * Calculates the mean value of the vector
 * @param vector<int> theVector, the source vector
 * @return long, the mean of the vector
 */
long getMean(int *theVector, size_t size) {
  unsigned long mean = 0;
  // Mean = sum/size
  for (size_t i = 0; i < size; i++) {
    mean += theVector[i];
  }
  mean /= size;
  return mean;
}



/**
 * Calculates the Energy value of the vector
 * @param vector<float> theVector, the source vector
 * @return float, the energy of the vector
 */
float getShortTimeEnergy(float *theVector, size_t size) {
  float energy = 0;
  // Energy = sum(value^2)/size
  for (size_t i = 0; i < size; i++) {
    energy += theVector[i]*theVector[i];
  }
  energy /= (float)size;
  return energy;
}



/**
 * Calculates the Energy value of the vector
 * @param vector<float> theVector, the source vector
 * @return float, the energy of the vector
 */
float getShortTimeEnergy(short *theVector, size_t size) {
  float energy = 0;
  // Energy = sum(value^2)/size
  for (size_t i = 0; i < size; i++) {
    energy += theVector[i]*theVector[i];
  }
  energy /= (float)size;
  return energy;
}


/**
 * Calculates the number of zero-crossings in the vector
 * @param vector<float> theVector, the source vector
 * @return long, the number of zero-crossings
 */
long getZeroCrossingRate(float *theVector, size_t size) {
  unsigned long zcr = 0;
  // The for-loop starts from 1 to Size and looks at i-1 and i
  for (size_t i = 1; i < size; i++) {
    // Zero crossing if either less 0 before and greater zero now
    if (theVector[i-1] < 0 && theVector[i] > 0) zcr++;
    // or greater zero before and less zero now
    else if(theVector[i-1] > 0 && theVector[i] < 0) zcr++;
  }
  return zcr;
}
/**
 * Calculates the number of zero-crossings with offset in the vector
 * @param vector<float> theVector, the source vector
 * @return long, the number of zero-crossings
 */
long getZeroCrossingRateWithOffset(float *theVector, size_t size, int offsetFromZero) {
  unsigned long zcr = 0;
  // The for-loop starts from 1 to Size and looks at i-1 and i
  for (size_t i = 1; i < size; i++) {
    // Zero crossing if either less 0 before and greater zero now
    if (theVector[i-1] < 0 && theVector[i] > 0) {
      if (fabs(theVector[i-1] - theVector[i]) > offsetFromZero) zcr++;
    }
    // or greater zero before and less zero now
    else if(theVector[i-1] > 0 && theVector[i] < 0) {
      if (fabs(theVector[i-1] - theVector[i]) > offsetFromZero) zcr++;
    }
  }
  return zcr;
}

/**
 * Calculates the time index for a given vector index
 * @param int index, the index of the vector
 * @param int Fs, the samlingRate
 * @return float, time index
 */
float timeIndex(int index, int Fs) {
  return (float)index/(float)(Fs);
}


/**
 * Calculates the time index for a given frame number
 * @param int frameIndex, the index of the frame
 * @param int frameLength, the length of a frame
 * @param int Fs, the samplingRate
 * @return float, time index
 */
float timeIndex(int frameIndex, int frameLength, int Fs) {
  return timeIndex(frameIndex*frameLength, Fs);
}

#endif /* signal_h */
