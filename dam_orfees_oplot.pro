pro plot_spec, data, time, freqs, frange, scl0=scl0, scl1=scl1
	

	print, 'Processing: '+string(freqs[0], format=string('(I4)')) + $
			' to ' + $
			string(freqs[n_elements(freqs)-1], format=string('(I4)'))+ ' MHz'

	
	spectro_plot, data > (scl0) < (scl1), $
  				time, $
  				reverse(freqs), $
  				/xs, $
  				/ys, $
  				/ylog, $
  				ytitle='Frequency (MHz)', $
  				title = 'Orfees and DAM', $
  				yr=[ frange[0], frange[1] ], $
  				xrange = '2014-Apr-18 '+['12:40:00', '13:02:00'], $
  				/noerase, $
  				position = [0.09, 0.3, 0.95, 0.95]
		
  	
END


pro dam_orfees_oplot, time_points = time_points, freq_points=freq_points, choose_points=choose_points

	;------------------------------------;
	;			Window params
	!p.charsize=1
	freq0 = 130
	freq1 = 1000
	time0 = '20140418_123000'
	time1 = '20140418_133000'

	;***********************************;
	;		Read and process DAM		
	;***********************************;
	cd,'~/Data/2014_apr_18/radio/dam/'
	restore, 'NDA_20140418_1221_left.sav', /verb
	dam_freqs = freq
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
	dam_time = timl
	
	dam_tim0 = anytim(file2time(time0), /time_only, /trun, /yoh)
	dam_tim1 = anytim(file2time(time1), /time_only, /trun, /yoh)

	;dam_spec = slide_backsub(dam_spec, dam_time, 10.0*60.0, /average)	
	dam_spec = constbacksub(dam_spec, /auto)

	;***********************************;
	;	   Read and process Orfees		
	;***********************************;	

	cd,'~/Data/2014_apr_18/radio/orfees/'
	if keyword_set(save_orfees) then begin
		null = mrdfits('orf20140418_101743.fts', 0, hdr0)
		fbands = mrdfits('orf20140418_101743.fts', 1, hdr1)
		orf_freqs = [ fbands.FREQ_B1, $
				  fbands.FREQ_B2, $
				  fbands.FREQ_B3, $
				  fbands.FREQ_B4, $
				  fbands.FREQ_B5  ]
		nfreqs = n_elements(orf_freqs)		
		
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
		
		
		tstart = anytim(file2time('20140418_000000'), /utim)
		time_b1 = tstart + data.TIME_B1/1000.0
		time_b2 = tstart + data.TIME_B2/1000.0 
		time_b3 = tstart + data.TIME_B3/1000.0 
		time_b4 = tstart + data.TIME_B4/1000.0 
		time_b5 = tstart + data.TIME_B5/1000.0 
	
		data = transpose([data.stokesi_b1, data.stokesi_b2, data.stokesi_b3, data.stokesi_b4, data.stokesi_b5])
		data = reverse(data, 2)

		orf_spec = slide_backsub(data, time_b1, 10.0*60.0, /average)	
		orf_time = time_b1
		
		orfees_struct = {name:'orfees_20140418_bsubbed', spec:orf_spec, time:orf_time, freq:orf_freqs, hdr:hdr2}
		save, orfees_struct, filename = 'orf_20140418_bsubbed_average.sav', $
			description='Data produced using sliding 5 minute background. Data is logged.'
	endif else begin
		;--------------------------------------------------;
		restore, 'orf_20140418_bsubbed_average.sav', /verb
		orf_spec = orfees_struct.spec
		orf_time = orfees_struct.time
		orf_freqs = orfees_struct.freq
	endelse
	
	;***********************************;
	;			   PLOT
	;***********************************;	
	loadct, 74
	reverse_ct
	scl_lwr = -0.4				;Lower intensity scale for the plots.

	plot_spec, dam_spec, dam_time, dam_freqs, [freq0, freq1], scl0=-20, scl1=100
	
	plot_spec, orf_spec, orf_time, orf_freqs, [freq0, freq1], scl0=-0.2, scl1=1.5

	hline, 445.0, /data, color=255
  	hline, 432.0, /data, color=255
  	hline, 408.0, /data, color=255	
  	hline, 327.0, /data, color=255	
  	hline, 298.0, /data, color=255		
  	hline, 270.0, /data, color=255
  	hline, 228.0, /data, color=255
  	hline, 173.0, /data, color=255
  	hline, 150.0, /data, color=255	

	if keyword_set(choose_points) then begin
		point, time_points, freq_points, /data
	endif else begin
		set_line_color
		plots, time_points, freq_points, /data, symsize=4, psym=1, thick=4, color=0
		plots, time_points, freq_points, /data, symsize=4, psym=1, thick=4, color=4
	endelse	
	;endif

	plots, time_points, 150.0, psym=1, color=1, /data

	;---------------------------------;
	;		Plot frequency time
	
	;x2png, '~/Desktop/dam_orfees_typeII_points.png'
	
END