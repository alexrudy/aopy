# -*- coding: utf-8 -*-
# 
#  test_fft.py
#  aopy
#  
#  Created by Jaberwocky on 2013-09-10.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import nose.tools as nt
from nose.plugins.skip import SkipTest
from nose.plugins.attrib import attr
import numpy as np

import os, os.path

import matplotlib.pyplot as plt

from .util import npeq_, PIDLYTests, npeq_or_save

@attr('fft')
class test_ffts(PIDLYTests):
    """Compare FFTs"""
    
    def setup(self):
        """Set up the FFTs"""
        super(test_ffts, self).setup()
        
        self.arrays = {}
        
        self.arrays["ones"] = np.ones((40))
        self.arrays["inds"] = np.arange(40)
        self.arrays["2d"] = np.arange((100)).reshape((10,10))
        
    def test_fft_arange(self):
        """FFT on 1D data"""
        
        import scipy.fftpack
        
        py_fft = scipy.fftpack.fft(self.arrays["inds"]) / self.arrays['inds'].shape[0]
        
        self.IDL.data = self.arrays["inds"]
        self.IDL('idl_fft = fft(data)')
        self.IDL('idl_fft_r = real_part(idl_fft)')
        self.IDL('idl_fft_i = imaginary(idl_fft)')
        idl_fft = self.IDL.idl_fft_r + 1j * self.IDL.idl_fft_i
        
        if not np.allclose(idl_fft, py_fft):
            plt.subplot(2,1,1)
            plt.plot(np.real(py_fft), label="Python")
            plt.plot(np.real(idl_fft), label="IDL")
            plt.legend()
            plt.subplot(2,1,2)
            plt.plot(np.imag(py_fft), label="Python")
            plt.plot(np.imag(idl_fft), label="IDL")
            plt.legend()
            plt.show()
        
        assert np.allclose(idl_fft, py_fft)
        
    def test_fft_2d(self):
        """FFT on 2D data"""
        import scipy.fftpack
        
        py_fft = scipy.fftpack.fftn(self.arrays["2d"]) / self.arrays['2d'].size
        
        self.IDL.data = self.arrays["2d"]
        self.IDL('idl_fft = fft(data)')
        self.IDL('idl_fft_r = real_part(idl_fft)')
        self.IDL('idl_fft_i = imaginary(idl_fft)')
        idl_fft = self.IDL.idl_fft_r + 1j * self.IDL.idl_fft_i
        
        if not np.allclose(idl_fft, py_fft, atol=1e-6):
            plt.subplot(2,1,1)
            plt.plot(np.real(py_fft[3,:]), label="Python")
            plt.plot(np.real(idl_fft[3,:]), label="IDL")
            plt.legend()
            plt.subplot(2,1,2)
            plt.plot(np.imag(py_fft[3,:]), label="Python")
            plt.plot(np.imag(idl_fft[3,:]), label="IDL")
            plt.legend()
            plt.figure()
            plt.subplot(1,2,1)
            plt.title("Real")
            plt.imshow(np.real(py_fft - idl_fft))
            plt.colorbar()
            plt.subplot(1,2,2)
            plt.title("Imaginary")
            plt.imshow(np.imag(py_fft - idl_fft))
            plt.colorbar()
            plt.show()
        
        idl_fft_c, py_fft_c = idl_fft[0,:], py_fft[0,:]
        assert np.allclose(idl_fft_c, py_fft_c)
        assert np.allclose(idl_fft, py_fft, atol=1e-6)
        