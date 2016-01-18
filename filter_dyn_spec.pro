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

pro filter_dyn_spec

	;------------------------------------;
	;			Window params
	loadct, 0
	reverse_ct
	window, 10, xs=1200, ys=600, retain=2
	!p.charsize=1.5
	!p.thick=1
	!x.thick=1
	!y.thick=1

	orfees_folder = '~/Data/2014_apr_18/radio/orfees/'
	freq0 = 140
	freq1 = 1000
	time0 = '20140418_124800'
	time1 = '20140418_125800'

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

	;flow = 0.3
    ;fhigh = 0.8
    ;nterms = 50
    smoothing = 10

    ;for i=0, n_elements(orf_time)-1 do begin
    ;	signal = transpose(orf_spec[i, *])
    ;	hfreq = signal - smooth(signal, smoothing)
    ;	signal = signal + 2.5*hfreq

    ;   Get coefficients:
	;	Coeff = DIGITAL_FILTER(flow, fhigh, 50.0, nterms)
	; 	Apply the filter:
	;	Result = CONVOL(signal, Coeff)

    ;   Result = LANCZOS_BANDPASS(signal, fc1, fc2, n, /Detrend)

    ;	orf_spec[i, *] = signal
    ;	progress_percent, i, 0, n_elements(orf_time)-1 
   ; endfor

    for i=0, n_elements(orf_freqs)-1 do begin
    	signal = transpose(orf_spec[*, i])
    	hfreq = signal - smooth(signal, smoothing)
    	signal = signal + 2.5*hfreq

    	orf_spec[*, i] = signal
    	progress_percent, i, 0, n_elements(orf_freqs)-1 
    endfor
    	
    ;hfreq_img = orf_spec - smooth(orf_spec, 20)
    ;orf_spec = orf_spec + 1.5*hfreq_img

    loadct, 74, /silent
	reverse_ct
	scl_lwr = -0.4				;Lower intensity scale for the plots.
	
	plot_spec, (orf_spec), orf_time, reverse(orf_freqs), [freq0, freq1], [time0, time1], scl0=-1.1, scl1=4.2



END