Development
===========

Below are things that I need to do to improve the performance of the WCAO/FMTS libraries.

Data Manipulation
-----------------
- Rewrite MCAOIngest to handle new file formats.
- Object Model for MCAOIngest

Pairity with IDL
----------------
- Match Fitting Performance to IDL libraries [DONE]
- Match Simulated Data Performance to IDL libraries
- Make IDL respect directory structures
- IDL-YAML interaction?

IDL Library Improvements
------------------------
- IO using python library format [PARTIAL]

Things that are broken
----------------------
- Configfile loading, especially ad-hoc config files in the working directory [Mostly FIXED]
- Sanitizing or Generating Telemetry Data. [FIXED]
- There is a 90º rotation somewhere in the code for displaying / fitting peaks.

Improvements to Internal Algorithms
-----------------------------------
- Arbitrary and periodic periodogram masks
- Variable Weighting Algorithms
- Log/Log Fitting routines
- Log/Linear Fitting routines

Documentation
-------------
- add ``automodapi`` support.
- automatic overwriting of log files / many log file management.

Diagnostic Tools
----------------
- Comparison Tools for IDL results
- Peak Fitting Diagnostic with Residuals [DONE]
- Interactive Peak Fitting Exploration Tool
- Interactive Found Peaks tool [DONE]
- Interactive layer matching tool [DONE]
- Residuals timeseries examination and periodgram masking diagnostics

Data Structures and Features
----------------------------
- Generalized Transfer Function Models
- Generalized Fitting Tools
- Variable Gain TF Models
- TF Model Persistance
- Closer linking of the various PSD grids to each other.
- Better memory controls. MMAP'd large files? Removing old telemetry? [FIX started]
- Management of Units (Real / Simulated 3.0m / NGAO sized?)

Refactoring
-----------
- 'analysis' module should change names.
- 'controllers' should be rethought
- API interface for use on the test bench.
- Restructuring for continuous intake of data.
- Threading of all operations - No main thread computation.
- Cases should be encapsulated in SQLite
- Cases could be held on a server, and downloaded when needed
- Configuration could be subdivided:
    - Information relevant to the particular instrument
    - Information relevant to the specific case
    - Information relevant to the algorithm
    - General, possibly unused, configuration of classes etc.
- Sub-data products should appear as first class data products, and link via dictionaries to their children.
- Classes should be self-configured in one place by meta-classes. I.E. you should set all of the configuration items from the YAML file on the class itself. The YAML file should still override those values, but the defaults should be held in the classes and a registry-built metaclass.
- IO and other subclasses should be refactored to be classified.

