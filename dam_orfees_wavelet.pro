pro dam_orfees_wavelet, frequency, plot_ps = plot_ps

	; Perform wavelet analysis of lightcurve extracted from ORFEES
	; Light curve taken at 'frequency' MHz. 

	cd,'~/Data/2014_apr_18/radio/'
	!p.charsize = 0.8
	!p.font = 0
	xleft = 0.05
	xright = 0.95
	if keyword_set(plot_ps) THEN BEGIN
		set_plot, 'ps'
		device, filename = 'dam_orfees_wavelet.eps', $
			/encapsulate, $
			/inches, $
			xsize=8, $
			ysize=10, $
			color=1, $
			bits_per_pixel=32, $
			/helvetica
	ENDIF ELSE BEGIN
		window, 1, xs=2500, ys=1000
	ENDELSE
	
	
	cd, 'orfees'
    null = mrdfits('orf20140418_101743.fts', 0, hdr0)
    fbands = mrdfits('orf20140418_101743.fts', 1, hdr1)
    null = mrdfits('orf20140418_101743.fts', 2, hdr_bg, row=0)
    tstart = anytim(file2time('20140418_101743'), /utim)

	;--------------------------------------------------;
    ;               Choose time range
	time0='20140418_125500'
    time1='20140418_125700'
    t0 = anytim(file2time(time0), /utim)
    t1 = anytim(file2time(time1), /utim)
    inc0 = (t0 - tstart)*10.0 ;Sampling time is 0.1 seconds
    inc1 = (t1 - tstart)*10.0 ;Sampling time is 0.1 seconds
    range = [inc0, inc1]
    data = mrdfits('orf20140418_101743.fts', 2, hdr2, range = range)
	
	data_array = data.STOKESI_B1
	freq_array = fbands.freq_B1
	tstart = anytim(file2time('20140418_000000'), /utim)
    time_array = tstart + data.TIME_B1/1000.0

	index = closest(freq_array, frequency)
	lcurve = data_array[index, *]

    ;--------------------------------------------------;
    ;         Choose time range for background
    tbg0 = anytim(file2time('20140418_123000'), /utim)
    tbg1 = anytim(file2time('20140418_123100'), /utim)
    incbg0 = (tbg0 - tstart)*10.0 ;Sampling time is 0.1 seconds
    incbg1 = (tbg1 - tstart)*10.0 ;Sampling time is 0.1 seconds
    bg = mrdfits('orf20140418_101743.fts', 2, hdr2, range = [incbg0, incbg1])
	bg = bg.STOKESI_B1
	bg = mean(bg[index, *])
	
	;--------------------;
	; Spectrogram plot is last thing in the code because the reverse colour chart was messing 
	; every other plot up. The colour charts in this code have been a serious pain in the arse.
	; Light curve plot	
	loadct, 74	
	lcurve = 10.0*alog10(lcurve) - 10.0*alog10(bg)
	utplot, time_array, lcurve, $
		/xs, $
		/ys, $
		ytitle = 'Intensity (dB)', $
		position = [xleft, 0.39, xright, 0.64], $
		/normal, $
		/noerase, $ 
		title = string(frequency, format='(I3)')+' MHz intensity from Orfees spectrogram'	
	;--------------------------------------------;
	;              Wavelet analysis
	;--------------------------------------------;
	dt = time_array[1]  - time_array[0]
	lcurve = transpose(lcurve)
	wave = wavelet(lcurve, $
			dt, $
			mother='DOG', $
			period = period, $
			coi=coi, $
			SIGNIF=signif, $
			/pad, $
			S0=dt*0.5, $
			SCALE=scale, $
			fft_theor = fft_theor)

	;--------------------------------------------;
	;           Plot wavelet spectrum
	;--------------------------------------------;
	; It took a lot of playing around with colour stretching and scaling the dat to make look right.
	; Without it, the lowest values in wave are plotted as white in the postscript. Couldn't figure out
	; what the issue was.	
	loadct, 5
	stretch, 50.0, 255.0	
	CONTOUR, abs(wave)^2.0 > (-1.0) < 10.0, time_array - time_array[0], period, $
		/xs, $
		/ys, $
		XTITLE='Time in seconds after ' + anytim(time_array[0], /yoh, /time_only, /trun) + ' UT', $ 
		YTITLE='Period (s)', $ 
		YRANGE=[MAX(period), MIN(period)], $   ;*** Large-->Small period
		/YTYPE, $                              ;*** make y-axis logarithmic
		NLEVELS=25, $
		/FILL, $
		position = [xleft, 0.07, xright, 0.32], $
		/normal, $
		/noerase, $
		xticklen = -0.01, $
		yticklen = -0.01, $
		title = 'DOG wavelet spectrogram'		
	
	wave_y =wave
	wave_z =wave

	FOR i = 0, n_elements(wave[*,0])-1 DO BEGIN
        	index = where(period lt coi[i])
        	IF index[0] ne -1 THEN BEGIN
                	wave_y[i, index] = !values.f_nan
                	wave_z[i, index] = 0.0
        	ENDIF
	ENDFOR

	;----------------------------------------------------------;
	;     Plot regions outside the cone of influence in grey
	;----------------------------------------------------------;
	loadct, 0
	CONTOUR, abs(wave_z)^2.0 >(-10) < 7, time_array-time_array[0], period, $
		YRANGE=[MAX(period), MIN(period)], $   ;*** Large-->Small period
		/YTYPE, $                              ;*** make y-axis logarithmic
		NLEVELS=25, $
		/xs, $
		/ys, $
		/FILL, $
		/noerase, $
		position = [xleft, 0.07, xright, 0.32], $	
		xticklen = -0.01, $
		yticklen = -0.01
		
	
	;-------------------------------;
	;   Plot significance levels	;
	;-------------------------------;
	ntime = n_elements(time_array)
	nscale = N_ELEMENTS(period)
	signif = WAVE_SIGNIF(lcurve, dt, scale)
	signif = REBIN(TRANSPOSE(signif), ntime, nscale)
    ;signif = REBIN(TRANSPOSE(signif), ntime, nscale)

    set_line_color
	CONTOUR, abs(wave)^2.0/signif, time_array - time_array0], $
		period, $
      	/OVERPLOT, $
		LEVEL=1.0, $
		C_ANNOT='95%', $
		color=4, $
		position = [xleft, 0.07, xright, 0.32]

	PLOTS, time_array-time_array[0], coi, $
		NOCLIP=0 , $
		thick=3, $
		color=4

	;Orfees plotted here because the reverse ct was messing up the rest of the plots
	
	loadct, 74
	data_array = transpose(reverse(data_array))
	spectro_plot, data_array, time_array, reverse(freq_array), $
			/xs, $
			/ys, $
			ytitle='Frequeny (MHz)', $
			position = [xleft, 0.71, xright, 0.97], $
			/normal, $
			/noerase, $
			title='Orfees spectrogram'	
			
	set_line_color	
	lin = fltarr(n_elements(time_array))
	lin[*] = 209.0
	set_line_color
	plots, time_array, lin, color=3, /data

	IF keyword_set(plot_ps) THEN BEGIN
		device, /close
		set_plot, 'x'
	ENDIF 
END
