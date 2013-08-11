# -*- coding: utf-8 -*-
# 
#  zernike.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-08-09.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
"""
:mod:`zernike` – Zernike Polynomials
====================================

The `zernike polynomials`_ are a modal basis set defined on a circular aperture, and so are useful for optics.


.. _zernike polynomials: http://en.wikipedia.org/wiki/Zernike_polynomials
"""


from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

from scipy.misc import factorial

def zernike_rho(n, m, rho):
    r"""Calculate the radial component of the zernike polynomial.
    
    This is defined piecewise. For :math:`m-n` odd, the radial component is defined as 0.
    For :math:`m-n` even, they are defined as
    
    .. math::
        
        R_{n}^{m}(\rho) = \sum_{k=0}^{(n-m)/2} \frac{(-1)^k (n-k)!}{k! ((n+m)/2 - k)! ((n-m)/2 - k)!} \rho^{n-2k}
        
    """
    
    # The Zernike Polynomials are identically 0 for (m-n) odd.
    if np.mod(n-m, 2) == 1:
        return np.zeros_like(rho)
        
    kmax = (n-m)/2    
    ks = np.arange(0, kmax + 1, 1)
    kterm = zernike_ks(n, m, ks)
    R = np.power(rho[...,np.newaxis], n - 2.0 * ks) * kterm
    return np.sum(R, axis=-1)

def zernike_ks(n, m, ks):
    """The zernike factorial terms."""
    return ((-1.0)**ks * factorial(n-ks)) / (factorial(ks) * factorial((n+m)/2.0 - ks) * factorial((n-m)/2.0 - ks))
    
def zernike_rho_slope(n, m, rho):
    """Zernike radial slope"""
    # if np.mod(n-m, 2) == 1:
    #     return np.zeros_like(rho)
    kmax = (n-m)/2
    ks = np.arange(0, kmax + 1)
    ks = ks[(2*ks != n)]
    kterm = zernike_ks(n, m, ks)
    Rp = np.power(rho[...,np.newaxis], n - 2.0 * ks - 1 ) * (n - 2.0 * ks) * kterm
    return np.sum(Rp, axis=-1)
    
def zernike_phi_slope(n, m, rho):
    """Zernike phi slope"""
    # if np.mod(n-m, 2) == 1:
    #     return np.zeros_like(rho)
    kmax = (n-m)/2.0
    ks = np.arange(0.0, kmax + 1)
    ks = ks[(2*ks != n)]
    kterm = zernike_ks(n, m, ks)
    Rthetap = np.power(rho[...,np.newaxis], n - 2.0 * ks ) * kterm
    return np.sum(Rthetap, axis=-1)
    
def zernike_slope(n, m, rho, phi):
    """docstring for zernike_slope"""
    if m > 0:
        S_rho = zernike_rho_slope(n, m, rho) * np.cos(m * phi)
        S_phi = zernike_phi_slope(n, m, rho) * -m * np.sin(m * phi)
    elif m < 0:
        S_rho = zernike_rho_slope(n, -m, rho) * np.sin( -m * phi)
        S_phi = zernike_phi_slope(n, -m, rho) * -m * np.cos(m * phi)
    else:
        S_rho = zernike_rho_slope(n, 0, rho)
        S_phi = np.zeros_like(S_rho)
    return S_rho, S_phi
    
def zernike_slope_cartesian(n, m, X, Y):
    """docstring for zernike_slope_cartesian"""
    Rho, Phi = cartesian_to_polar(X, Y)
    S_rho, S_phi = zernike_slope(n, m, Rho, Phi)
    X_s = np.sin(Phi) * S_rho + np.cos(Phi) * S_phi / Rho
    Y_s = np.cos(Phi) * S_rho - np.sin(Phi) * S_phi / Rho
    return X_s, Y_s


def zernike_polar(n, m, rho, phi):
    """Calculate the zernike polynomial.
    
    This is defined by
    
    .. math::
        
        Z_{n}^{m}(\rho,\varphi) = R_{n}^{m}(\rho) \cos(m \varphi)
        
        Z_{n}^{-m}(\rho,\varphi) = R_{n}^{m}(\rho) \sin(m \varphi)
        
    """
    if m > 0:
        return zernike_rho(n, m, rho) * np.cos(m * phi)
    elif m < 0:
        return zernike_rho(n, -m, rho) * np.sin(-m * phi)
    else:
        return zernike_rho(n, 0, rho)
    
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
    
def zernikej(j, rho, phi):
    """
    Calculate the jth linear Noll indexed Zernike mode.
    """
    n, m = noll_to_zern(j)
    return zernike_polar(n, m, rho, phi)
    
def zernike_cartesian(j, X, Y):
    """
    Calculate the zernike polynomials on a cartesian grid.
    """
    Rho, Phi = cartesian_to_polar(X, Y)
    return zernikej(j, Rho, Phi)
    
def zernike(j, size):
    """Calculate zernike modes on a cartesian grid of a specified size."""
    pass
    
def cartesian_to_polar(X, Y):
    """Cartesian to polar"""
    rho = np.sqrt(X**2 + Y**2)
    phi = np.arctan2(Y, X)
    return rho, phi
    
def polar_to_cartesian(Rho, Phi):
    """Polar to cartesian"""
    X = np.cos(Phi) * Rho
    Y = np.sin(Phi) * Rho
    return X, Y
    
def _find_triangular_number(n_items):
    """Find the triangular number that fits the given number of items."""
    from scipy.special import binom
    n = 1
    T_n = 1
    while T_n < n_items:
        n = n + 1
        T_n = binom(n+1, 2)
    return (n, T_n)
        
    
def zernike_triangle(figure=None, max_noll=16, size=40, radius=18):
    """Make a zernike triangle diagram"""
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
        Z = zernike_cartesian(j, X, Y)
        ax = figure.add_subplot(gs[n,x-1:x+1])
        Z[ap != 1] = np.nan
        ax.imshow(Z, interpolation='nearest')
        ax.get_xaxis().set_visible(False)
        ax.get_yaxis().set_visible(False)
        ax.set_title("Zernike ({:d},{:d})".format(n, m))
        
def zernike_slope_triangle(figure=None, max_noll=16, size=40, radius=18):
    """Make a zernike slope triangle diagram"""
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