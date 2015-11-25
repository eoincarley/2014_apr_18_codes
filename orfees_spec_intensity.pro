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
  				;/ylog, $
  				ytitle='Frequency (MHz)', $
  				;title = 'Orfees and DAM', $
  				yr=[ frange[0], frange[1] ], $
  				xrange = [ trange[0], trange[1] ], $
  				/noerase, $
  				position = [0.18, 0.7, 0.94, 0.99], $
  				xticklen = -0.012, $
  				yticklen = -0.015
		
  	
END

pro orfees_spec_intensity

	;-------------------------------------------------;
	;				Define constants
	;		
	!p.charsize=1
	orfees_folder = '~/Data/2014_apr_18/radio/orfees/'
	freq0 = 150
	freq1 = 450
	time0 = '20140418_123420'
	time1 = '20140418_124900'
	time0_typeIII = anytim(file2time(time0), /utim)
	time1_typeIII = anytim(file2time(time1), /utim)
	date_string = time2file(file2time(time0), /date)

	;-------------------------------------------------;
	;		     Restore and plot orfees
	;
	restore, orfees_folder+'orf_'+date_string+'_bsubbed_minimum.sav', /verb
	orf_spec = orfees_struct.spec
	orf_time = orfees_struct.time
	orf_freqs = reverse(orfees_struct.freq)
	plot_orfees = 'plot_spec, orf_spec, orf_time, orf_freqs, [freq0, freq1], [time0, time1], scl0=-0.1, scl1=0.9'

	;-------------------------------------------------;
	;		     	Get NRH flux
	;
	;flux_struct = nrh_flux_compare_orfees(time0, time1)
	restore, '~/Data/2014_apr_18/radio/nrh/flux_density_spectrum.sav'


	;-------------------------------------------------;
	;		     	Plot together
	;
	freqs = [150, 173, 228, 270, 298, 327, 408, 432, 445]
	nseconds = round(time1_typeIII - time0_typeIII)
	img_num=0

	for i=0., nseconds-1 do begin

		loadct, 0, /silent
		window, 0, xs=400, ys=800, retain=2

		time0_typeIII = time0_typeIII + 1.
		;print, anytim(time0_typeIII, /cc)

		orfees_index = closest(orf_time, time0_typeIII)
		intensity_spec = orf_spec[orfees_index, *]

		plot, orf_freqs, smooth(intensity_spec, 5), $
			/xs, $
			/ys, $
			;/xlog, $
			xr=[freq0, freq1], $
			/ylog, $
			yr=[1e-2, 1], $
			ytitle = 'Intensity (arbitrary)', $
			xtitle = 'Frequency (MHz)', $
			title = 'Orfees '+anytim(orf_time[orfees_index], /cc), $
			pos=[0.18, 0.4, 0.95, 0.63], $
			/noerase

		nrh_index = closest((flux_struct.nrh_150)[*, 0], time0_typeIII)

		time_index=nrh_index
		flux =  [ (flux_struct.nrh_150)[time_index, 1], $
				  (flux_struct.nrh_173)[time_index, 1], $
				  (flux_struct.nrh_228)[time_index, 1], $
				  (flux_struct.nrh_270)[time_index, 1], $
				  (flux_struct.nrh_298)[time_index, 1], $
				  (flux_struct.nrh_327)[time_index, 1], $
				  (flux_struct.nrh_408)[time_index, 1], $
				  (flux_struct.nrh_432)[time_index, 1], $
				  (flux_struct.nrh_445)[time_index, 1]  ]

		plot, freqs, flux, $
				/xs, $
				/ys, $
				yr=[0.1, 100.0], $
				xr=[freq0, freq1], $
				/ylog, $
				xtitle='Frequency (MHz)', $
				ytitle='Flux Density (SFU)', $
				title = 'NRH '+anytim((flux_struct.nrh_150)[time_index, 0], /cc), $
				pos=[0.18, 0.1, 0.95, 0.33], $
				/noerase

		
		loadct, 74, /silent
		reverse_ct
		junk = execute(plot_orfees)	
		vline, time0_typeIII

		
		x2png, '~/Data/2014_apr_18/radio/intensity_spec/image_'+string(img_num, format='(I04)' )+'.png'
		img_num = img_num + 1

	endfor				

	cd, '~/Data/2014_apr_18/radio/intensity_spec/'
	spawn, 'ffmpeg -y -r 25 -i image_%04d.png -vb 50M orfees_nrh_spec_intensity.mpg'
	spawn, 'rm image*.png'

	stop

END