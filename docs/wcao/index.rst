:mod:`wcao` - Wind-Controller Adaptive Optics
=============================================

.. module:: wcao

:mod:`wcao` provides classes to understand and use the wind-detected and predicted adaptive optics control scheme. The module is primarily designed for use with telemetry data taken on AO systems, rather than real-time data.

To use :mod:`wcao`, you'll need a specific data case, which will be an instance of :class:`wcao.data.core.WCAOCase`. As well, you'll want to pass this data case through an estimator object, which will be an instance of :class:`wcao.estimators.core.BaseEstimator`. Estimators carry out thier calculations on telemetry data stored in the data case class. The results of the estimation scheme are reported back to the original data case in the data case's results object. 

A simple script might be as follows::
    
    Data = WCAOCase("Telescope","01012011",(WCAOCase.__module__,'telemetry.yml'))
    Plan = Estimator().setup(Data)
    Plan.estimate()
    Plan.finish()
    Data.results["FT"].show()
    

In this script, the initial ``Data`` object holds all of the telemetry information, and holds the results in the end.

