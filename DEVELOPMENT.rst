Development
===========

Below are things that I need to do to improve the performance of the WCAO/FMTS libraries.


Pairity with IDL
----------------
- Match Fitting Performance to IDL libraries
- Match Simulated Data Performance to IDL libraries
- Make IDL respect directory structures
- IDL-YAML interaction?

Things that are broken
----------------------
- Configfile loading, especially ad-hoc config files in the working directory
- Sanitizing or Generating Telemetry Data.

Improvements to Internal Algorithms
-----------------------------------
- Variable Weighting Algorithms
- Log/Log Fitting routines
- Log/Linear Fitting routines

Documentation
-------------
- add ``automodapi`` support.

Diagnostic Tools
----------------
- Comparison Tools for IDL results
- Peak Fitting Diagnostic with Residuals
- Interactive Peak Fitting Exploration Tool
- Interactive layer matching tool

Data Structures and Features
----------------------------
- Generalized Transfer Function Models
- Generalized Fitting Tools
- Variable Gain TF Models
- TF Model Persistance
- Closer linking of the various PSD grids to each other.

Refactoring
-----------
- 'analysis' module should change names.
- 'controllers' should be rethought
- API interface for use on the test bench.
- Restructuring for continuous intake of data
- Cases should be encapsulated in SQLite
- Cases could be held on a server, and downloaded when needed
- Configuration could be subdivided:
    - Information relevant to the particular instrument
    - Information relevant to the specific case
    - Information relevant to the algorithm
    - General, possibly unused, configuration of classes etc.

Plans
=====

