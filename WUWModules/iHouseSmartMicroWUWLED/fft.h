
/* fix_fft.c - Fixed-point in-place Fast Fourier Transform  */
/*
  All data are fixed-point short integers, in which -32768
  to +32768 represent -1.0 to +1.0 respectively. Integer
  arithmetic is used for speed, instead of the more natural
  floating-point.

  For the forward FFT (time -> freq), fixed scaling is
  performed to prevent arithmetic overflow, and to map a 0dB
  sine/cosine wave (i.e. amplitude = 32767) to two -6dB freq
  coefficients. The return value is always 0.

  For the inverse FFT (freq -> time), fixed scaling cannot be
  done, as two 0dB coefficients would sum to a peak amplitude
  of 64K, overflowing the 32k range of the fixed-point integers.
  Thus, the fix_fft() routine performs variable scaling, and
  returns a value which is the number of bits LEFT by which
  the output must be shifted to get the actual amplitude
  (i.e. if fix_fft() returns 3, each value of fr[] and fi[]
  must be multiplied by 8 (2**3) for proper scaling.
  Clearly, this cannot be done within fixed-point short
  integers. In practice, if the result is to be used as a
  filter, the scale_shift can usually be ignored, as the
  result will be approximately correctly normalized as is.

  Written by:  Tom Roberts  11/8/89
  Made portable:  Malcolm Slaney 12/15/94 malcolm@interval.com
  Enhanced:  Dimitrios P. Bouras  14 Jun 2006 dbouras@ieee.org
*/


#define N_WAVE      1024    /* full length of Sinewave[] */
#define LOG2_N_WAVE 10      /* log2(N_WAVE) */

/*
  Henceforth "short" implies 16-bit word. If this is not
  the case in your architecture, please replace "short"
  with a type definition which *is* a 16-bit word.
*/

/*
  Since we only use 3/4 of N_WAVE, we define only
  this many samples, in order to conserve data space.
*/
short Sinewave[N_WAVE-N_WAVE/4] = {
      0,    201,    402,    603,    804,   1005,   1206,   1406,
   1607,   1808,   2009,   2209,   2410,   2610,   2811,   3011,
   3211,   3411,   3611,   3811,   4011,   4210,   4409,   4608,
   4807,   5006,   5205,   5403,   5601,   5799,   5997,   6195,
   6392,   6589,   6786,   6982,   7179,   7375,   7571,   7766,
   7961,   8156,   8351,   8545,   8739,   8932,   9126,   9319,
   9511,   9703,   9895,  10087,  10278,  10469,  10659,  10849,
  11038,  11227,  11416,  11604,  11792,  11980,  12166,  12353,
  12539,  12724,  12909,  13094,  13278,  13462,  13645,  13827,
  14009,  14191,  14372,  14552,  14732,  14911,  15090,  15268,
  15446,  15623,  15799,  15975,  16150,  16325,  16499,  16672,
  16845,  17017,  17189,  17360,  17530,  17699,  17868,  18036,
  18204,  18371,  18537,  18702,  18867,  19031,  19194,  19357,
  19519,  19680,  19840,  20000,  20159,  20317,  20474,  20631,
  20787,  20942,  21096,  21249,  21402,  21554,  21705,  21855,
  22004,  22153,  22301,  22448,  22594,  22739,  22883,  23027,
  23169,  23311,  23452,  23592,  23731,  23869,  24006,  24143,
  24278,  24413,  24546,  24679,  24811,  24942,  25072,  25201,
  25329,  25456,  25582,  25707,  25831,  25954,  26077,  26198,
  26318,  26437,  26556,  26673,  26789,  26905,  27019,  27132,
  27244,  27355,  27466,  27575,  27683,  27790,  27896,  28001,
  28105,  28208,  28309,  28410,  28510,  28608,  28706,  28802,
  28897,  28992,  29085,  29177,  29268,  29358,  29446,  29534,
  29621,  29706,  29790,  29873,  29955,  30036,  30116,  30195,
  30272,  30349,  30424,  30498,  30571,  30643,  30713,  30783,
  30851,  30918,  30984,  31049,  31113,  31175,  31236,  31297,
  31356,  31413,  31470,  31525,  31580,  31633,  31684,  31735,
  31785,  31833,  31880,  31926,  31970,  32014,  32056,  32097,
  32137,  32176,  32213,  32249,  32284,  32318,  32350,  32382,
  32412,  32441,  32468,  32495,  32520,  32544,  32567,  32588,
  32609,  32628,  32646,  32662,  32678,  32692,  32705,  32717,
  32727,  32736,  32744,  32751,  32757,  32761,  32764,  32766,
  32767,  32766,  32764,  32761,  32757,  32751,  32744,  32736,
  32727,  32717,  32705,  32692,  32678,  32662,  32646,  32628,
  32609,  32588,  32567,  32544,  32520,  32495,  32468,  32441,
  32412,  32382,  32350,  32318,  32284,  32249,  32213,  32176,
  32137,  32097,  32056,  32014,  31970,  31926,  31880,  31833,
  31785,  31735,  31684,  31633,  31580,  31525,  31470,  31413,
  31356,  31297,  31236,  31175,  31113,  31049,  30984,  30918,
  30851,  30783,  30713,  30643,  30571,  30498,  30424,  30349,
  30272,  30195,  30116,  30036,  29955,  29873,  29790,  29706,
  29621,  29534,  29446,  29358,  29268,  29177,  29085,  28992,
  28897,  28802,  28706,  28608,  28510,  28410,  28309,  28208,
  28105,  28001,  27896,  27790,  27683,  27575,  27466,  27355,
  27244,  27132,  27019,  26905,  26789,  26673,  26556,  26437,
  26318,  26198,  26077,  25954,  25831,  25707,  25582,  25456,
  25329,  25201,  25072,  24942,  24811,  24679,  24546,  24413,
  24278,  24143,  24006,  23869,  23731,  23592,  23452,  23311,
  23169,  23027,  22883,  22739,  22594,  22448,  22301,  22153,
  22004,  21855,  21705,  21554,  21402,  21249,  21096,  20942,
  20787,  20631,  20474,  20317,  20159,  20000,  19840,  19680,
  19519,  19357,  19194,  19031,  18867,  18702,  18537,  18371,
  18204,  18036,  17868,  17699,  17530,  17360,  17189,  17017,
  16845,  16672,  16499,  16325,  16150,  15975,  15799,  15623,
  15446,  15268,  15090,  14911,  14732,  14552,  14372,  14191,
  14009,  13827,  13645,  13462,  13278,  13094,  12909,  12724,
  12539,  12353,  12166,  11980,  11792,  11604,  11416,  11227,
  11038,  10849,  10659,  10469,  10278,  10087,   9895,   9703,
   9511,   9319,   9126,   8932,   8739,   8545,   8351,   8156,
   7961,   7766,   7571,   7375,   7179,   6982,   6786,   6589,
   6392,   6195,   5997,   5799,   5601,   5403,   5205,   5006,
   4807,   4608,   4409,   4210,   4011,   3811,   3611,   3411,
   3211,   3011,   2811,   2610,   2410,   2209,   2009,   1808,
   1607,   1406,   1206,   1005,    804,    603,    402,    201,
      0,   -201,   -402,   -603,   -804,  -1005,  -1206,  -1406,
  -1607,  -1808,  -2009,  -2209,  -2410,  -2610,  -2811,  -3011,
  -3211,  -3411,  -3611,  -3811,  -4011,  -4210,  -4409,  -4608,
  -4807,  -5006,  -5205,  -5403,  -5601,  -5799,  -5997,  -6195,
  -6392,  -6589,  -6786,  -6982,  -7179,  -7375,  -7571,  -7766,
  -7961,  -8156,  -8351,  -8545,  -8739,  -8932,  -9126,  -9319,
  -9511,  -9703,  -9895, -10087, -10278, -10469, -10659, -10849,
 -11038, -11227, -11416, -11604, -11792, -11980, -12166, -12353,
 -12539, -12724, -12909, -13094, -13278, -13462, -13645, -13827,
 -14009, -14191, -14372, -14552, -14732, -14911, -15090, -15268,
 -15446, -15623, -15799, -15975, -16150, -16325, -16499, -16672,
 -16845, -17017, -17189, -17360, -17530, -17699, -17868, -18036,
 -18204, -18371, -18537, -18702, -18867, -19031, -19194, -19357,
 -19519, -19680, -19840, -20000, -20159, -20317, -20474, -20631,
 -20787, -20942, -21096, -21249, -21402, -21554, -21705, -21855,
 -22004, -22153, -22301, -22448, -22594, -22739, -22883, -23027,
 -23169, -23311, -23452, -23592, -23731, -23869, -24006, -24143,
 -24278, -24413, -24546, -24679, -24811, -24942, -25072, -25201,
 -25329, -25456, -25582, -25707, -25831, -25954, -26077, -26198,
 -26318, -26437, -26556, -26673, -26789, -26905, -27019, -27132,
 -27244, -27355, -27466, -27575, -27683, -27790, -27896, -28001,
 -28105, -28208, -28309, -28410, -28510, -28608, -28706, -28802,
 -28897, -28992, -29085, -29177, -29268, -29358, -29446, -29534,
 -29621, -29706, -29790, -29873, -29955, -30036, -30116, -30195,
 -30272, -30349, -30424, -30498, -30571, -30643, -30713, -30783,
 -30851, -30918, -30984, -31049, -31113, -31175, -31236, -31297,
 -31356, -31413, -31470, -31525, -31580, -31633, -31684, -31735,
 -31785, -31833, -31880, -31926, -31970, -32014, -32056, -32097,
 -32137, -32176, -32213, -32249, -32284, -32318, -32350, -32382,
 -32412, -32441, -32468, -32495, -32520, -32544, -32567, -32588,
 -32609, -32628, -32646, -32662, -32678, -32692, -32705, -32717,
 -32727, -32736, -32744, -32751, -32757, -32761, -32764, -32766,
};

/*
  FIX_MPY() - fixed-point multiplication & scaling.
  Substitute inline assembly for hardware-specific
  optimization suited to a particluar DSP processor.
  Scaling ensures that result remains 16-bit.
*/
inline short FIX_MPY(short a, short b) {
	/* shift right one less bit (i.e. 15-1) */
	int c = ((int)a * (int)b) >> 14;
	/* last bit shifted out = rounding-bit */
	b = c & 0x01;
	/* last shift + rounding bit */
	a = (c >> 1) + b;
	return a;
}

/*
  fix_fft() - perform forward/inverse fast Fourier transform.
  fr[n],fi[n] are real and imaginary arrays, both INPUT AND
  RESULT (in-place FFT), with 0 <= n < 2**m; set inverse to
  0 for forward transform (FFT), or 1 for iFFT.
*/
int fix_fft(short fr[], short fi[], short m, short inverse) {
	int mr, nn, i, j, l, k, istep, n, scale, shift;
	short qr, qi, tr, ti, wr, wi;

	n = 1 << m;

	/* max FFT size = N_WAVE */
	if (n > N_WAVE)
		return -1;

	mr = 0;
	nn = n - 1;
	scale = 0;

	/* decimation in time - re-order data */
	for (m=1; m<=nn; ++m) {
		l = n;
		do {
			l >>= 1;
		} while (mr+l > nn);
		mr = (mr & (l-1)) + l;

		if (mr <= m)
			continue;
		tr = fr[m];
		fr[m] = fr[mr];
		fr[mr] = tr;
		ti = fi[m];
		fi[m] = fi[mr];
		fi[mr] = ti;
	}

	l = 1;
	k = LOG2_N_WAVE-1;
	while (l < n) {
		if (inverse) {
			/* variable scaling, depending upon data */
			shift = 0;
			for (i=0; i<n; ++i) {
				j = fr[i];
				if (j < 0)
					j = -j;
				m = fi[i];
				if (m < 0)
					m = -m;
				if (j > 16383 || m > 16383) {
					shift = 1;
					break;
				}
			}
			if (shift)
				++scale;
		} else {
			/*
			  fixed scaling, for proper normalization --
			  there will be log2(n) passes, so this results
			  in an overall factor of 1/n, distributed to
			  maximize arithmetic accuracy.
			*/
			shift = 1;
		}
		/*
		  it may not be obvious, but the shift will be
		  performed on each data point exactly once,
		  during this pass.
		*/
		istep = l << 1;
		for (m=0; m<l; ++m) {
			j = m << k;
			/* 0 <= j < N_WAVE/2 */
			wr =  Sinewave[j+N_WAVE/4];
			wi = -Sinewave[j];
			if (inverse)
				wi = -wi;
			if (shift) {
				wr >>= 1;
				wi >>= 1;
			}
			for (i=m; i<n; i+=istep) {
				j = i + l;
				tr = FIX_MPY(wr,fr[j]) - FIX_MPY(wi,fi[j]);
				ti = FIX_MPY(wr,fi[j]) + FIX_MPY(wi,fr[j]);
				qr = fr[i];
				qi = fi[i];
				if (shift) {
					qr >>= 1;
					qi >>= 1;
				}
				fr[j] = qr - tr;
				fi[j] = qi - ti;
				fr[i] = qr + tr;
				fi[i] = qi + ti;
			}
		}
		--k;
		l = istep;
	}
	return scale;
}

/*
  fix_fftr() - forward/inverse FFT on array of real numbers.
  Real FFT/iFFT using half-size complex FFT by distributing
  even/odd samples into real/imaginary arrays respectively.
  In order to save data space (i.e. to avoid two arrays, one
  for real, one for imaginary samples), we proceed in the
  following two steps: a) samples are rearranged in the real
  array so that all even samples are in places 0-(N/2-1) and
  all imaginary samples in places (N/2)-(N-1), and b) fix_fft
  is called with fr and fi pointing to index 0 and index N/2
  respectively in the original array. The above guarantees
  that fix_fft "sees" consecutive real samples as alternating
  real and imaginary samples in the complex array.
*/
int fix_fftr(short f[], int m, int inverse) {
	int i, N = 1<<(m-1), scale = 0;
	short tt, *fr=f, *fi=&f[N];

	if (inverse)
		scale = fix_fft(fi, fr, m-1, inverse);
	for (i=1; i<N; i+=2) {
		tt = f[N+i-1];
		f[N+i-1] = f[i];
		f[i] = tt;
	}
	if (! inverse)
		scale = fix_fft(fi, fr, m-1, inverse);
	return scale;
}


//
//  fft.h
//  MFCC
//
//  Created by Benjamin Völker on 05/10/15.
//  Copyright © 2015 Benjamin Völker. All rights reserved.
//

#ifndef fft_h
#define fft_h

#if defined(ARDUINO) && ARDUINO >= 100
  #include "Arduino.h"
#else
  #include "WProgram.h"
#endif


#include <math.h>
#include <stdlib.h>

// The window types
#define FFT_WIN_TYP_RECTANGLE 0
#define FFT_WIN_TYP_HAMMING 1
#define FFT_WIN_TYP_HANN 2
#define FFT_WIN_TYP_TRIANGLE 3
#define FFT_WIN_TYP_BLACKMAN 4
#define FFT_WIN_TYP_WELCH 5
// Pi constants that are used
#define twoPi 6.28318531
#define fourPi 12.56637061


/**
 * Computes the window with a given size and given type
 * The window size is float the output vector size because it is symmetrically
 * @param float* window, the result of the computed window will be stored in this vector
 * @param int windowSize, size of the window
 * @param int windowType, one of the availabe window types (see defines)
 */
void computeWindow(float* window, int windowSize, int windowType) {
  float samplesMinusOne = (float(windowSize) - 1.0);
  for (uint16_t i = 0; i < (windowSize / 2); i++) {
    float indexMinusOne = float(i);
    float ratio = (indexMinusOne / samplesMinusOne);
    /* Compute and record weighting factor */
    switch (windowType) {
      // Rectangle window (box)
      case FFT_WIN_TYP_RECTANGLE:
        window[i] = 1.0;
        break;
      // Hamming window
      case FFT_WIN_TYP_HAMMING:
        window[i] = 0.54 - (0.46 * cos(twoPi * ratio));
        break;
      // Hanning window
      case FFT_WIN_TYP_HANN:
        window[i] = 0.54 * (1.0 - cos(twoPi * ratio));
        break;
      // Triangle / bartlett window
      case FFT_WIN_TYP_TRIANGLE: /* triangle (Bartlett) */
        window[i] = 1.0 - ((2.0 * fabs(indexMinusOne - (samplesMinusOne / 2.0))) / samplesMinusOne);
        break;
      // Blackmann window
      case FFT_WIN_TYP_BLACKMAN:
        window[i] = 0.42323 - (0.49755 * (cos(twoPi * ratio))) + (0.07922 * (cos(fourPi * ratio)));
        break;
      // Welch window
      case FFT_WIN_TYP_WELCH:
        window[i] = 1.0 - pow((indexMinusOne - samplesMinusOne / 2.0) / (samplesMinusOne / 2.0), 2);
        break;
    }
  }
}

/**
 * Applies the window on a given data sequence
 * The window size is half the output vector size because it is symmetrically
 * @param float *vData, the vector on which the window will be applied
 * @param float* window, the window (must be precomputed by "computeWindow")
 * @param int samples, size of the data sequence (must be double the size of the window)
 * @param bool direction, if the window should be applied or deapplied
 */
void applyWindowing(float *vData, float *window, int samples, bool dir) {
  // Synce the window is symmetric, we can loop over half of the sequence
  for (int i = 0; i < (samples >> 1); i++) {
    // Depending on direction multiply or devide by the window
    if (dir) {
      vData[i] *= window[i];
      vData[samples - (i + 1)] *= window[i];
    } else {
      vData[i] /= window[i];
      vData[samples - (i + 1)] /= window[i];
    }
  }
}


/**
 * Applies the window on a given data sequence
 * The window size is half the output vector size because it is symmetrically
 * @param float *vData, the vector on which the window will be applied
 * @param float* window, the window (must be precomputed by "computeWindow")
 * @param int samples, size of the data sequence (must be double the size of the window)
 * @param bool direction, if the window should be applied or deapplied
 */
void applyWindowing(short *vData, float *window, int samples, bool dir) {
  // Synce the window is symmetric, we can loop over half of the sequence
  for (int i = 0; i < (samples >> 1); i++) {
    if (dir) {
      vData[i] = (short)((float)(vData[i])*window[i]);
      vData[samples - (i + 1)] = (short)((float)(vData[samples - (i + 1)])*window[i]);
    } else {
      vData[i] = (short)(float)(vData[i])/(float)window[i];
      vData[samples - (i + 1)] = (short)(float)(vData[samples - (i + 1)])/(float)window[i];
    }
  }
}

/**
 * Computes the magnitude of a complex value sequence "x[j] = a + ib"
 * The result will be stored in the vReal vector (in place)
 * @param float *vReal, the real part of the sequence
 * @param float* vImag, the imaginary part of the sequence
 * @param int fftSize, size of the data sequence
 */
void complexToMagnitude(float *vReal, float *vImag, int fftSize) {
  // Relevant information is only in the first half of the vectors
  for (int i = 0; i < (fftSize >> 1); i++) {
    vReal[i] = sqrt(pow(vReal[i], 2) + pow(vImag[i], 2));
  }
}


/**
 * Computes the magnitude of a complex value sequence "x[j] = a + ib"
 * @param float *vReal, the real part of the sequence
 * @param float* vImag, the imaginary part of the sequence
 * @param float* result, the result will be stored in this vector
 * @param int fftSize, size of the data sequence
 */
void complexToMagnitude(short *vReal, short *vImag, float *result, int fftSize) {
  // Relevant information is only in the first half of the vectors
  for (int i = 0; i < (fftSize >> 1); i++) {
    result[i] = (float)sqrt((float)vReal[i] * (float)vReal[i] + (float)vImag[i] * (float)vImag[i]);
  }
}

/**
 * Computes the magnitude of a complex value sequence "x[j] = a + ib"
 * The result will be stored in the vReal vector (in place)
 * @param short *vReal, the real part of the sequence
 * @param short *vImag, the imaginary part of the sequence
 * @param int fftSize, size of the data sequence
 */
void complexToMagnitude(short *vReal, short *vImag, int fftSize) {
  // Relevant information is only in the first half of the vectors
  for (int i = 0; i < (fftSize >> 1); i++) {
    vReal[i] =sqrt((long)vReal[i] * (long)vReal[i] + (long)vImag[i] * (long)vImag[i]);
  }
}

/**
 * Computes the magnitude of a complex value sequence "x[j] = a + ib"
 * The result will be stored in the vReal vector (in place)
 * @param short *sequence, the real part of the sequence is stored from 0-N/2, the imaginary part
 * is stored from N/2-N
 * @param int fftSize, size of the data sequence
 */
void complexToMagnitude(short *sequence, int fftSize) {
  for (int i = 0; i < (fftSize >> 1); i++) {
    sequence[i] =sqrt((long)sequence[i] * (long)sequence[i] + (long)sequence[i+(fftSize >> 1)] * (long)sequence[i+(fftSize >> 1)]);
  }
}

/**
 * Computes the major frequency from a fft vector (bins)
 * @param short *vD, the magnitude of the complex sequence
 * @param int samples, the size of the FFT
 * @param float samplingFrequency, the frequency with which the data is sampled
 * @return float, the major frequency in Hz 
 */
float majorPeak(short *vD, int samples, float samplingFrequency) {
  // Get the index and value of the maximum peak of the spectrum
  float maxY = 0;
  int IndexOfMaxY = 1;
  // Discard 0 since 50Hz will always be present somewhere in the signal
  for (int i = 1; i < ((samples >> 1) - 1); i++) {
    if ((vD[i-1] < vD[i]) && (vD[i] > vD[i+1])) {
      if (vD[i] > maxY) {
        maxY = vD[i];
        IndexOfMaxY = i;
      }
    }
  }
  // The frequency is than interpolated with the value in the 1 hop neighborhood
  float delta = 0.5 * ((vD[IndexOfMaxY-1] - vD[IndexOfMaxY+1]) / (float)(vD[IndexOfMaxY-1] - (2.0 * vD[IndexOfMaxY]) + vD[IndexOfMaxY+1]));
  float interpolatedX = ((IndexOfMaxY + delta)  * samplingFrequency) / (samples-1);
  // Return the interpolated frequency peak
  return(interpolatedX);
}


/**
 * Computes the major frequency from a fft vector (bins)
 * @param float *vD, the magnitude of the complex sequence
 * @param int samples, the size of the FFT
 * @param float samplingFrequency, the frequency with which the data is sampled
 * @return float, the major frequency in Hz 
 */
float majorPeak(float *vD, int samples, float samplingFrequency) {
  // Get the index and value of the maximum peak of the spectrum
  float maxY = 0;
  int IndexOfMaxY = 0;
  // Discard 0 since 50Hz will always be present somewhere in the signal
  for (int i = 1; i < ((samples/2) - 1); i++) {
    if ((vD[i-1] < vD[i]) && (vD[i] > vD[i+1])) {
      if (vD[i] > maxY) {
        maxY = vD[i];
        IndexOfMaxY = i;
      }
    }
  }
  // The frequency is than interpolated with the value in the 1 hop neighborhood
  float delta = 0.5 * ((vD[IndexOfMaxY-1] - vD[IndexOfMaxY+1]) / (vD[IndexOfMaxY-1] - (2.0 * vD[IndexOfMaxY]) + vD[IndexOfMaxY+1]));
  float interpolatedX = ((IndexOfMaxY + delta)  * samplingFrequency) / (samples-1);
  // Return the interpolated frequency peak
  return(interpolatedX);
}

/**
 * Computes the FFT in place by calling the fix_fft function
 * @param short *vReal, the Real part of the fft, the time sequence must be stored in this vector
 * @param short *vImag, the imaginary part will be stored here
 * @param int fftSize, the size of the fft, must be one of 32/64/128/256/512/104, otherwise
 * this function will not work properly
 */
void computeFFT(short *vReal, short *vImag, int fftSize) {
  // Get the logarithm to base to of the given fftsize
  int m = 5;
  if (fftSize == 64) m = 6;
  else if (fftSize == 128) m = 7;
  else if (fftSize == 256) m = 8;
  else if (fftSize == 512) m = 9;
  else if (fftSize == 1024) m = 10;
  fix_fft(vReal, vImag, m, false);
}

#endif /* fft_h */


