//
//  vectorMatrixFunctions.h
//  DTW
//
//  Created by Benjamin Völker on 07/10/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#ifndef vectorMatrixFunctions_h
#define vectorMatrixFunctions_h

#if defined(ARDUINO) && ARDUINO >= 100
  #include "Arduino.h"
#else
  #include "WProgram.h"
#endif

#include <math.h>
#include <vector>
using namespace std;

//#define DEBUG_DTW

float *dtwMatrix;
size_t xDim;
size_t yDim;

/**
 * Returns the index to access data in the matrixVector
 * @param size_t x, row of matrix
 * @param size_t y, column of matrix
 * @return size_t, index in matrixvector
 */
size_t getDataIndex(size_t x, size_t y) {
  return (x * yDim) + y;
}


/**
  * Prints the Matrix to the console
  */
void printDTWMatrix() {
  for (size_t i = 0; i < xDim; i++) {
    for (size_t j = 0; j < yDim; j++) {
      Serial.print(dtwMatrix[getDataIndex(i, j)]);
      Serial.print("\t");
    }
    Serial.print("\n");
  }
}


/**
 * Calculate the euclidean distance between two vectors that must be of the same size
 * @param float* vector1, first vector
 * @param float* vector2, second vector
 * @return float, euclidean distance between the two vectors
 */
float euclideanDistance(float *vector1, float *vector2, size_t size) {
  float distance = 0.0;
  // Calculate the eucleadian distance iteratively
  for (size_t i = 0; i < size; i++) {
    distance += pow((vector1[i] - vector2[i]), 2);
  }
  return sqrt(distance);
}

/**
 * Returns the minum value of three floats
 * @param float a, first number
 * @param float b, second number
 * @param float c, third number
 * @return float, miminum of a,b,c
 */
float minOf3(float a, float b, float c) {
  if((a < b) && (a < c)) {
   return a;
  } else if((b < a) && (b < c)) {
   return b;
  } 
  return c;
}


/**
 * Inits the matrix where the dtw cost values are stored in
 * @param size_t xSize, # rows of matrix
 * @param size_t ySize, # columns of matrix
 */
void initMatrix(size_t xSize, size_t ySize) {
  xDim = xSize + 1;
  yDim = ySize + 1;
  
  // Construct DTW and fill with 0s
  dtwMatrix = (float*)malloc((xDim * yDim)*(sizeof(float)));
  if (dtwMatrix == NULL) Serial.println("not enough memory left for DTW");
  
  for (size_t i = 0; i < (xDim * yDim); i++) {
    dtwMatrix[i] = 0;
  }
  
  // Set Matrix starting values
  dtwMatrix[getDataIndex(0, 0)] = 0.0;
  for (size_t i = 1; i < xDim; i++) {
    dtwMatrix[getDataIndex(i, 0)] = INFINITY;
  }
  for (size_t i = 1; i < yDim; i++) {
    dtwMatrix[getDataIndex(0, i)] = INFINITY;
  }
}



/**
 * Returns the index to access data in the matrixVector
 * @param float* sequence1, the first input sequence used for dtw calculation
 * @param size_t seq1Size, the length of the first input sequence
 * @param float* sequence2, the second input sequence used for dtw calculation
 * @param size_t seq2Size, the length of the second input sequence
 * @param size_t seqVectorSize, the size of one element in the sequence, this must
 * be the same for both input sequences, otherwise the euclidian distance of the two vectors (or one scalar)
 * can not be computed
 * @param int radius, the radius for which distance is calculated. This parameter ensures a reasonable Warping Window,
 * since a good alignment path is unlikely to wander too far from the Matrix diagonal. Radius is the distance from this diagonal.
 * Guarantees that the alignment does not try to skip different features and gets stuck at similar features.
 * @return float, the overall distance of the two sequences
 */
float performDTW(float* sequence1, size_t seq1Size, float* sequence2, size_t seq2Size, size_t seqVectorSize, int radius) {
  initMatrix(seq1Size, seq2Size);
  // Compute DTW cost for the two sequences
  for (size_t i = 1; i <= seq1Size; i++) {
    for (size_t j = 1; j <= seq2Size; j++) {
      if ((int)i >= (int)(j - radius) && (int)i <= (int)(j + radius)) {
        // Calculate the euclidean distance
        float costIndex = euclideanDistance(&sequence1[(i - 1)*seqVectorSize], &sequence2[(j - 1)*seqVectorSize], seqVectorSize);
        float costPath = 0.0;
        // Get the three neighboring values from the matrix to use for the update
        if (i == (j - radius) || i == (j + radius)) {
          costPath = dtwMatrix[getDataIndex(i - 1, j - 1)];
        } else {
          float iStepj = dtwMatrix[getDataIndex(i - 1, j)];
          float iStepjSep = dtwMatrix[getDataIndex(i - 1, j - 1)];
          float ijStep = dtwMatrix[getDataIndex(i, j - 1)];
          // Start the update step
          costPath = minOf3(iStepj, iStepjSep, ijStep);
        }
        
        // Update the cost value in the matrix
        dtwMatrix[getDataIndex(i, j)] = costIndex + costPath;
      }
    }
  }
  // Result is last entry in DTW matrix scaled by the size of the two sequences
  double overallDistance = dtwMatrix[getDataIndex(seq1Size, seq2Size)]/(float)(seq1Size + seq2Size);
  
  #ifdef DEBUG_DTW
    printDTWMatrix();
  #endif
  // Free the memory of matrix created
  free(dtwMatrix);
  
  // Return total path costs for the best path through the matrix
  return overallDistance;
}

/**
 * Returns the index to access data in the matrixVector
 */
float performDTW(float* sequence1, size_t seq1Size, float* sequence2, size_t seq2Size, size_t seqVectorSize) {
  return performDTW(sequence1, seq1Size, sequence2, seq2Size, seqVectorSize, seq1Size);
}





#endif /* vectorMatrixFunctions_h */
