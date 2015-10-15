pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.5
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=12, $
          ysize=4, $
          bits_per_pixel=16, $
          /encapsulate, $
          yoffset=5

end

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
  				xrange = '2014-Apr-18 '+['12:30:00', '13:20:00'], $
  				/noerase, $
  				position = [0.09, 0.1, 0.95, 0.95]
		
  	
END


pro dam_orfees_plot, save_orfees = save_orfees, postscript=postscript


	; This v2 now puts the seperate dynamic spectra into one.

	;------------------------------------;
	;			Window params
	if keyword_set(postscript) then begin 
		setup_ps, '~/Data/2014_apr_18/radio/orfees_mosaic_points.eps'
	endif else begin
		loadct, 0
		reverse_ct
		window, 0, xs=1200, ys=1000, retain=2
		!p.charsize=1.5
		!p.thick=1
		!x.thick=1
		!y.thick=1
	endelse	

	freq0 = 8
	freq1 = 1000
	time0 = '20140418_122500'
	time1 = '20140418_132000'

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
		inc0 = (t0 - tstart)*10.0 	;Sampling time is 0.1 seconds
		inc1 = (t1 - tstart)*10.0 	;Sampling time is 0.1 seconds
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
	
	plot_spec, orf_spec, orf_time, orf_freqs, [freq0, freq1], scl0=-0.2, scl1=0.5
	
	;x2png, '~/Data/cesra_school/dam_orfees_burst_20140418.png'

	set_line_color
	restore, '~/Data/2014_apr_18/radio/chosen_tf_for_aia_nrh_mosaic.sav', /verb;'ft_dam_orfees_20140418.sav', /verb
	t = time_points
	plots, t, 228.0, /data, psym=1, symsize=3, color=1, thick=7
	plots, t, 228.0, /data, psym=1, symsize=3, color=5, thick=4

	plots, t, 298.0, /data, psym=1, symsize=3, color=0, thick=7
	plots, t, 298.0, /data, psym=1, symsize=3, color=4, thick=4

	plots, t, 408.0, /data, psym=1, symsize=3, color=1, thick=7
	plots, t, 408.0, /data, psym=1, symsize=3, color=3, thick=4

	plots, t, 445.0, /data, psym=1, symsize=3, color=0, thick=7
	plots, t, 445.0, /data, psym=1, symsize=3, color=2, thick=4

	if keyword_set(postscript) then begin 
		device, /close
		set_plot, 'x'
	endif	
	

END
