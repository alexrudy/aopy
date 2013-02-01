;; CVS header information for IDL files
;; $Revision: 1.6 $
;; $Author: poyneer1 $
;; $Date: 2011/11/03 23:25:43 $


;; ****** OFFICIAL USE ONLY ***************
;; May be exempt from public release under the 
;; Freedom of Information Act (5 U.S.C 552), 
;; exemption and category 4: Commercial.
;; 
;; ****** IMPORTANT RESTRICTIONS **********
;; This code is for strictly limited release 
;; within the Gemini Planet Imager project and 
;; may not be made publicly available. Under EAR99,
;; there are restrictions on the availability of this
;; code to foreign nationals. Please contact 
;; Lisa Poyneer <poyneer1@llnl.gov>.
;; ****************************************


;; --------------------------------------------------------
;; This work was performed under the auspices of the U.S. Department of 
;; Energy by the University of California, Lawrence Livermore National 
;; Laboratory under contract No. W-7405-Eng-48.
;; OR 
;; This work performed under the auspices of the U.S. Department of Energy 
;; by Lawrence Livermore National Laboratory under Contract DE-AC52-07NA27344.

;; Developed by Lisa A. Poyneer 2001-2008
;; No warranty is expressed or implied.
;; --------------------------------------------------------

;; this is a helper since I am always making these stupid 
;; x and y-indices grids!!!!!


pro generate_freq_grids, xgrid, ygrid, n, scale=sfac


    xgrid = make_array(n,n,double=doubleflag)
    for j=0, n-1 do xgrid[j,*] = j - (j GT n/2)*n
    if keyword_set(sfac) then xgrid = xgrid*sfac
    xgrid[n/2,*] = -xgrid[n/2,*]
    ygrid = transpose(xgrid)
    


end


