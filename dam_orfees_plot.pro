pro plot_spec, data, time, freqs, frange, bg, scl0=scl0, scl1=scl1
	
	bg = 10.0*alog10(bg)	
	data = 10.0*alog10(data)

	data = transpose(data)
	
	;bg_spec = data
	;FOR i = 0, n_elements(data[0,*])-1 DO bg_spec[*, i] = bg[i]
	;data = data-bg_spec

	data = constbacksub(data, /auto)
	data = data/max(data)
	data = reverse(data, 2)
	wset,0
	spectro_plot, (data > (scl0) < scl1), $
  				time, $
  				reverse(freqs), $
  				/xs, $
  				/ys, $
  				/ylog, $
  				ytitle='Frequency (MHz)', $
  				title = 'Orfees and DAM', $
  				yr=[ frange[0], frange[1] ], $
  				xrange = '2014-Apr-18 '+['12:30:00', '13:20:00'], $
  				/noerase, $
  				position = [0.09, 0.1, 0.95, 0.95]
		
	;set_line_color	
  	;hline, 432.0, /data, color=3
  	
END


pro dam_orfees_plot

	;------------------------------------;
	;			    Window params

	loadct, 0
	reverse_ct
	window, 0, xs=1200, ys=800, retain=2
	!p.charsize=1.5
	!p.thick=1
	!x.thick=1
	!y.thick=1
	freq0 = 8
	freq1 = 1000
	time0 = '20140418_123000'
	time1 = '20140418_133000'
	scl_lwr = -0.1				;Lower intensity scale for the plots.

	;***********************************;
	;			 Read DAM		
	;***********************************;
	cd,'~/Data/2014_apr_18/radio/dam/'
	restore, 'NDA_20140418_1221_left.sav', /verb
	daml = spectro_l
	timl = tim_l
	
	restore, 'NDA_20140418_1251_left.sav', /verb
	daml = [daml, spectro_l]
	timl = [timl, tim_l]
	
	restore, 'NDA_20140418_1221_right.sav', /verb
	damr = spectro_r
	restore, 'NDA_20140418_1251_right.sav', /verb
	damr = [damr, spectro_r]
	
	dam_spec = damr + daml
	dam_tim = timl
	
	dam_tim0 = anytim(file2time(time0), /time_only, /trun, /yoh)
	dam_tim1 = anytim(file2time(time1), /time_only, /trun, /yoh)
	
	
	;***********************************;
	;			Read Orfees		
	;***********************************;	
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
	
	;--------------------------------------------------;
	;				 Choose time range
	t0 = anytim(file2time(time0), /utim)
	t1 = anytim(file2time(time1), /utim)
	inc0 = (t0 - tstart)*10.0 ;Sampling time is 0.1 seconds
	inc1 = (t1 - tstart)*10.0 ;Sampling time is 0.1 seconds
	range = [inc0, inc1]
	data = mrdfits('orf20140418_101743.fts', 2, hdr2, range = range)
	
	
	;--------------------------------------------------;
	;		   Choose time range for background
	tbg0 = anytim(file2time('20140418_123000'), /utim)
	tbg1 = anytim(file2time('20140418_123100'), /utim)
	incbg0 = (tbg0 - tstart)*10.0 ;Sampling time is 0.1 seconds
	incbg1 = (tbg1 - tstart)*10.0 ;Sampling time is 0.1 seconds
	bg = mrdfits('orf20140418_101743.fts', 2, hdr2, range = [incbg0, incbg1])  
	
	tstart = anytim(file2time('20140418_000000'), /utim)
	time_b1 = tstart + data.TIME_B1/1000.0
	time_b2 = tstart + data.TIME_B2/1000.0 
	time_b3 = tstart + data.TIME_B3/1000.0 
	time_b4 = tstart + data.TIME_B4/1000.0 
	time_b5 = tstart + data.TIME_B5/1000.0 

	;***********************************;
	;			Read Orfees		
	;***********************************;	
	loadct, 74
	reverse_ct
	plot_spec, data.STOKESI_B1, time_b1, fbands.FREQ_B1, [freq0, freq1], average(bg.stokesi_b1, 1), scl0=scl_lwr, scl1=1.5
	plot_spec, data.STOKESI_B2, time_b2, fbands.FREQ_B2, [freq0, freq1], average(bg.stokesi_b2, 1), scl0=scl_lwr, scl1=1.5
	plot_spec, data.STOKESI_B3, time_b3, fbands.FREQ_B3, [freq0, freq1], average(bg.stokesi_b3, 1), scl0=scl_lwr, scl1=1.5
	plot_spec, data.STOKESI_B4, time_b4, fbands.FREQ_B4, [freq0, freq1], average(bg.stokesi_b4, 1), scl0=scl_lwr, scl1=2.0
	plot_spec, data.STOKESI_B5, time_b5, fbands.FREQ_B5, [freq0, freq1], average(bg.stokesi_b5, 1), scl0=-0.05, scl1=0.5
	
	dam_spec = reverse(transpose(dam_spec))
	plot_spec, dam_spec, dam_tim, reverse(freq), [freq0, freq1], average(dam_spec, 2), scl0=(-0.2), scl1=0.7
	
	x2png, '~/Data/cesra_school/dam_orfees_burst_20140418.png'
	
stop
END
