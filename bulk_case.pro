

for i=0,30 do begin
    obs = get_case_altair(i)
    process_raw_data, obs
    process_fmodes, obs
    process_phase, obs
endfor