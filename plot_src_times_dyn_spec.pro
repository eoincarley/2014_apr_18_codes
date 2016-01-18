pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.0
   !p.thick=4
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=8, $
          ysize=6, $
          bits_per_pixel=16, $
          /encapsulate, $
          yoffset=5

end

pro plot_spec, data, time, freqs, frange, trange, scl0=scl0, scl1=scl1
	

	print, 'Processing: '+string(freqs[0], format=string('(I4)')) + $
			' to ' + $
			string(freqs[n_elements(freqs)-1], format=string('(I4)'))+ ' MHz'

	trange = anytim(file2time(trange), /utim)


	spectro_plot, sigrange(data) > (scl0) < (scl1), $
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

pro plot_src_times_dyn_spec

	;------------------------------------;
	;			Window params
	;setup_ps, '~/orfees_nrh_intensity.eps'
	loadct, 0
	reverse_ct
	window, 10, xs=1200, ys=600, retain=2
	!p.charsize=1.5
	!p.thick=1
	!x.thick=1
	!y.thick=1
	nrh_folder = '~/Data/2014_apr_18/radio/nrh/'
	orfees_folder = '~/Data/2014_apr_18/radio/orfees/'
	freq0 = 140
	freq1 = 1000
	time0 = '20140418_124800'
	time1 = '20140418_125600'
	date_string = time2file(file2time(time0), /date)

	;***********************************;
	;	   Read and plot Orfees		
	;***********************************;	

	cd, orfees_folder
	restore, 'orf_'+date_string+'_bsubbed_minimum.sav', /verb
	orf_spec = orfees_struct.spec
	orf_time = orfees_struct.time
	orf_freqs = orfees_struct.freq

	index0 = closest(orf_time, anytim(file2time(time0), /utim))
	index1 = closest(orf_time, anytim(file2time(time1), /utim))
	orf_spec = orf_spec[index0:index1, *]
	orf_time = orf_time[index0:index1]


	;for i=0, n_elements(orf_freqs)-1 do begin
    ;	signal = transpose(orf_spec[*, i])
    ;	hfreq = signal - smooth(signal, 10)
    ;	signal = signal + 2.5*hfreq

    ;	orf_spec[*, i] = signal
    ;	progress_percent, i, 0, n_elements(orf_freqs)-1 
    ;endfor

    loadct, 74, /silent
	reverse_ct
	scl_lwr = -0.4				;Lower intensity scale for the plots.
	;hfreq_img = orf_spec - smooth(orf_spec, 20)
    ;orf_spec = orf_spec - 1.5*hfreq_img
	plot_spec, (orf_spec), orf_time, reverse(orf_freqs), [freq0, freq1], [time0, time1], scl0=-1.1, scl1=3.2


	;*****************************************************;
	;	   Overplot NRH source times and intensity	
	;*****************************************************;	
	nrh_flux_files = findfile(nrh_folder+'*src1.sav')

	PLOTSYM, 0
	loadct, 27
	for i=0, n_elements(nrh_flux_files)-1 do begin

		; AR source		
		print, 'Reading '+nrh_flux_files[i] 
		restore, nrh_flux_files[i], /verb
		time2 = anytim(SFU_TIME_STRUCT.time, /utim)
		flux2 = SFU_TIME_STRUCT.flux > 1.0
		size_range = findgen(n_elements(flux2))*(255)/(n_elements(flux2)-1)
		flux_range = findgen(n_elements(flux2))*(max(flux2))/(n_elements(flux2)-1)
		colors = interpol(size_range, flux_range, flux2)

		nrh_freq = fltarr(n_elements(time2))	
		nrh_freq[*] = SFU_TIME_STRUCT.freq
		for j=1, n_elements(time2)-2 do $
			plots, [time2[j-1], time2[j+1]], [nrh_freq[j], nrh_freq[j+1]], $
			/data, $
			color = colors[j], $
			thick=7	;symsize = symsizes[j], color=5

	endfor			

stop
	set_line_color
	nrh_flux_files = findfile(nrh_folder+'*src2.sav')

	for i=0, n_elements(nrh_flux_files)-1 do begin
		; Small moving source		
		print, 'Reading '+nrh_flux_files[i] 
		restore, nrh_flux_files[i], /verb
		time2 = anytim(SFU_TIME_STRUCT.time, /utim)
		flux2 = SFU_TIME_STRUCT.flux ;	> 1.0
		size_range = findgen(n_elements(flux2))*(3)/(n_elements(flux2)-1)
		flux_range = findgen(n_elements(flux2))*(max(flux2))/(n_elements(flux2)-1)
		symsizes = interpol(size_range, flux_range, flux2)

		nrh_freq = fltarr(n_elements(time2))	
		nrh_freq[*] = SFU_TIME_STRUCT.freq
		for j=0, n_elements(time2)-1, 10 do $
			plots, time2[j], nrh_freq[j], /data, symsize = symsizes[j], color=5, psym=8

	endfor			

	;device, /close
	set_plot, 'x'

END