.. module::
    aopy

:mod:`AOPY` – Adaptive Optics in PYthon
=======================================

This module provides tools for working on Adaptive Optics systems in Python.


.. _astropy-units:
Using :mod:`astropy.units`
--------------------------

Most phyiscal quantities in :mod:`aopy` will accept an instance of :class:`astropy.units.Quantity` and will return, regardless of what is installed originally, an instance of :class:`astropy.units.Quantity`. This helps to reduce ambiguities in using units at different scailings. By including units in your own code, you can ensure that you are using parameters correctly. You can even insert units that are unexpected, and if possible, :mod:`astropy.units` will convert them to the correct unit.

Information on :mod:`astropy.units` is available at <http://docs.astropy.org/en/stable/units/index.html>.

Here is a simple example of the units module::
    
    >>> from astropy import units as u
    >>> r0quantity = 30 * u.cm
    <Quantity 30 cm>
    >>> rate = 1000 * 1 / u.s
    <Quantity 1000 1/s>
    >>> rate.to('Hz')
    <Quantity 1000 Hz>
    >>> r0quantity.to("meter")
    <Quantity 0.30 m>
    