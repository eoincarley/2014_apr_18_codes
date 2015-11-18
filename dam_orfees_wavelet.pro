pro dam_orfees_wavelet, frequency, plot_ps = plot_ps

	; Perform wavelet analysis of lightcurve extracted from ORFEES
	; Light curve taken at 'frequency' MHz. 

	cd,'~/Data/2014_apr_18/radio/orfees/'
	!p.charsize = 0.8
	!p.font = 0
	xleft = 0.1
	xright = 0.95
	time0 = anytim('2014-04-18T12:54:30', /utim)
	time1 = anytim('2014-04-18T12:58:00', /utim)


	if keyword_set(plot_ps) THEN BEGIN
		set_plot, 'ps'
		!p.charsize = 1.0
		device, filename = 'dam_orfees_wavelet.eps', $
			/encapsulate, $
			/inches, $
			xsize=7, $
			ysize=10, $
			color=1, $
			bits_per_pixel=32, $
			/helvetica
	ENDIF ELSE BEGIN
		loadct, 0
		window, 1, xs=1500, ys=1000
	ENDELSE
	
	
    ;--------------------------------------------------;
	restore, 'orf_20140418_bsubbed_min.sav', /verb
	data_array = orfees_struct.spec
	time_array = orfees_struct.time
	freq_array = orfees_struct.freq
	
	index_t0 = closest(time_array, time0)
	index_t1 = closest(time_array, time1)

	time_array = time_array[index_t0:index_t1]
	data_array = data_array[index_t0:index_t1, *] > (0) < (1.4)

	;--------------------------------------------------;
	; Spectrogram plot is last thing in the code because the reverse colour chart was messing 
	; every other plot up. The colour charts in this code have been a serious pain in the arse.
	; Light curve plot	

	freq_array = reverse(freq_array)
	index = closest(freq_array, frequency)
	lcurve = data_array[*, index]
	
	loadct, 0
	utplot, time_array, smooth(lcurve, 1), $
		/xs, $
		/ys, $
		linestyle = 0, $
		ytitle = 'Intensity (arbitrary)', $
		position = [xleft, 0.39, xright, 0.64], $
		xr = [time0, time1], $
		/normal, $
		/noerase, $ 
		title = string(frequency, format='(I3)')+' MHz intensity from Orfees spectrogram'	


	;--------------------------------------------;
	;              Wavelet analysis
	;--------------------------------------------;
	dt = time_array[1]  - time_array[0]
	lcurve = transpose(transpose(lcurve))

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
	loadct, 74
	stretch, 50.0, 255.0	
	CONTOUR, abs(wave)^1.0 > 0.15 < 0.5, time_array - time_array[0], period, $
		/xs, $
		/ys, $
		XTITLE='Time in seconds after ' + anytim(time_array[0], /yoh, /time_only, /trun) + ' UT', $ 
		YTITLE='Period (s)', $ 
		YRANGE=[MAX(period), 0.8], $   ;*** Large-->Small period
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
		YRANGE=[MAX(period), 0.8], $   ;*** Large-->Small period
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
	CONTOUR, abs(wave)^2.0/signif, time_array - time_array[0], $
		period, $
      	/OVERPLOT, $
		LEVEL=1.0, $
		C_ANNOT='95%', $
		color=4, $
		position = [xleft, 0.07, xright, 0.32]

	PLOTS, time_array-time_array[0], coi, $
		NOCLIP=0 , $
		thick=3, $
		color=4, $
		linestyle=0

	;Orfees plotted here because the reverse ct was messing up the rest of the plots
	
	loadct, 74
	reverse_ct
	spectro_plot, data_array, time_array, freq_array, $
			/xs, $
			/ys, $
			ytitle='Frequeny (MHz)', $
			yr=[ frequency-40, frequency+40 ], $
			xr = [time0, time1], $
			position = [xleft, 0.71, xright, 0.97], $
			/normal, $
			/noerase, $
			title='Orfees spectrogram'	
			
	set_line_color	
	lin = fltarr(n_elements(time_array))
	lin[*] = frequency
	set_line_color
	plots, time_array, lin, color=4, /data, linestyle=0

	IF keyword_set(plot_ps) THEN BEGIN
		device, /close
		set_plot, 'x'
	ENDIF 
END
