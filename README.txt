README.txt

For wind identification using algorithms related to 
'Predictive Fourier Control'. See references:

Predictive Fourier Control:
L. A. Poyneer, B. A. Macintosh, and J.-P. Veran, "Fourier transform
  wavefront control with adaptive prediction of the atmosphere," 
J. Opt. Soc. Am. A 24, 2645--2660 (2007).

Wind Identification:
L. A. Poyneer, M. A. {van Dam}, and J.-P. Veran, "Experimental
  verification of the frozen flow atmospheric turbulence assumption with use of
  astronomical adaptive optics telemetry," J. Opt. Soc. Am. 26, 833--846 (2009).

**********************************************************************
******* What you will need:

An IDL license

The IDL Astronomy Library, for FITS file reading.
    http://idlastro.gsfc.nasa.gov

The Imagelib toolkit, which has lots of nice functions
for display. 
    imagelib.tar.gz

Install this in your personal IDL library path and then
add the following line to your .idl_startup file:
    imagelib
    devicelib
    
There are several routines which use command-line tools to
make nice figures and animated GIFs. You will need to 
have installed (if you are on a Mac, get these via macports)
     ImageMagick
     Whirlgif

The code and data. To begin, use the tar
    WindIdentCodeAndData_29Jan2013.tar.gz

Unpack this in the directory where you store your IDL
projects. It will create a directory telem_analysis_13/
which will have inside it all the sub directories 
and code files that you will need.

**********************************************************************
******* How to run the code

To begin only the raw data will be given to you.
Each observation of raw data in data/telname/raw/
is described in a matching IDL file of the form
get_case_telname.pro

This takes a number as an argument. Inside are all the details
of how to process this telescope's particular telemetry format,
geometry, etc. into a standard format.

To process the raw data into two 3D cubes 
(one of which is the actuator commands, the other FOurier modes of the commands)
in closed-loop with time, do as follows:

IDL> obs = get_case_telname(num)
IDL> process_raw_data, obs

This will read everything in and process it for you.
Saved to disk in data/telname/proc/ 
will be a fits file of the name
identifier_phase.fits
identifier_fmodes.fits

The obs structure in IDL contains all the necessary info
for further processing.  For example:

IDL> help, get_case_keck(0)
** Structure <3806608>, 21 tags, length=2888, data length=2882, refs=1:
   TELESCOPE       STRING    'keck'
   RAW_PATH        STRING    'data/keck/raw/data_30jul07/dataset2.dat'
   PROCESSED_PATH  STRING    'data/keck/proc/20070730_2'
   FILENAME        STRING    '20070730_2'
   N               INT             26
   N_DM            INT             21
   L_DM            INT              2
   H_DM            INT             22
   DATATYPE        STRING    'closed-loop-dm-commands'
   RATE            FLOAT           1054.00
   D               FLOAT          0.560000
   PROBLEMS        INT              0
   PUPIL_REMAP     STRING    'disp2d'
   READ_METHOD     STRING    'restore-trs'
   DATA_SUFFIX     STRING    '.dat'
   DATA_DIM        STRING    '2D'
   SCALING_FOR_NM_PHASE
                   FLOAT           470.000
   DMTRANS_MULFAC  FLOAT     Array[26, 26]
   GAIN            FLOAT          0.500000
   INTEGRATOR_C    FLOAT          0.990000
   TAU             FLOAT       0.000890000
%

The signal DMTRANS_MULFAC is the Fourier transform filter
that describes the influence function of the deformable mirror.
This is used in Fourier analysis.



**********************************************************************
******* At this point if you want to explore an algorithm that uses the 
closed-loop DM commands to identify the wind layers, you should write a
procedure to do so. I've encluded a simple example to get you going in

process_phase_example.pro



**********************************************************************
******* To proceed with the Fourier wind identification run the 
following:

IDL> process_fmodes, obs ;; ;obs is your structure

This will read the fourier modes in, convert to frequency space, 
estimate the temporal PSDs of each Fourier mode via
periodograms, then remove the influence of the DM and 
convert from closed-loop to estimated open-loop measurements
of the atmosphere plus noise.

Then this will run the identification algorithms.

The first step is fitting the PSDs and finding peaks.
This is done with 

IDL>   fit_data = find_and_fit_peaks_nodc(atm_psds)

This returns a structure that contains all the fit info

IDL> help, fit_data
** Structure <5209808>, 9 tags, length=11148592, data length=11148592, refs=1:
   ALPHA_DC        FLOAT     Array[26, 26]
   VARIANCE_DC     FLOAT     Array[26, 26]
   RMS_DC          FLOAT     Array[26, 26]
   ALPHAS_PEAKS    FLOAT     Array[26, 26, 6]
   VARIANCE_PEAKS  FLOAT     Array[26, 26, 6]
   RMS_PEAKS       FLOAT     Array[26, 26, 6]
   EST_OMEGAS_PEAKS
                   FLOAT     Array[26, 26, 6]
   FIT_ATM_PSDS    FLOAT     Array[26, 26, 2048]
   FIT_ATM_PEAKS_PSDS
                   FLOAT     Array[26, 26, 2048]

These include the low-order (DC) model, the locations
and power levels of the found peaks, and our model fit to the
PSDs.

If you'd like to examine these, pick a mode by k and l (from 0 to (obs.n-1))
and plot it as follows:

IDL> k = 5
IDL> l = obs.n - 5
IDL> make_plot_psd, hz, atm_psds, k, l ;; plot the data's PSD
IDL> make_plot_psd, hz, fit_data.fit_atm_psds, k, l, over=250 ;; overplot our model fit

If you want a list of the temporal frequencies of the peaks, do 
as follows:

IDL> peaks_hz = fit_data.est_omegas_peaks/(2*!pi)*obs.rate
IDL> print, peaks_hz[k,l,*]


Now that we've identified the peaks, we use these to find layers by
matching finding planes peaks across fx and fy that are consistent with
a layer of wind translating across the pupil.

This is done with

IDL> wind_data = find_and_fit_layers(fit_data.est_omegas_peaks/(2*!pi)*obs.rate, ca)

This is a brute-force search - for each possible <vx,vy> vector,
the code calculates where the peaks should be in temporal frequency 
for each Fourier mode. Then it sees how many of those peaks were actually
found. This produces a "windmap" of the likelihood of a layer at a velocity.

IDL> help, wind_data
** Structure <732c028>, 4 tags, length=104988, data length=104988, refs=1:
   VX              FLOAT     Array[161]
   VY              FLOAT     Array[161]
   METRIC          FLOAT     Array[161, 161]
   LAYER_LIST      FLOAT     Array[4]

This is returned in wind_data.metric

Then a second function finds the layers from the map. This
uses IDL's built-in watershed algorithm. The results of this
are returned in wind_data.layer_list.
Right now each layer has four entries: vx (m/s), vy (m/s),
likelihood (0-1) and a fourth field which is presently blank.


There are some visualization routines that help you interpret the data.

To look at the windmap with the found layers, use:

IDL> make_wind_map, wind_data, obs

To look at the peaks on a color-coded mapping in frequency space
and see just how well the layers were identified, use:

IDL>   make_layer_freq_image, fit_data, wind_data, obs


This produces a multi-panel image of all the peaks and how well
they match the theory.









