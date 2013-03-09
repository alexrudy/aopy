!PATH=EXPAND_PATH('<IDL_DEFAULT>')
!PATH=!PATH+":"+expand_path("+.")
!PATH=!PATH+":"+expand_path("+~/Development/Astronomy/IDL/astron")
!PATH=!PATH+":"+expand_path("~/Development/Astronomy/IDL/don_pro")
!PATH=!PATH+":"+expand_path("~/Development/Astronomy/IDL/don_pro/StarFinder")
!PATH=!PATH+":"+expand_path("~/Development/Astronomy/IDL/don_pro/thompson")
!PATH=!PATH+":"+expand_path("../Images")
device, decompose=0
device, retain=2
; loadct, 5
imagelib
devicelib
; !edit_input = 128