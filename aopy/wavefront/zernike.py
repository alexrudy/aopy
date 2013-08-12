# -*- coding: utf-8 -*-
# 
#  zernike.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-08-09.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
"""
:mod:`wavefront.zernike` – Zernike Polynomials
==============================================

The `zernike polynomials`_ are a modal basis set defined on a circular aperture, and so are useful for optics.
They are defined in an even/odd fashion, with the following convention

.. math::
    
    Z_{n}^{m}(\\rho,\\varphi) = R_{n}^{m}(\\rho) \cos(m \\varphi)
    
    Z_{n}^{-m}(\\rho,\\varphi) = R_{n}^{m}(\\rho) \sin(m \\varphi)

where :math:`R_{n}^{m}` is given by

.. math::
    
    R_{n}^{m}(\\rho) = \sum_{k=0}^{(n-m)/2} \\frac{(-1)^k (n-k)!}{k! ((n+m)/2 - k)! ((n-m)/2 - k)!} \\rho^{n-2k}
    

For all of the functions below, the zernike polynomial is calculated assuming a radius of 1. Radii or indicies should be scaled appropriately to the desired aperture.


Calculating Zernike Polynomials
-------------------------------

.. autofunction:: zernike_polar

.. autofunction:: zernike_cartesian

.. autofunction:: zernike_noll_polar

.. autofunction:: zernike_noll_cartesian


Calculating Zernike Slopes
--------------------------

.. autofunction:: zernike_slope_polar

.. autofunction:: zernike_slope_cartesian

Index Conversion Tools
----------------------

.. autofunction:: noll_to_zern

.. autofunction:: zern_to_noll

Zernike Triangle Diagrams
-------------------------

A triangle of zernike polynomials is often set out like Pascal's triangle. These functions do that in matplotlib.

.. autofunction:: zernike_triangle

.. autofunction:: zernike_slope_triangle

Zernike Utility Functions
-------------------------

These functions are used internally to calculated the Zernike polynomials. They are used to prevent repetitive input of calculations and reduce errors.

.. autofunction:: zernike_ks

.. autofunction:: zernike_rho

.. autofunction:: zernike_rho_slope

.. autofunction:: zernike_phi_slope

.. _zernike polynomials: http://en.wikipedia.org/wiki/Zernike_polynomials
"""


from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

from scipy.misc import factorial

def zernike_ks(n, m):
    r"""
    The zernike factorial terms.
    
    :param n: Zernike `n` index.
    :param m: Zernike `m` index.
    :returns: ``(ks, kterm)`` where ``kterm`` is the math below, and ``ks`` is the vector in k-space.
    
    .. math::
        
        \sum_{k=0}^{(n-m)/2} \frac{(-1)^k (n-k)!}{k! ((n+m)/2 - k)! ((n-m)/2 - k)!}
        
    
    """
    ks = np.arange(0, (n-m)/2 + 1)
    ks = ks[(2*ks != n)]
    kterm = ((-1.0)**ks * factorial(n-ks)) / (factorial(ks) * factorial((n+m)/2.0 - ks) * factorial((n-m)/2.0 - ks))
    return ks, kterm

def zernike_rho(n, m, Rho):
    r"""
    Calculate the radial component of the zernike polynomial, often called :math:`R_{n}^{m}`.
    
    :param n: Zernike `n` index.
    :param m: Zernike `m` index.
    :param Rho: The radii on which to calculate.
    :returns: The :math:`R_{n}^{m}` zernike component.
    
    This is defined piecewise. For :math:`m-n` odd, the radial component is defined as 0.
    For :math:`m-n` even, they are defined as
    
    .. math::
        
        R_{n}^{m}(\rho) = \sum_{k=0}^{(n-m)/2} \frac{(-1)^k (n-k)!}{k! ((n+m)/2 - k)! ((n-m)/2 - k)!} \rho^{n-2k}
        
    """
    # The Zernike Polynomials are identically 0 for (m-n) odd.
    if np.mod(n-m, 2) == 1:
        return np.zeros_like(Rho)
    ks, kterm = zernike_ks(n, m)
    R = np.power(Rho[...,np.newaxis], n - 2.0 * ks) * kterm
    return np.sum(R, axis=-1)
    
def zernike_rho_slope(n, m, Rho):
    r"""
    Zernike radial slope.
    
    :param n: Zernike `n` index.
    :param m: Zernike `m` index.
    :param Rho: The radii on which to calculate.
    
    .. math::
        
        \frac{\partial R_{n}^{m}}{\partial \rho}
    
    """
    ks, kterm = zernike_ks(n, m)
    Rp = np.power(Rho[...,np.newaxis], n - 2.0 * ks - 1 ) * (n - 2.0 * ks) * kterm
    return np.sum(Rp, axis=-1)
    
def zernike_phi_slope(n, m, Rho):
    r"""
    Zernike Phi slope.
    
    :param n: Zernike `n` index.
    :param m: Zernike `m` index.
    :param Rho: The radii on which to calculate.
    
    .. math::
        
        \frac{\partial R_{n}^{m}}{\partial \varphi}
    
    """
    ks, kterm = zernike_ks(n, m)
    Rthetap = np.power(Rho[...,np.newaxis], n - 2.0 * ks ) * kterm
    return np.sum(Rthetap, axis=-1)
    
def zernike_polar(n, m, Rho, Phi):
    r"""
    Calculate the zernike polynomial in polar coordinates. The radius of the polynomial is 1.
    
    :param n: Zernike `n` index.
    :param m: Zernike `m` index.
    :param Rho: The radii on which to calculate.
    :param Phi: The angles on which to calculate.
    
    This is defined by
    
    .. math::
        
        Z_{n}^{m}(\rho,\varphi) = R_{n}^{m}(\rho) \cos(m \varphi)
        
        Z_{n}^{-m}(\rho,\varphi) = R_{n}^{m}(\rho) \sin(m \varphi)
        
    where
    
    .. math::
        
        R_{n}^{m}(\rho) = \sum_{k=0}^{(n-m)/2} \frac{(-1)^k (n-k)!}{k! ((n+m)/2 - k)! ((n-m)/2 - k)!} \rho^{n-2k}
        
    """
    if m > 0:
        return zernike_rho(n, m, Rho) * np.cos(m * Phi)
    elif m < 0:
        return zernike_rho(n, -m, Rho) * np.sin(-m * Phi)
    else:
        return zernike_rho(n, 0, Rho)
    
def zernike_slope_polar(n, m, Rho, Phi):
    """
    Calculate the slope of the Zernike polynomials in polar coordinates.
    
    :param n: Zernike `n` index.
    :param m: Zernike `m` index.
    :param Rho: The radii on which to calculate.
    :param Phi: The angles on which to calculate.
    :returns: ``S_Rho, S_Phi``, the pair of radial and angular slopes.
    
    """
    if m > 0:
        S_Rho = zernike_rho_slope(n, m, Rho) * np.cos(m * Phi)
        S_Phi = zernike_phi_slope(n, m, Rho) * -m * np.sin(m * Phi)
    elif m < 0:
        S_Rho = zernike_rho_slope(n, -m, Rho) * np.sin( -m * Phi)
        S_Phi = zernike_phi_slope(n, -m, Rho) * -m * np.cos(m * Phi)
    else:
        S_Rho = zernike_rho_slope(n, 0, Rho)
        S_Phi = np.zeros_like(S_Rho)
    return S_Rho, S_Phi
    
    
def zernike_cartesian(n, m, X, Y):
    """
    Calculate the zernike polynomials on a cartesian grid.
    
    :param n: Zernike `n` index.
    :param m: Zernike `m` index.
    :param X: The X on which to calculate.
    :param Y: The Y on which to calculate.
    
    """
    Rho, Phi = cartesian_to_polar(X, Y)
    return zernike_polar(n, m, Rho, Phi)

def zernike_slope_cartesian(n, m, X, Y):
    """
    Calculate the zernike polynomial slopes on a cartesian grid.
    
    :param n: Zernike `n` index.
    :param m: Zernike `m` index.
    :param X: The X on which to calculate.
    :param Y: The Y on which to calculate.
    
    """
    Rho, Phi = cartesian_to_polar(X, Y)
    S_Rho, S_Phi = zernike_slope_polar(n, m, Rho, Phi)
    X_s = np.sin(Phi) * S_Rho + np.cos(Phi) * S_Phi / Rho
    Y_s = np.cos(Phi) * S_Rho - np.sin(Phi) * S_Phi / Rho
    return X_s, Y_s
    
def noll_to_zern(j):
    """
    Convert from linear Noll index to a tuple of Zernike indicies.
    
    :param int j: Linear Noll Index
    
    """
    if (j <= 0):
        raise ValueError("Noll indices start at 1.")
    
    n = 0
    j1 = j-1
    while (j1 > n):
        n += 1
        j1 -= n

    m = (-1)**j * ((n % 2) + 2 * int((j1+((n+1) % 2)) / 2.0 ))
    return (n, m)

def zern_to_noll(n, m):
    """
    Convert a Zernike index pair, (n,m) to a Linear Noll index.
        
    :param n: Zernike `n` index.
    :param m: Zernike `m` index.
    
    """
    j = 1
    jmax = 2 * n
    while (j < jmax):
        nf, mf = noll_to_zern(j)
        if nf == n and mf == m:
            return j
        else:
            j += 1
    raise ValueError("Searched {:d} Noll indicies, no (n={:d},m={:d}) pair found!".format(jmax, n, m))
    
def zernike_noll_polar(j, Rho, Phi):
    """
    Calculate the jth linear Noll indexed Zernike mode.
    
    :param j: The noll index.
    :param Rho: The radii on which to calculate.
    :param Phi: The angles on which to calculate.
    
    """
    n, m = noll_to_zern(j)
    return zernike_polar(n, m, Rho, Phi)
    
def zernike_noll_cartesian(n, m, X, Y):
    """
    Calculate the jth linear Noll indexed Zernike mode.
    
    :param j: The noll index.
    :param X: The X on which to calculate.
    :param Y: The Y on which to calculate.
    
    """
    Rho, Phi = cartesian_to_polar(X, Y)
    return zernike_noll_polar(j, Rho, Phi)
    
def cartesian_to_polar(X, Y):
    """
    Convert a coordinate grid/pair from cartesian to polar coordinates.
    
    :param X: The X to convert.
    :param Y: The Y to convert.
    :return: ``Rho, Phi``, the radial and angular components.
    
    """
    Rho = np.sqrt(X**2 + Y**2)
    Phi = np.arctan2(Y, X)
    return Rho, Phi
    
def polar_to_cartesian(Rho, Phi):
    """
    Convert a coordinate grid/pair from polar to cartesian coordinates.
    
    :param Rho: The radial component to convert.
    :param Phi: The angular component to convert.
    :return: ``X, Y``, the X and Y components.
    
    """
    X = np.cos(Phi) * Rho
    Y = np.sin(Phi) * Rho
    return X, Y
    
def _find_triangular_number(n_items):
    """
    Find the next largest triangular number that fits the given number of items.
    
    Returns `(n, T_n)`, where `T_n` is the triangular number, and `n` is the number of rows in the triangle.
    """
    from scipy.special import binom
    n = 1
    T_n = 1
    while T_n < n_items:
        n = n + 1
        T_n = binom(n+1, 2)
    return (n, T_n)
        
    
def zernike_triangle(figure=None, noll=16, size=40, radius=18):
    """
    Make a zernike triangle diagram.
    
    :param figure: The matplotlib figure instance to use.
    :param int noll: The maximum linear noll index zernike mode to display. This number will be increased up to the next triangular number.
    :param int size: The size of the grid to use.
    :param int radius: The radius scaling to use.
    
    """
    import matplotlib.gridspec
    if figure is None:
        import matplotlib.pyplot
        figure = matplotlib.pyplot.figure()
    
    X, Y = np.mgrid[-size/2:size/2,-size/2:size/2] / radius
    ap = (np.sqrt(X**2 + Y**2) < 1.0).astype(np.int)
    
    
    rows, figures = _find_triangular_number(max_noll)
    cols = (rows * 2)
    
    gs = matplotlib.gridspec.GridSpec(rows, cols)
    
    for j in range(1,int(figures)+1):
        n, m = noll_to_zern(j)
        x = rows + m
        Z = zernike_noll_cartesian(j, X, Y)
        ax = figure.add_subplot(gs[n,x-1:x+1])
        Z[ap != 1] = np.nan
        ax.imshow(Z, interpolation='nearest')
        ax.get_xaxis().set_visible(False)
        ax.get_yaxis().set_visible(False)
        ax.set_title("Zernike ({:d},{:d})".format(n, m))
        
def zernike_slope_triangle(figure=None, max_noll=16, size=40, radius=18):
    """
    Make a zernike slope triangle diagram
    
    :param figure: The matplotlib figure instance to use.
    :param int noll: The maximum linear noll index zernike mode to display. This number will be increased up to the next triangular number.
    :param int size: The size of the grid to use.
    :param int radius: The radius scaling to use.
    
    """
    import matplotlib.gridspec
    if figure is None:
        import matplotlib.pyplot
        figure = matplotlib.pyplot.figure()
    
    X, Y = np.mgrid[-size/2:size/2,-size/2:size/2] / radius
    ap = (np.sqrt(X**2 + Y**2) < 1.0).astype(np.int)
    
    
    rows, figures = _find_triangular_number(max_noll)
    cols = (rows * 4)
    
    gs = matplotlib.gridspec.GridSpec(rows, cols)
    
    for j in range(1,int(figures)+1):
        n, m = noll_to_zern(j)
        x = 2 * rows + 2 * m
        Z_x, Z_y = zernike_slope_cartesian(n, m, X, Y)
        ax_x = figure.add_subplot(gs[n,x-2:x])
        Z_x[ap != 1] = np.nan
        ax_x.imshow(Z_x, interpolation='nearest')
        ax_x.get_xaxis().set_visible(False)
        ax_x.get_yaxis().set_visible(False)
        ax_x.set_title("X Slopes ({:d},{:d})".format(n, m))
        ax_y = figure.add_subplot(gs[n,x:x+2])
        Z_y[ap != 1] = np.nan
        ax_y.imshow(Z_y, interpolation='nearest')
        ax_y.get_xaxis().set_visible(False)
        ax_y.get_yaxis().set_visible(False)
        ax_y.set_title("Y Slopes ({:d},{:d})".format(n, m))