//
//  arrayFunctions.h
//  MFCC
//
//  Created by Benjamin Völker on 05/10/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#ifndef arrayFunctions_h
#define arrayFunctions_h

#if defined(ARDUINO) && ARDUINO >= 100
  #include "Arduino.h"
#else
  #include "WProgram.h"
#endif


/**
 * Prints a vector to the console.
 * @param <class T> *vector, the vector to be print
 * @param int size_t length, the length of the vetor
 * @param bool index, if the vector should be printed with a leading index
 */
template <class T> void printV( T *vector, size_t length, bool index) {
  for (size_t i = 0; i < length; i++) {
    if (index) {
      Serial.print(i);
      Serial.print("\t");
    }
    Serial.println(vector[i]);
  }
}



/**
 * Get the subvector of a given vector by position and length
 * @param int *sourceVector, the big vector
 * @param int position, the position from where to begin
 * @param int length, the length of the subvector
 * @return int*, the subvector is returned
 */
int* getSubVector(int *sourceVector, size_t size, int position, int length) {
  // Allocate the window
  int *aWindow = (int*)malloc((length)*(sizeof(int)));
  for (int i = 0; i < length; i++) {
    // Pad vector with 0s at the end if sourcevector is too small
    if ((size_t)(position + i) > size) aWindow[i] = 0;
    else aWindow[i] = sourceVector[position + i];
  }
  return aWindow;
}

/**
 * Get the subvector of a given vector by position and length
 * @param float *sourceVector, the big vector
 * @param int position, the position from where to begin
 * @param int length, the length of the subvector
 * @return float*, the subvector is returned
 */
float* getSubVector(float *sourceVector, size_t size, size_t position, size_t length) {
  // Allocate the window
  float *aWindow = (float*)malloc((length)*(sizeof(float)));
  
  for (size_t i = 0; i < length; i++) {
    // Pad vector with 0s at the end if sourcevector is too small
    if ((size_t)(position + i) > size) aWindow[i] = 0;
    else aWindow[i] = sourceVector[position + i];
  }
  return aWindow;
}


#endif /* arrayFunctions_h */
