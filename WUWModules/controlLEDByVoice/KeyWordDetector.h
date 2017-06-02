/****************************************************
TODO
 ****************************************************/

#ifndef KeyWordDetector_h
#define KeyWordDetector_h

#if (ARDUINO >= 100)
#include "Arduino.h"
#else
#include "WProgram.h"
#endif

#include <SD.h>
#include <SPI.h>


// Debug-messages.
#define DEBUG_KD 1
#define DEBUG_KD_MORE 0
//#define DEBUG_MEL
//#define DEBUG_WINDOW
//#define DEBUG_MAJOR_FREQUENCY
//#define DEBUG_FFT
//#define DEBUG_ENERGY


// The CS Pin of the SD card
#define SD_CS 10
// The filename of the file holding the mfcc data of the template
#define FILENAME "MFCCs_"
#define FILEENDING ".txt"

// Sampling rate in HZ
#define SAMPLING_RATE 16000
// Window and Frame length in ms
#define WINDOW_LENGTH_MS 20
#define FRAME_LENGTH_MS 10

#define FFT_SIZE 512

#define COMPARE_ALL_KEYWORDS 1

// Calculate number of samples for a window or frame
#define WINDOW_LENGTH WINDOW_LENGTH_MS * SAMPLING_RATE / 1000
#define FRAME_LENGTH FRAME_LENGTH_MS * SAMPLING_RATE / 1000
// The number of frames averaged to a new longterm energy value
#define LONGTERM_ENERGY_FRAME_COUNT 20
// The energy required to break silence as a multiply of the longtermenergy for start of keyword and end of keyword is different
// since some often used keywords start with high energy end end with lower energy e.g. House or a pronounced so that energy drops
// significantly at the end.
#define ENERGY_DETECTION_MULTIPLIER_BEGIN 10
#define ENERGY_DETECTION_MULTIPLIER_END 5
// The number of frames of silence (no voice) appended to voiced region
#define FRAME_SILENCE_THRESHOLD 20
// A lower limit for the length of the spoken keyword
#define TEMPLATE_MATCH_UPPER_LENGTH_LIMIT 1.2f
// A lower limit for the length of the spoken keyword
#define TEMPLATE_MATCH_LOWER_LENGTH_LIMIT 0.7f

// The min and max frequency in Hz used to set up the mel filter bank
// Max frequency must be smaller equal samplingrate/2
//#define MEL_MIN_FREQUENCY 300.0f
//#define MEL_MAX_FREQUENCY 8000.0f
#define MEL_MIN_FREQUENCY 100.0f
#define MEL_MAX_FREQUENCY 8000.0f

// The number of mel filter banks (good value: 26 - 40)
// NOTE: you can not change this in order to manually adjust code
// since fast dct is performed by loop unrolling with size 26 
// and only calculates dct coefficients 1-12 and thus returns
// a vector of size 12
#define NUM_MEL_FILTER_BANKS 26
#define NUM_MFCCS 12

#define A_PREEMPHASIS 0.95f

// The number of DTW comparisons
#define NUMBER_OF_DTW_COMPARISONS 3
// The warping window of the DTW is defined by this
#define MAX_DTW_WARPING_DISTANCE 20

// DTW match threshold, results lower this value are treated as keyword
#define MATCH_THRESHOLD 0.99f

// The maximal length of the mfcc vector
#define MAX_MFCC_VECTOR_FRAMES 200
#define MAX_MFCC_VECTOR_SIZE NUM_MFCCS*MAX_MFCC_VECTOR_FRAMES

// The number of histogram bins calculated
#define NUM_HIST_BINS 10
// The stepwidth for one histogram bin on absolute value of signal
#define HIST_STEP (int)((128)/NUM_HIST_BINS)
// The number of windows that are used to avaerage histogram
#define NUM_WINDOWS_HIST 100
// The number of first histogram bins averaged for bg noise classification 
#define FIRST_HIST_BINS 2

// Thresholds for low medium and high noise assumption (must be above value)
#define LOW_NOISE_THRESHOLD 0.78f
#define MEDIUM_NOISE_THRESHOLD 0.45f


// The lowpass value for noise floor estimation update
// newValue = oldValue*(1-NOISE_FLOOR_LOWPASS) + NOISE_FLOOR_LOWPASS*currentValue
#define NOISE_FLOOR_LOWPASS 0.1f

// This offset is added to the noise floor value for each freuency bin
#define NOISE_FLOOR_OFFSET 0.1

class KeyWordDetector {
  
public:
    
  // Constructor
  KeyWordDetector();
  
  // Destructor
  ~KeyWordDetector();
  
  // Init function with a handler function for detecting keyword
  void init(void (*keywordHandler)(int), void (*templateHandler)(int));
  
  // Dumps info about the settings
  void dumpInfo();
  
  // Updates the keyword detector with a given pointer to the next audio window
  void update(int8_t *audioWindow);
  
  // Start learning keyword
  void startLearningKeyword();
  
  // Will delete all template files stored on the SD card
  bool deleteAllTemplates();
  
private:
  
  /*
   * Calculate the size of the needed FFT and inits the member varialbes.
   */
  void initFFT();
  
  /*
   * Generate the Mel filter banks and inits the member variable
   */
  void generateMelFilterBank();
  
  /*
   * Geneerate the window function and inits the member variables
   */
  void generateWindowFunction();
  
  /*
   * Applies a preemphasis filter (first order FIR filter) to a given vector
   */
  void applyPreemphasis();

  /*
   * Performs the FFT inplace to a given vector.
   */
   void performFFT();
   
  /*
   * Compute the power spectrum from spectrum in Place.
   */
  void powerSpectrum();
  
  /*
   * Calculates and returns the mfccs from a given vector.
   */
  void getMFCCs();
  
  /*
   * Calculate and updates the current noise floor which can be used for spectral noise gating. 
   */
  void noiseFloorCalculation();
  
  /*
   * Applies a noise gate to the current spectrum. 
   */
  void spectralNoiseGating();

  /*
   * Stores new template mfcc data after detecting voice frames on sequential
   * audio windows.
   */
  bool getNewTemplate();
  
  /*
   * Runs the detection algorithm on a audio window,
   * this function must be continously called on sequential
   * audio windows, otherwise it could cause misleading data.
   */
  bool testForKeyword();
  
  /*
   * Runs the DTW algorithm on the testMFCCs and templateMFCCs sequences.
   * Will return true or false, depending on the overall distance between the 
   * two sequences. If below defined threshold, this will return true.
   * @param size_t potentiallKeywordFrameCount, the size of the potential keyword
   */
  int testPotentialKeyword(size_t potentiallKeywordFrameCount);

  /*
   * Will store the currentMFCC vector at the given position 
   * param size_t index, index's mfcc vector is stored
   */
  void storeMFCCs(size_t index);
  
  /*
   * Will store the currentMFCC vector at the given position 
   * param size_t index, index's mfcc vector is stored
   */
  void storeTemplateMFCCs(size_t index);
  
  /*
   * Will return the index for the start of one mfcc vector 
   * (since mfcc matrix is stored in large vector).
   * param size_t index, index's mfcc vector is asked
   */
  size_t getMFCCIndex(size_t index);
  
  
  /*
   * Writes a float value to the SD card.
   * @param float value, value to write
   */
  void SD_writeFloat(float value);
  
  /*
   * Reads a float value from the SD card.
   * @return float, value that is read
   */
  float SD_readFloat();
  
  /*
   * Reads an int value from the SD card.
   * @return int value, value that is read
   */
  int SD_readInt();
  
  /*
   * Writes an int value to the SD card.
   * @param int value, value to write
   */
  void SD_writeInt(int value);
   
  /*
   * Writes MFCC data to SD card.
   * @param int fileNumber, the fileNumber to be written, since all
   * templates are stored in different files
   * @return bool, if successfully written
   */
  bool SD_writeMFCCData(int fileNumber);
  
  /*
   * Reads MFCC data from SD card.
   * @param int fileNumber, the fileNumber to be read, since all
   * templates are stored in different files
   * @return bool, if successfully read
   */
  bool SD_readMFCCData(int fileNumber);
  
  /*
   * Will print the mfcc sequence in matrix form.
   * Since a mfcc sequence consist of mfcc vectors of defined length.
   */
  void printMFCCSequence(float *sequence, size_t size);
  
  // Needed for normalisation after windowing
  float windowNormS1;
  float windowNormS2;
  float powerSpectrumScale;
  
  // The window (hamming, hann, etc.) is half sized since it is symmetric
  float window[WINDOW_LENGTH/2];
  
  // The power spectrum of the current audio window
  float powerSpec[FFT_SIZE/2];
  float noiseFloor[FFT_SIZE/2];
  
  // Imaginary vector used for FFT
  short vImag[FFT_SIZE];
  short vReal[FFT_SIZE];
  
  // The melbins used for filterbank calculation
  int melBins[NUM_MEL_FILTER_BANKS+2];
  // Sclaed cosine DCT coefficients
  float dctCoeff[NUM_MEL_FILTER_BANKS];
  // The logarithmic mel energies of the current window
  float logMelEn[NUM_MEL_FILTER_BANKS];
  // The mfccs of the current window
  float currentMFCCs[NUM_MFCCS];
  
  // The energies and mfccs of the template
  float *templateEnergies;
  float templateMFCCs[MAX_MFCC_VECTOR_SIZE];
  size_t templateKeywordFrameCount;
  
  float *testEnergies;
  float testMFCCs[MAX_MFCC_VECTOR_SIZE];
  size_t potentiallKeywordFrameCount;
  
  // A vector where energies are stored for longterm energy calculation
  float energies[LONGTERM_ENERGY_FRAME_COUNT];
  size_t energyIndex;
  
  // If potentially there is a keyword present
  // If activated, the shortterm energies are stored and the
  // mfccs are calculated and store
  bool activated;
  
  // Counts the number of silenced frames
  int frameSilenceCount;
  
  // The longterm energy used for comparing for silence threshold
  float longTermEnergy;
  
  // Start index for a potential keyword
  size_t frameCount;
  
  // Reset is used if a keyword was too short, no closer match perfomed
  bool reset;
  // Waiting for next silence is used if a keyword is too long, no closer match is performed
  bool waitForNextSilence;

  // The template data file stored on the sd card
  File templateDataFile;
  
  // The number of stored templates
  int numberOfStoredTemplates;
  
  // If should store new template
  bool learnKeyword;
  
  // The shortest and longest template size, for framing the keywords
  size_t shortestTemplateSize;
  size_t longestTemplateSize;
  
  // The current count of windows used for hist calculation
  size_t histWindow;
  
  // The first hist bins that give information about bg noise
  size_t firstHistBins;
  
  // The Background noise estimated from long time amplitude histogram
  // the higher this value the lower the noise
  float bgNoise;
  
  // A Handler function that is called if a keyword is successfully detected
  void (*keywordHandlerFunction)(int);
  
  // A Handler function that is called if a template is succesfully learned
  void (*templateHandlerFunction)(int);
  
};

#endif


