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
		/xs, $
		yrange=[1e-9, 1e-3], $
		/ylog, $
		ytitle = 'Watts m!U-2!N', $
		xrange = [tstart, tend], $
		xtitle = ' ', $
		position=[0.1, 0.77, 0.95, 0.99], $
		/normal, $
		XTICKFORMAT="(A1)"
		

	outplot, goes[0,*], goes[1,*], color=3 ;for some reason utplot won't color the line

	axis,yaxis=1,ytickname=[' ','A','B','C','M','X',' ']
	axis,yaxis=0,yrange=[1e-9,1e-3]

  g0 = closest(goes[0,*], tstart)
  g1 = closest(goes[0,*], tend)

	plots, goes[0, g0:g1], 1e-8, linestyle=1
	plots, goes[0, g0:g1], 1e-7, linestyle=1
	plots, goes[0, g0:g1], 1e-6, linestyle=1
	plots, goes[0, g0:g1], 1e-5, linestyle=1
	plots, goes[0, g0:g1], 1e-4, linestyle=1
	
	outplot, goes[0,*], goes[1,*], color=3
	outplot, goes[0,*], goes[2,*], color=5

	legend, ['GOES15 0.1-0.8nm','GOES15 0.05-0.4nm'], $
			linestyle=[0,0], $
			color=[3,5], $
			box=0, $
			pos=[0.12, 0.98],$
			/normal, $
			charsize=1.0
	
END

pro plot_nrh, tstart, tend

	restore,'~/Data/2014_apr_18/radio/nrh/src2_xypeak_432mhz.sav', /verb
 	time = anytim(nrh_times, /utim)
 	utplot, time, manual_peak, $
      xr = [tstart, tend], $
      color=8, $
      /ylog, $
      ytitle = 'Brightness Temperature', $
      yr = [1e6, 2e9], $
		  position=[0.1, 0.08, 0.95, 0.30], $
		  /ys, $
		  /normal, $
		  /noerase
 		
 	restore,'~/Data/2014_apr_18/radio/nrh/src3_xypeak_432mhz.sav', /verb	
 	time = anytim(nrh_times, /utim)
 	outplot, time, manual_peak, $
 		color = 0
 		
 	restore,'~/Data/2014_apr_18/radio/nrh/src1_xypeak_432mhz.sav', /verb	
 	time = anytim(nrh_times, /utim)
 	outplot, time, manual_peak, $
 		psym = 3, $
 		color = 5
 		
 	legend, ['Nancay 432 MHz:', 'Looptop', 'Loop', 'AR Center'], $
			linestyle=[0, 0, 0, 0], $
			color=[1, 8, 0, 5], $
			box=0, $
			pos=[0.12, 0.29],$
			/normal, $
			charsize=1.0	
 		
END


;************************************************;
;               Main Procedure
;	
pro plot_lightcurves, ps=ps

  !p.charsize=1.0
  !p.thick=3

  cd,'~/Data/2014_apr_18/radio/'
  If keyword_set(ps) then begin
    set_plot,'ps'
    device, filename='radio_lcs_2014_apr_18.eps', $
        /encapsulate, $
        /color, $
        /inches, $
        xsize = 9, $
        ysize = 13
  endif else begin
    !p.charsize=1.5
    !p.thick=1
    window, 0, xs=1000, ys=1300
	endelse
	
	!p.multi=[0, 1, 1]
	tstart = anytim(file2time('20140418_122000'), /utim)
	tend = anytim(file2time('20140418_132000'), /utim)
	set_line_color
	
	;-----------------------;
	;	    Plot GOES
	goes = get_goes('~/Data/2014_apr_18/goes/20140418_Gp_xr_1m.txt')
	plot_goes, goes, tstart, tend
	
	;-----------------------;
	;	    Plot DAM
	; Light curves for DAM and Orfees produced using 
	; ~/idl/2014_apr_18_codes/radio_lightcurves.pro
	restore, '~/Data/2014_apr_18/radio/dam/DAM_lightcurves.sav', /verb
	utplot, tim, smooth(dam_lc0, 10), $
			color=4, $
			/xs, $
			/ys, $
			ytitle='Intensity', $
			xr=[tstart, tend], $
		  xtitle = ' ', $
		  yr=[100, 360], $
		  position=[0.1, 0.54, 0.95, 0.76], $
		  /normal, $
		  /noerase, $
		  XTICKFORMAT="(A1)"
	
	outplot, tim, smooth(dam_lc1, 10), $
			color = 9	
			
	legend, ['DAM 30 MHz', 'DAM 60 MHz'], $
			linestyle=[0, 0], $
			color=[4, 9], $
			box=0, $
			pos=[0.74, 0.75],$
			/normal, $
			charsize=1.0		
			
			
	;-----------------------;
	;	  Plot Orfees
	restore,'~/Data/2014_apr_18/radio/orfees/ORF_lightcurves.sav', /verb
	utplot, time_b3, 10.0*alog10(smooth(orf_lc0, 10)), $
			color=6, $
			/xs, $
			yr = [20, 40], $
			ytitle = 'Intensity (Arbitrary)', $
			xr=[tstart, tend], $
		  position=[0.1, 0.31, 0.95, 0.53], $
		  /normal, $
		  /noerase, $
		  XTICKFORMAT="(A1)", $
		  xtit = ' '
		  
			
	  ;outplot, time_b3, 10.0*alog10( smooth(orf_lc2, 10) ), color=2
	outplot, time_b3, 10.0*alog10( smooth(orf_lc3, 10) ), color=7
	  ;outplot, time_b3, 10.0*alog10( smooth(orf_lc4, 10) ), color=8
	outplot, time_b3, 10.0*alog10( smooth(orf_lc5, 10) ), color=5
	  ;outplot, time_b3, 10.0*alog10( smooth(orf_lc6, 10) ), color=1
	  
	legend, ['Orfees 228 MHz', 'Orfees 327 MHz', 'Orfees 432 MHz'], $
			linestyle=[0, 0, 0], $
			color=[6, 7, 5], $
			box=0, $
			pos=[0.70, 0.52],$
			/normal, $
			charsize=1.0
			
	;-----------------------;
	;	   Plot NRH
	plot_nrh, tstart, tend
	
  if keyword_set(ps) then begin
    device, /close
    set_plot, 'x'
  endif
	

;****************	


  cd,'~/Data/2014_apr_18/radio/'
  
  !p.charsize=1.5
  If keyword_set(ps) then begin
    set_plot,'ps'
    device, filename='radio_lcs2_2014_apr_18.eps', $
        /encapsulate, $
        /color, $
        /inches, $
        xsize = 13, $
        ysize = 6
  endif else begin
    !p.charsize=1.5
    window, 1, xs=1700, ys=500
	endelse

 	;-------------------------------------------------;
 	;		          Compare Orfees and NRH
 	;	
 	tstart = anytim(file2time('20140418_124000'), /utim)
	tend = anytim(file2time('20140418_132000'), /utim)
 	

 	orf = alog10( orf_lc5 )/max(alog10( orf_lc5 ) )
 	utplot, time_b3, orf, $
 		color=3, $
 		yr = [0.6, 1], $
 		ytitle = 'Normalised Intensity', $
 		/xs, $
 		xr = [tstart, tend], $
 		xthick=5, $
 		ythick=5, $
 		charthick=5
 		
 		
 	restore,'~/Data/2014_apr_18/radio/nrh/src2_xypeak_432mhz.sav', /verb
 	time = anytim(nrh_times, /utim)
 	outplot, time, alog10(manual_peak)/max(alog10(manual_peak)), $
 			color=5
 		
 	restore,'~/Data/2014_apr_18/radio/nrh/src3_xypeak_432mhz.sav', /verb	
 	time = anytim(nrh_times, /utim)
 	outplot, time, alog10(manual_peak)/max(alog10(manual_peak)), $
 		color = 0
 		
 	restore,'~/Data/2014_apr_18/radio/nrh/src1_xypeak_432mhz.sav', /verb	
 	time = anytim(nrh_times, /utim)
 	outplot, time, alog10(manual_peak)/max(alog10(manual_peak)), $
 		color = 4	 	
 		
 	legend, ['NRH 432 MHz (Looptop source)', 'NRH 432 MHz (Loop source)', 'NRH 432 MHz (AR center)', 'Orfees 432 MHz (Precursor)'], $
			linestyle=[0, 0, 0, 0], $
			color=[5, 0, 4, 3], $
			box=0, $
			/right, $
			/normal, $
			charsize=1.5	
 	if keyword_set(ps) then begin
    device, /close
    set_plot, 'x'
  endif
END






