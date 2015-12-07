pro plot_spec, data, time, freqs, frange, trange, scl0=scl0, scl1=scl1
	

	print, 'Processing: '+string(freqs[0], format=string('(I4)')) + $
			' to ' + $
			string(freqs[n_elements(freqs)-1], format=string('(I4)'))+ ' MHz'

	trange = anytim(file2time(trange), /utim)
	spectro_plot, smooth(data,1) > (scl0) < (scl1), $
  				time, $
  				freqs, $
  				/xs, $
  				/ys, $
  				/ylog, $
  				ytitle='Frequency (MHz)', $
  				;title = 'Orfees and DAM', $
  				yr=[ frange[0], frange[1] ], $
  				xrange = [ trange[0], trange[1] ], $
  				/noerase, $
  				position = [0.12, 0.15, 0.95, 0.95], $
  				xticklen = -0.012, $
  				yticklen = -0.015
		
  	
END


pro dam_orfees_oplot, time_points = time_points, freq_points=freq_points, choose_points=choose_points

	; This is for use with both plot_nrh_aia_nda_orfees and plot_nrh_aia_nda_mosaic

	; It is mainly for choosing time and frequency points so that an AIA+NRH image
	; can be produced at that time and frequency

	dam_folder = '~/Data/2014_apr_18/radio/dam/'
	orfees_folder = '~/Data/2014_apr_18/radio/orfees/'
	freq0 = 140
	freq1 = 1000
	time0 = '20140418_124800'
	time1 = '20140418_125600'
	date_string = time2file(file2time(time0), /date)

	;------------------------------------;
	;			Window params
	loadct, 0
	reverse_ct
	window, 10, xs=1200, ys=600, retain=2
	!p.charsize=1.5
	!p.thick=1
	!x.thick=1
	!y.thick=1

	;***********************************;
	;	   Read and plot Orfees		
	;***********************************;	

	cd, orfees_folder
	restore, 'orf_'+date_string+'_bsubbed_minimum.sav', /verb
	orf_spec = orfees_struct.spec
	orf_time = orfees_struct.time
	orf_freqs = orfees_struct.freq

	restore, filename = 'orf_'+date_string+'_polarised.sav'
	orf_spec_pol = orfees_struct.spec


	loadct, 74, /silent
	reverse_ct
	scl_lwr = -0.4				;Lower intensity scale for the plots.
	
	plot_spec, orf_spec, orf_time, reverse(orf_freqs), [freq0, freq1], [time0, time1], scl0=-0.1, scl1=1.2
	
	
	;--------------------------------------------;
	;			Mark Frequency Lines
	;
	vline, time_marker, color=255, thick=4
	vline, time_marker, color=0, thick=4, linestyle=2

	set_line_color
	time_line0 = anytim('2014-04-18T12:25:00', /utim)
	time_line1 = anytim('2014-04-18T13:20:00', /utim)

	plots, [time_line0, time_line1], [150, 150], color=2, linestyle=2, /data
	plots, [time_line0, time_line1], [173, 173], color=3, linestyle=2, /data
	plots, [time_line0, time_line1], [228, 228], color=4, linestyle=2, /data
	plots, [time_line0, time_line1], [270, 270], color=5, linestyle=2, /data
	plots, [time_line0, time_line1], [298, 298], color=6, linestyle=2, /data
	plots, [time_line0, time_line1], [327, 327], color=7, linestyle=2, /data
	plots, [time_line0, time_line1], [408, 408], color=8, linestyle=2, /data
	plots, [time_line0, time_line1], [432, 432], color=9, linestyle=2, /data
	plots, [time_line0, time_line1], [445, 445], color=10, linestyle=2, /data



	if keyword_set(choose_points) then begin
		loadct, 0
		point, time_points, freq_points, /data
	endif else begin
		set_line_color
		plots, time_points, freq_points, /data, symsize=4, psym=1, thick=4, color=0
		plots, time_points, freq_points, /data, symsize=4, psym=1, thick=4, color=4
	endelse	

	plots, time_points, 150.0, psym=1, color=1, /data

	
END