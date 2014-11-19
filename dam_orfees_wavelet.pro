pro dam_orfees_wavelet

	;Perform wavelet analysis of lightcurve extracted from ORFEES
	; Light curve taken at 491 MHz. This is in B3.

	cd,'~/Data/2014_apr_18/radio/orfees/'
        null = mrdfits('orf20140418_101743.fts', 0, hdr0)
        fbands = mrdfits('orf20140418_101743.fts', 1, hdr1)
        freqs = [ fbands.FREQ_B1, $
                        fbands.FREQ_B2, $
                        fbands.FREQ_B3, $
                        fbands.FREQ_B4, $
                        fbands.FREQ_B5  ]
        nfreqs = n_elements(freqs)

        null = mrdfits('orf20140418_101743.fts', 2, hdr_bg, row=0)
        tstart = anytim(file2time('20140418_101743'), /utim)

	index = closest(fbands.freq_b3, 491.0)
	print, index
	
	;--------------------------------------------------;
        ;               Choose time range
	time0='20140418_125240'
        time1='20140418_125330'
        t0 = anytim(file2time(time0), /utim)
        t1 = anytim(file2time(time1), /utim)
        inc0 = (t0 - tstart)*10.0 ;Sampling time is 0.1 seconds
        inc1 = (t1 - tstart)*10.0 ;Sampling time is 0.1 seconds
        range = [inc0, inc1]
        data = mrdfits('orf20140418_101743.fts', 2, hdr2, range = range)
	data_array = data.STOKESI_B3
	lcurve = data_array[index, *]

        ;--------------------------------------------------;
        ;         Choose time range for background
        tbg0 = anytim(file2time('20140418_123000'), /utim)
        tbg1 = anytim(file2time('20140418_123100'), /utim)
        incbg0 = (tbg0 - tstart)*10.0 ;Sampling time is 0.1 seconds
        incbg1 = (tbg1 - tstart)*10.0 ;Sampling time is 0.1 seconds
        bg = mrdfits('orf20140418_101743.fts', 2, hdr2, range = [incbg0, incbg1])
	bg = bg.STOKESI_B3
	bg = mean(bg[index, *])

        tstart = anytim(file2time('20140418_000000'), /utim)
        time_b3 = tstart + data.TIME_B3/1000.0
	loadct, 0
	reverse_ct
	window, 10
	spectro_plot, reverse(transpose(data_array),2), time_b3, reverse(fbands.freq_b3), $
			/xs, $
			/ys
	stop
	
	window, 0, xs=1100, ys=500
	lcurve = 10.0*alog10(lcurve) - 10.0*alog10(bg)
	utplot, time_b3, lcurve, $
		/xs, $
		/ys, $
		ytitle = 'Intensity (dB)' 

	;--------------------------------------------;
	;              Wavelet analysis
	;--------------------------------------------;
	dt = time_b3[1]  - time_b3[0]
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
	;                   Plot wavelet spectrum
	;--------------------------------------------;
	window, 2, xs=1100, ys=400
	loadct,5
	CONTOUR, abs(wave)^2.0 > (-10) < 7, time_b3 - time_b3[0], period, $
		/xs, $
		XTITLE='Time in seconds after HH:MM:SS UT', $
		YTITLE='Period (s)', $ 
		YRANGE=[MAX(period), MIN(period)], $   ;*** Large-->Small period
		/YTYPE, $                             ;*** make y-axis logarithmic
		NLEVELS=25, $
		/FILL
	stop
	wave_y =wave
	wave_z =wave

	FOR i = 0, n_elements(wave[*,0])-1 DO BEGIN
        	index = where(period lt coi[i])
        	IF index[0] ne -1 THEN BEGIN
                	wave_y[i, index] = !values.f_nan
                	wave_z[i, index] = 0.0
        	ENDIF
	ENDFOR

	;-----------------------------------------------------;
	;       Plot regions outside the cone of influence in grey
	;-----------------------------------------------------;
	loadct, 0
	CONTOUR, abs(wave_z)^2.0 >(-10) < 7, time_b3-time_b3[0], period, $
	YRANGE=[MAX(period), MIN(period)], $   ;*** Large-->Small period
	/YTYPE, $                              ;*** make y-axis logarithmic
	NLEVELS=25, $
	/FILL, $
	/noerase
	
	
	;-----------------------------;
	;   Plot significance levels;
	;-----------------------------;
	ntime = n_elements(time_b3)
	nscale = N_ELEMENTS(period)
	signif = WAVE_SIGNIF(lcurve, dt, scale)
	signif = REBIN(TRANSPOSE(signif), ntime, nscale)
        ;signif = REBIN(TRANSPOSE(signif), ntime, nscale)

       	set_line_color
	CONTOUR, abs(wave)^2.0/signif, time_b3 - time_b3[0], $
		period, $
      		/OVERPLOT, $
		LEVEL=1.0, $
		C_ANNOT='95%', $
		color=4

	PLOTS, time_b3-time_b3[0], coi, $
		NOCLIP=0 , $
		thick=3, $
		color=4

END
