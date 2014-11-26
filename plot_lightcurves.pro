function get_goes, file

	readcol, file, y, m, d, hhmm, mjd, sod, short_channel, long_channel

	;-------- Time in correct format --------
	time  = strarr(n_elements(y))
	time[*] = string(y[*], format='(I04)') + string(m[*], format='(I02)') $
		  + string(d[*], format='(I02)') + '_' + string(hhmm[*], format='(I04)')

	;------ Get start and stop indices -----
	time = anytim(file2time(time), /utime)
	
	goes_array = dblarr( 3, n_elements(time) )
	goes_array[0, *] = time
	goes_array[1, *] = long_channel
	goes_array[2, *] = short_channel

	return, goes_array
	
END

pro plot_goes, goes, tstart, tend

	utplot, goes[0,*], goes[1,*], $
		psym=3, $
		title='1-minute GOES-15 Solar X-ray Flux', $
		/xs, $
		yrange=[1e-9, 1e-3], $
		/ylog, $
		ytitle = 'Watts m!U-2!N', $
		xrange = [tstart, tend]
		

	outplot, goes[0,*], goes[1,*], color=3 ;for some reason utplot won't color the line

	axis,yaxis=1,ytickname=[' ','A','B','C','M','X',' ']
	axis,yaxis=0,yrange=[1e-9,1e-3]

	;plots, goes[0,*], 1e-8
	;plots, goes[0,*], 1e-7
	;plots, goes[0,*], 1e-6
	;plots, goes[0,*], 1e-5
	;plots, goes[0,*], 1e-4
	outplot, goes[0,*], goes[1,*], color=3
	outplot, goes[0,*], goes[2,*], color=5

	legend, ['GOES15 0.1-0.8nm','GOES15 0.05-0.4nm'], $
			linestyle=[0,0], $
			color=[3,5], $
			box=0, $
			pos=[0.1, 0.97],$
			/normal, $
			charsize=1.5
	
END

pro plot_nrh, tstart, tend

	restore,'~/Data/2014_apr_18/radio/nrh/src2_xypeak_432mhz.sav', /verb
 	time = anytim(nrh_times, /utim)
 	utplot, time, manual_peak, $
 		xr = [tstart, tend], $
 		color=1, $
 		/ylog, $
 		ytitle = 'Brightness Temperature', $
 		yr = [1e6, 2e9]
 		
 	restore,'~/Data/2014_apr_18/radio/nrh/src3_xypeak_432mhz.sav', /verb	
 	time = anytim(nrh_times, /utim)
 	outplot, time, manual_peak, $
 		psym = 4, $
 		color = 8
 		
 	restore,'~/Data/2014_apr_18/radio/nrh/src1_xypeak_432mhz.sav', /verb	
 	time = anytim(nrh_times, /utim)
 	outplot, time, manual_peak, $
 		psym = 3, $
 		color = 9	
 		
END

	
pro plot_lightcurves

	!p.charsize=3
	!p.thick=1
	window, 0, xs=1000, ys=1300
	
	!p.multi=[0, 1, 4]
	tstart = anytim(file2time('20140418_122000'), /utim)
	tend = anytim(file2time('20140418_132000'), /utim)
	set_line_color
	
	;-----------------------;
	;	    Plot GOES
	goes = get_goes('~/Data/2014_apr_18/goes/20140418_Gp_xr_1m.txt')
	plot_goes, goes, tstart, tend
	
	;-----------------------;
	;	    Plot DAM
	restore, '~/Data/2014_apr_18/radio/dam/DAM_lightcurves.sav', /verb
	utplot, tim, smooth(dam_lc0, 10), $
			color=4, $
			/xs, $
			/ys, $
			ytitle='Intensity (arbitrary)', $
			xr=[tstart, tend]
			
	outplot, tim, smooth(dam_lc1, 10), $
			color=7	
			
	;-----------------------;
	;	  Plot Orfees
	restore,'~/Data/2014_apr_18/radio/orfees/ORF_lightcurves.sav', /verb
	utplot, time_b3, 10.0*alog10(smooth(orf_lc0, 10)), $
			colour=6, $
			/xs, $
			yr = [20, 40], $
			ytitle = 'Intensity (Arbitrary)', $
			xr=[tstart, tend]
			
	outplot, time_b3, 10.0*alog10( smooth(orf_lc2, 10) ), color=2
	outplot, time_b3, 10.0*alog10( smooth(orf_lc3, 10) ), color=7
	outplot, time_b3, 10.0*alog10( smooth(orf_lc4, 10) ), color=8
	outplot, time_b3, 10.0*alog10( smooth(orf_lc5, 10) ), color=9
	outplot, time_b3, 10.0*alog10( smooth(orf_lc6, 10) ), color=1
	
	;-----------------------;
	;	   Plot NRH
	plot_nrh, tstart, tend
 		
;****************	
 	;-------------------------------------------------;
 	;		Compare Orfees and NRH
 	;	
 	window, 1, xs=1700, ys=500
 	!p.multi = [0, 1, 1]
 	!p.charsize = 1.5
 	tstart = anytim(file2time('20140418_124000'), /utim)
	tend = anytim(file2time('20140418_132000'), /utim)
 	
 	orf = alog10( orf_lc5 )/max(alog10( orf_lc5 ) )
 	utplot, time_b3, orf, $
 		color=3, $
 		yr = [0.6, 1], $
 		ytitle = 'Normalised Intensity', $
 		/xs, $
 		xr = [tstart, tend]
 		
 	restore,'~/Data/2014_apr_18/radio/nrh/src2_xypeak_432mhz.sav', /verb
 	time = anytim(nrh_times, /utim)
 	outplot, time, alog10(manual_peak)/max(alog10(manual_peak)), $
 			color=4
 		
 	restore,'~/Data/2014_apr_18/radio/nrh/src3_xypeak_432mhz.sav', /verb	
 	time = anytim(nrh_times, /utim)
 	outplot, time, alog10(manual_peak)/max(alog10(manual_peak)), $
 		color = 1
 		
 	restore,'~/Data/2014_apr_18/radio/nrh/src1_xypeak_432mhz.sav', /verb	
 	time = anytim(nrh_times, /utim)
 	outplot, time, alog10(manual_peak)/max(alog10(manual_peak)), $
 		psym = 3, $
 		color = 7	 	
 		
 	legend, ['NRH 432 MHz (Looptop source)', 'NRH 432 MHz (Loop source)', 'NRH 432 MHz (AR center)', 'Orfees 432 MHz (Precursor)'], $
			linestyle=[0, 0, 0, 0], $
			color=[4, 1, 7, 3], $
			box=0, $
			/right, $
			/normal, $
			charsize=1.5	
 	stop	

END






