!PATH=!PATH+":"+expand_path("+~/Development/Astronomy/IDL/don_pro")
!PATH=!PATH+":"+expand_path("+~/Development/Astronomy/IDL/astron")
!PATH=!PATH+":"+expand_path("~/Development/Astronomy/WindPrediction/Images")
!PATH=!PATH+":"+expand_path("~/Development/Astronomy/WindPrediction/telem_analysis_13")
device, decompose=0
device, retain=2
loadct, 5
imagelib
devicelib
; !edit_input = 128