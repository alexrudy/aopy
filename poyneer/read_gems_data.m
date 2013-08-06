pkg load fits
load data/gems/raw/phf11106030531.mat
save_fits_image('data/gems/raw/phf11106030531_time.fits', rtcTimeStamp)
save_fits_image('data/gems/raw/phf11106030531_phase.fits', lgsFilteredPhases*MicronsPerPhaseBit(1))


pkg load fits
load data/gems/raw/phf11109092452.mat
save_fits_image('data/gems/raw/phf11109092452_time.fits', rtcTimeStamp)
save_fits_image('data/gems/raw/phf11109092452_phase.fits', lgsFilteredPhases*MicronsPerPhaseBit(1))





pkg load fits
load data/gems/raw/slp11106030531.mat
save_fits_image('data/gems/raw/slp11106030531_time.fits', rtcTimeStamp)
save_fits_image('data/gems/raw/slp11106030531_slopes.fits', lgsSlopes*ArcSecondsPerSlopeBit(1))

pkg load fits
load data/gems/raw/slp11109092452.mat
save_fits_image('data/gems/raw/slp11109092452_time.fits', rtcTimeStamp)
save_fits_image('data/gems/raw/slp11109092452_slopes.fits', lgsSlopes*ArcSecondsPerSlopeBit(1))



pkg load fits
load data/gems/raw/myst_lgscmat_11109092452.mat
