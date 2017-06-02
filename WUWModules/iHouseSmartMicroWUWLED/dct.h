//
//  dct.h
//  MFCC
//
//  Created by Benjamin Völker on 07/10/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#ifndef dct_h
#define dct_h

#if defined(ARDUINO) && ARDUINO >= 100
  #include "Arduino.h"
#else
  #include "WProgram.h"
#endif

#include <math.h>
#include <stdlib.h>



// Sine Lookup table
const float SIN_TABLE[181] = {
  0.000000, 0.008727, 0.017452, 0.026177, 0.034899, 0.043619, 0.052336, 0.061049, 0.069756, 0.078459, 0.087156, 0.095846, 0.104528,
  0.113203, 0.121869, 0.130526, 0.139173, 0.147809, 0.156434, 0.165048, 0.173648, 0.182236, 0.190809, 0.199368, 0.207912, 0.216440,
  0.224951, 0.233445, 0.241922, 0.250380, 0.258819, 0.267238, 0.275637, 0.284015, 0.292372, 0.300706, 0.309017, 0.317305, 0.325568,
  0.333807, 0.342020, 0.350207, 0.358368, 0.366501, 0.374607, 0.382683, 0.390731, 0.398749, 0.406737, 0.414693, 0.422618, 0.430511,
  0.438371, 0.446198, 0.453990, 0.461749, 0.469472, 0.477159, 0.484810, 0.492424, 0.500000, 0.507538, 0.515038, 0.522499, 0.529919,
  0.537300, 0.544639, 0.551937, 0.559193, 0.566406, 0.573576, 0.580703, 0.587785, 0.594823, 0.601815, 0.608761, 0.615661, 0.622515,
  0.629320, 0.636078, 0.642788, 0.649448, 0.656059, 0.662620, 0.669131, 0.675590, 0.681998, 0.688355, 0.694658, 0.700909, 0.707107,
  0.713250, 0.719340, 0.725374, 0.731354, 0.737277, 0.743145, 0.748956, 0.754710, 0.760406, 0.766044, 0.771625, 0.777146, 0.782608,
  0.788011, 0.793353, 0.798636, 0.803857, 0.809017, 0.814116, 0.819152, 0.824126, 0.829038, 0.833886, 0.838671, 0.843391, 0.848048,
  0.852640, 0.857167, 0.861629, 0.866025, 0.870356, 0.874620, 0.878817, 0.882948, 0.887011, 0.891007, 0.894934, 0.898794, 0.902585,
  0.906308, 0.909961, 0.913545, 0.917060, 0.920505, 0.923880, 0.927184, 0.930418, 0.933580, 0.936672, 0.939693, 0.942641, 0.945519,
  0.948324, 0.951057, 0.953717, 0.956305, 0.958820, 0.961262, 0.963630, 0.965926, 0.968148, 0.970296, 0.972370, 0.974370, 0.976296,
  0.978148, 0.979925, 0.981627, 0.983255, 0.984808, 0.986286, 0.987688, 0.989016, 0.990268, 0.991445, 0.992546, 0.993572, 0.994522,
  0.995396, 0.996195, 0.996917, 0.997564, 0.998135, 0.998630, 0.999048, 0.999391, 0.999657, 0.999848, 0.999962, 1.000000
};

/**
 * Fast cosine calculation.
 * @param int deg, the angle as integer in degree
 * @return float, result
 */
float fcos(int deg){
  float result = 0;
  if (deg < 0) deg = -deg;
  // Map to 0-360deg
  while (deg > 3600)  deg -= 3600;
  // 0 and 90 degrees.
  if ( (deg >= 0) && (deg <= 900) ) {
    result = SIN_TABLE[(900-deg)/5];
  // 90 and 180 degrees.
  } else if ( (deg > 900) && (deg <= 1800) ) {
    result = -SIN_TABLE[(deg - 900) / 5];
  // 180 and 270 degrees.
  } else if ( (deg > 1800) && (deg <= 2700) ) {
    result = -SIN_TABLE[(deg - 2700) / 5];
  } else {
    result = SIN_TABLE[(deg - 2700) / 5];
  }
  return result;
}

/**
 * Fast cosine calculation.
 * @param float x, the angle in radian
 * @return float, result
 */
float cosA(float x) {
  // Map value to 0-360deg (0-Pi)
  x = fmodf(x, M_PI);
  // Cosine(x) is sine(x+pi/2)
  x += 1.57079632;
  // If value is beyond pi now, map it back
  if (x > 3.14159265)  x -= 6.28318531;
  // Compute the aproximation of the cosine by a second order taylor approximation
  if (x < 0)  return 1.27323954 * x + 0.405284735 * x * x;
  else return 1.27323954 * x - 0.405284735 * x * x;
}

/**
 * Fast cosine calculation.
 * @param float x, the angle in radian
 * @return float, result
 */
float cosA2(float x) {
  // Map value to 0-360deg (0-Pi)
  x = fmodf(x, M_PI);
  // Cosine(x) is sine(x+pi/2)
  x += M_PI/2;
  // If value is beyond pi now, map it back
  if(x > M_PI)   {
    x -= 2 * M_PI;
  }
  
  // Compute the aproximation of the cosine by a second order taylor approximation
  const float B = 4/M_PI;
  const float C = -4/(M_PI*M_PI);
  float y = B * x + C * x * abs(x);
  // If you want to have extra precision, compute third order taylor
  #ifdef EXTRA_PRECISION
    const float P = 0.225;
    y = P * (y * abs(y) - y) + y;
  #endif
  return y;
}

/**
 * Will compare discrete cosine transformations with different cosine implementations
 * @param float *c, the vector in which the result will be stored in
 * @param float *data, the vector of the data that will be transformed
 * @param size_t size, the size of the data and result vector
 */
void dctTest(float *c, float *data, size_t size) {
  // Test correctness 
  float theAngle = random(60000)*M_PI/360.0;
  float arduinoCosine = cos(theAngle);
  float approxCosine = cosA(theAngle);
  float approx2Cosine = cosA2(theAngle);
  float lutCosine = cosf((int)(1800*theAngle/M_PI));
  // The different cosine calculations will be displayed here
  Serial.print("Arduino cosine: ");
  Serial.println(arduinoCosine);
  Serial.print("LUT cosine: ");
  Serial.println(lutCosine);
  Serial.print("Approx cosine: ");
  Serial.println(approxCosine);
  Serial.print("Approx2 cosine: ");
  Serial.println(approx2Cosine);
  
  // Test the DCT with the arduino cosine implementation
  // Arduino implementation requires radian angle to be passed to cosine function
  // Is incredible slow one cosine call is approx 43us
  float scale = sqrt (2.0/(float)(size));
  float angle;  
  long cosineTime = 0;
  elapsedMicros time = 0;
  for (size_t i = 0; i < size; i++ ) {
    c[i] = 0.0;
    for (size_t j = 0; j < size; j++ ) {
      angle = (M_PI*(float) (i*(2*j + 1))/(float)(2*size));
      c[i] += cos(angle) * data[j];
    }
    c[i] *= scale;
  }
  cosineTime = time;
  Serial.print("Arduino cos took: ");
  Serial.print(cosineTime);
  Serial.println("us to compute.");
  
  
  // Test the DCT with the LUT cosine implementation
  // LUT requires cosine in deg (rad*180/M_PI)
  // Is incredible slow as well
  time = 0;
  for (size_t i = 0; i < size; i++ ) {
    c[i] = 0.0;
    for (size_t j = 0; j < size; j++ ) {
      angle = ((float) (i*(2*j + 1))/(float)(2*size));
      c[i] += cos((int)(1800*angle)) * data[j];
    }
    c[i] *= scale;
  }
  cosineTime = time;
  Serial.print("LUT cos took: ");
  Serial.print(cosineTime);
  Serial.println("us to compute.");
  
  
  
  // Test the DCT with the cosine Approximation implementation
  // Angle must be in rad
  // Is approx 3 times faster than above methodes
  time = 0;
  for (size_t i = 0; i < size; i++ ) {
    c[i] = 0.0;
    for (size_t j = 0; j < size; j++ ) {
      angle = (M_PI * (float) (i*(2*j + 1))/(float)(2*size));
      c[i] += cosA(angle) * data[j];
    }
    c[i] *= scale;
  }
  cosineTime = time;
  Serial.print("Approx cos took: ");
  Serial.print(cosineTime);
  Serial.println("us to compute.");
  
    
  // Test the DCT with the cosine Approximation implementation #2
  // Angle must be in rad
  // Is approx 3 times faster than above methodes and the fastest tested method
  time = 0;
  for (size_t i = 0; i < size; i++ ) {
    c[i] = 0.0;
    for (size_t j = 0; j < size; j++ ) {
      angle = (M_PI * (float) (i*(2*j + 1))/(float)(2*size));
      c[i] += cosA2(angle) * data[j];
    }
    c[i] *= scale;
  }
  cosineTime = time;
  Serial.print("Approx 2 cos took: ");
  Serial.print(cosineTime);
  Serial.println("us to compute.");
  
}

/**
 * Performs a discrete cosine transformation on the data.
 * The DCT of a sequence returns the coefficients for approximating this sequence by
 * multiple cosine
 * @param float *data, the data on which the transformation is applied
 * @param size_t size, the size of the data
 * @return float*, the result vetor which is allocated
 */
float* performDCT(float *data, size_t size) {
  // Compute the scale only once
  float scale = sqrt (2.0/(float)(size));
  float angle;
  // Allocate result vector
  float *c = (float*)malloc((size)*(sizeof(float)));
  // Go in N^2 over data
  for (size_t i = 0; i < size; i++ ) {
    c[i] = 0.0;
    for (size_t j = 0; j < size; j++ ) {
      // Compute angle depending of point in array
      angle = M_PI * (float) (i*(2*j + 1))/(float)(2*size);
      // Multiplicate data with cosine and add it to result
      c[i] += cos(angle) * data[j]; 
    }
    // Scale result
    c[i] = c[i] * scale;
  }
  return c;
}


/**
 * Performs a discrete cosine transformation on the data.
 * The DCT of a sequence returns the coefficients for approximating this sequence by
 * multiple cosine
 * @param float *c, the coefficients of the dct are stored in this array
 * @param float *data, the data on which the transformation is applied
 * @param size_t size, the size of the data
 * @return float*, the result vetor which is allocated
 */
void performDCT(float *c, float *data, size_t size) {
  // Compute the scale only once
  float scale = sqrt (2.0/(float)(size));
  float angle;  
  for (size_t i = 0; i < size; i++ ) {
    c[i] = 0.0;
    for (size_t j = 0; j < size; j++ ) {
      // Multiplicate data with cosine and add it to result
      angle = (M_PI*(float) (i*(2*j + 1))/(float)(2*size));
      c[i] += cos(angle) * data[j];
    }
    // Scale result=2*
    c[i] = c[i] * scale;
  }
}


/*
 * This will calculate the coefficients needed for fast dct of size 26.
 * @param float *coeff, the cosine and scaled coefficients.
 */
void computeDCTCoeff26(float *coeff) {
  float scale = sqrt (2.0/(float)(26));
  for (size_t i = 0; i < 26; i++ ) {
    coeff[i] = cos(M_PI*i/52.0) * scale;
  }
}


/*
 * This will perform a dct. Coefficients must be calculated before.
 * Calculation is quick -> 368us on teensy 96MHz
 * @param float *c, the vector of size 12 where result is stored in.
 * @param float *data, the data vector.
 * @param float *coeff, the cosine and scaled coefficients which must be calculated by "computeDCTCoeff26"
 */
void performDCT26Unrolled12MFCCs(float *c, float *data, float *coeff) {
  // Result for 0 is not calculated
  // c[0] represents 2nd dct result
  // c[1] represents 3rd dct result... etc
  c[0] = coeff[1]*(data[0]-data[25])+coeff[3]*(data[1]-data[24])+coeff[5]*(data[2]-data[23])
       + coeff[7]*(data[3]-data[22])+coeff[9]*(data[4]-data[21])+coeff[11]*(data[5]-data[20])
       + coeff[13]*(data[6]-data[19])+coeff[15]*(data[7]-data[18])+coeff[17]*(data[8]-data[17])
       + coeff[19]*(data[9]-data[16])+coeff[21]*(data[10]-data[15])+coeff[23]*(data[11]-data[14])
       + coeff[25]*(data[12]-data[13]);//13 Multi + 25 Additions 
  c[1] = coeff[2]*(data[0]-data[12]-data[13]+data[25])+coeff[6]*(data[1]-data[11]-data[14]+data[24])
       + coeff[10]*(data[2]-data[10]-data[15]+data[23])+coeff[14]*(data[3]-data[9]-data[16]+data[22])
       + coeff[18]*(data[4]-data[8]-data[17]+data[21])+coeff[22]*(data[5]-data[7]-data[18]+data[20]); // 6 Mult + 23 Add
  c[2] = coeff[3]*(data[0]-data[25])+coeff[9]*(data[1]-data[24])+coeff[15]*(data[2]-data[23])
       + coeff[21]*(data[3]-data[22])+coeff[25]*(-data[4]+data[21])+coeff[19]*(-data[5]+data[20])
       + coeff[13]*(-data[6]+data[19])+coeff[7]*(-data[7]+data[18])+coeff[1]*(-data[8]+data[17])
       + coeff[5]*(-data[9]+data[16])+coeff[11]*(-data[10]+data[15])+coeff[17]*(-data[11]+data[14])
       + coeff[23]*(-data[12]+data[13]); // 13 Mult + 25
  c[3] = coeff[4]*(data[0]+data[12]+data[13]+data[25])+coeff[12]*(data[1]+data[11]+data[14]+data[24])
       + coeff[20]*(data[2]+data[10]+data[15]+data[23])-coeff[24]*(data[3]+data[9]+data[16]+data[22])
       - coeff[16]*(data[4]+data[8]+data[17]+data[21])-coeff[8]*(data[5]+data[7]+data[18]+data[20])
       - coeff[0]*(data[6]+data[19]); // 7 Multi + 27 Add
  c[4] = coeff[5]*(data[0]-data[25])+coeff[15]*(data[1]-data[24])+coeff[25]*(data[2]-data[23])
       + coeff[17]*(data[22]-data[3])+coeff[7]*(data[21]-data[4])+coeff[3]*(data[20]-data[5]) 
       + coeff[13]*(data[19]-data[6])+coeff[23]*(data[18]-data[7])+coeff[19]*(data[8]-data[17])
       + coeff[9]*(data[9]-data[16])+coeff[1]*(data[10]-data[15])+coeff[11]*(data[11]-data[14])
       + coeff[21]*(data[12]-data[13]); // 13 Multi + 25 Add
  c[5] = coeff[6]*(data[0]-data[12]-data[13]+data[25])+coeff[18]*(data[1]-data[11]-data[14]+data[24])
       + coeff[22]*(-data[2]+data[10]+data[15]-data[23])+coeff[10]*(-data[3]+data[9]+data[16]-data[22])
       + coeff[2]*(-data[4]+data[8]+data[17]-data[21])+coeff[14]*(-data[5]+data[7]+data[18]-data[20]); // 6 Multi + 23 Add
  c[6] = coeff[7]*(data[0]-data[25])+coeff[21]*(data[1]-data[24])+coeff[17]*(-data[2]+data[23])
       + coeff[3]*(-data[3]+data[22])+coeff[11]*(-data[4]+data[21])+coeff[25]*(-data[5]+data[20]) 
       + coeff[13]*(data[6]-data[19])+coeff[1]*(data[7]-data[18])+coeff[15]*(data[8]-data[17])
       + coeff[23]*(-data[9]+data[16])+coeff[9]*(-data[10]+data[15])+coeff[5]*(-data[11]+data[14])
       + coeff[19]*(-data[12]+data[13]); // 13 + 25 Add
  c[7] = coeff[8]*(data[0]+data[12]+data[13]+data[25])+coeff[24]*(data[1]+data[11]+data[14]+data[24])
       - coeff[12]*(data[2]+data[10]+data[15]+data[23])-coeff[4]*(data[3]+data[9]+data[16]+data[22])
       - coeff[20]*(data[4]+data[8]+data[17]+data[21])+coeff[16]*(data[5]+data[7]+data[18]+data[20])
       + coeff[0]*(data[6]+data[19]); // 7 Multi + 27 Add
  c[8] = coeff[9]*(data[0]-data[25])+coeff[25]*(-data[1]+data[24])+coeff[7]*(-data[2]+data[23])
       + coeff[11]*(-data[3]+data[22])+coeff[23]*(data[4]-data[21])+coeff[5]*(data[5]-data[20])
       + coeff[13]*(data[6]-data[19])+coeff[21]*(-data[7]+data[18])+coeff[3]*(-data[8]+data[17])
       + coeff[15]*(-data[9]+data[16])+coeff[19]*(data[10]-data[15])+coeff[1]*(data[11]-data[14])
       + coeff[17]*(data[12]-data[13]); // 13 + 25 Add
  c[9] = coeff[10]*(data[0]-data[12]-data[13]+data[25])+coeff[22]*(-data[1]+data[11]+data[14]-data[24])
       + coeff[2]*(-data[2]+data[10]+data[15]-data[23])+coeff[18]*(-data[3]+data[9]+data[16]-data[22])
       + coeff[14]*(data[4]-data[8]-data[17]+data[21])+coeff[6]*(data[5]-data[7]-data[18]+data[20]); // 6 Multi + 23 Add
  c[10] = coeff[11]*(data[0]-data[25])+coeff[19]*(-data[1]+data[24])+coeff[3]*(-data[2]+data[23])
        + coeff[25]*(-data[3]+data[22])+coeff[5]*(data[4]-data[21])+coeff[17]*(data[5]-data[20]) 
        + coeff[13]*(-data[6]+data[19])+coeff[9]*(-data[7]+data[18])+coeff[21]*(data[8]-data[17])
        + coeff[1]*(data[9]-data[16])+coeff[23]*(data[10]-data[15])+coeff[7]*(-data[11]+data[14])
        + coeff[15]*(-data[12]+data[13]); // 13 + 25 Add
  c[11] = coeff[12]*(data[0]+data[12]+data[13]+data[25])-coeff[16]*(data[1]+data[11]+data[14]+data[24])
        - coeff[8]*(data[2]+data[10]+data[15]+data[23])+coeff[20]*(data[3]+data[9]+data[16]+data[22]) 
        + coeff[4]*(data[4]+data[8]+data[17]+data[21])-coeff[24]*(data[5]+data[7]+data[18]+data[20])
        - coeff[0]*(data[6]+data[19]); // 7 Multi + 27 Add
}


#endif /* dct_h */
