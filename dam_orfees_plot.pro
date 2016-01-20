pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.5
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=12, $
          ysize=5, $
          bits_per_pixel=16, $
          /encapsulate, $
          yoffset=5

end

pro dam_orfees_plot, save_orfees = save_orfees, postscript=postscript


	; This v2 now puts the seperate dynamic spectra into one.

	dam_folder = '~/Data/2014_apr_18/radio/dam/'
	orfees_folder = '~/Data/2014_apr_18/radio/orfees/'
	freq0 = 10
	freq1 = 1000
	time0 = '20140418_124200'
	time1 = '20140418_124800'
	date_string = time2file(file2time(time0), /date)

	;------------------------------------;
	;			Window params
	if keyword_set(postscript) then begin 
		setup_ps, '~/orfees_zebra_'+date_string+'.eps'
	endif else begin
		loadct, 0
		reverse_ct
		window, 0, xs=600, ys=600, retain=2
		!p.charsize=1.5
		!p.thick=1
		!x.thick=1
		!y.thick=1
	endelse	

	;***********************************;
	;		Read and plot GOES	
	;***********************************;
	;goes_file = '~/Data/2014_sep_01/goes/20140901_Gp_xr_1m.txt'
	;plot_goes_txt, time0, time1, goes_file

	;***********************************;
	;		Read and process DAM		
	;***********************************;

	cd, dam_folder
	restore, 'NDA_'+date_string+'_1151.sav', /verb
	dam_freqs = nda_struct.freq
	daml = nda_struct.spec_left
	damr = nda_struct.spec_right
	times = nda_struct.times

	restore, 'NDA_'+date_string+'_1251.sav', /verb
	daml = [daml, nda_struct.spec_left]
	damr = [damr, nda_struct.spec_right]
	times = [times, nda_struct.times]
	
	dam_spec = damr + daml
	dam_time = times
	
	dam_tim0 = anytim(file2time(time0), /time_only, /trun, /yoh)
	dam_tim1 = anytim(file2time(time1), /time_only, /trun, /yoh)

		;dam_spec = slide_backsub(dam_spec, dam_time, 10.0*60.0, /average)	
	dam_spec = constbacksub(dam_spec, /auto)


	;goto, skip_orfees
	;***********************************;
	;	   Read and process Orfees		
	;***********************************;	

	cd, orfees_folder
	if keyword_set(save_orfees) then begin
		orfees_file = findfile('*.fts')
		null = mrdfits(orfees_file[0], 0, hdr0)
		fbands = mrdfits(orfees_file[0], 1, hdr1)
		orf_freqs = [ fbands.FREQ_B1, $
					  fbands.FREQ_B2, $
					  fbands.FREQ_B3, $
					  fbands.FREQ_B4, $
					  fbands.FREQ_B5  ]
		nfreqs = n_elements(orf_freqs)		
		
		null = mrdfits(orfees_file[0], 2, hdr_bg, row=0)
		tstart = anytim(file2time(orfees_file[0]), /utim)
		
		;-------------------------------------;
		;	   Choose/build time range
		;-------------------------------------;

		t0 = anytim(file2time(time0), /utim)
		t1 = anytim(file2time(time1), /utim)
		inc0 = (t0 - tstart)*10.0 	;Sampling time is 0.1 seconds
		inc1 = (t1 - tstart)*10.0 	;Sampling time is 0.1 seconds
		range = [inc0, inc1]
		data = mrdfits(orfees_file[0], 2, hdr2, range = range)
		
		tstart = anytim(file2time(date_string+'_000000'), /utim)
		time_b1 = tstart + data.TIME_B1/1000.0
		time_b2 = tstart + data.TIME_B2/1000.0 
		time_b3 = tstart + data.TIME_B3/1000.0 
		time_b4 = tstart + data.TIME_B4/1000.0 
		time_b5 = tstart + data.TIME_B5/1000.0 
	
		;-------------------------------------;
		;		    STOKES I data	
		;-------------------------------------;

		orf_spec = transpose([data.stokesi_b1, data.stokesi_b2, data.stokesi_b3, data.stokesi_b4, data.stokesi_b5])
		orf_spec = reverse(orf_spec, 2)
		orf_time = time_b1

		orfees_struct = {name:'orfees_'+date_string+'_raw', $
						spec:orf_spec, $
						time:orf_time, $
						freq:orf_freqs, $
						hdr:hdr2}

		save, orfees_struct, filename = 'orf_'+date_string+'_raw.sav', $
			description='Orfees raw data.'				

		;-------------------------------------;
		;  STOKES I Background Subtract Data	
		;-------------------------------------;

		orf_spec = slide_backsub(orf_spec, time_b1, 10.0*60.0, /minimum)	
		
		orfees_struct = {name:'orfees_'+date_string+'_bsubbed', $
						spec:orf_spec, $
						time:orf_time, $
						freq:orf_freqs, $
						hdr:hdr2}

		save, orfees_struct, filename = 'orf_'+date_string+'_bsubbed_minimum.sav', $
			description='Data produced using sliding 5 minute background. Data is logged.'


		;-------------------------------------;
		;		    STOKES V data	
		;-------------------------------------;

		orf_spec_pol = transpose([data.stokesv_b1, data.stokesv_b2, data.stokesv_b3, data.stokesv_b4, data.stokesv_b5])
		orf_spec_pol = reverse(orf_spec_pol, 2)	

		orfees_struct = {name:'orfees_'+date_string+'_polarised', $
						spec:orf_spec_pol, $
						time:orf_time, $
						freq:orf_freqs, $
						hdr:hdr2}

		save, orfees_struct, filename = 'orf_'+date_string+'_polarised.sav', $
			description='Polarisation data. No background subtraction.'

	endif else begin
		restore, 'orf_'+date_string+'_bsubbed_minimum.sav', /verb
		orf_spec = orfees_struct.spec
		orf_time = orfees_struct.time
		orf_freqs = orfees_struct.freq

		restore, filename = 'orf_'+date_string+'_polarised.sav'
		orf_spec_pol = orfees_struct.spec

		restore, filename = 'orf_'+date_string+'_raw.sav'
		orf_spec_raw = orfees_struct.spec

	endelse
	
	;skip_orfees: print, 'Skipped Orfees.'
	;***********************************;
	;			   PLOT
	;***********************************;	

	loadct, 74
	reverse_ct
	scl_lwr = -0.4				;Lower intensity scale for the plots.

	plot_spec, dam_spec, dam_time, dam_freqs, [freq0, freq1], [time0, time1], scl0=-30, scl1=150
	
	plot_spec, orf_spec, orf_time, reverse(orf_freqs), [freq0, freq1], [time0, time1], scl0=-0.1, scl1=0.9
	
	;x2png, '~/Desktop/ISSI_meeting/data/dam/dam_'+time0+'.png'

	if keyword_set(postscript) then begin 
		device, /close
		set_plot, 'x'
	endif
	
	;x2png, '~/Data/cesra_school/dam_orfees_burst_20140418.png'

	set_line_color
	restore, '~/Data/2014_apr_18/radio/chosen_tf_for_aia_nrh_mosaic.sav', /verb;'ft_dam_orfees_20140418.sav', /verb
	t = time_points
	plots, t, 228.0, /data, psym=1, symsize=3, color=1, thick=7
	plots, t, 228.0, /data, psym=1, symsize=3, color=5, thick=4

	;plots, t, 298.0, /data, psym=1, symsize=3, color=0, thick=7
	;plots, t, 298.0, /data, psym=1, symsize=3, color=4, thick=4

	;plots, t, 408.0, /data, psym=1, symsize=3, color=1, thick=7
	;plots, t, 408.0, /data, psym=1, symsize=3, color=3, thick=4

	;plots, t, 445.0, /data, psym=1, symsize=3, color=0, thick=7
	;plots, t, 445.0, /data, psym=1, symsize=3, color=2, thick=4



	
	times = anytim(['2014-04-18T12:51:20.000', $
					'2014-04-18T12:51:30.000', $
					'2014-04-18T12:51:40.000', $
					'2014-04-18T12:53:09.000', $
					'2014-04-18T12:54:00.000', $
					'2014-04-18T12:56:10.000'])

	freqs = [445.0, 432.0, 408.0, 327.0, 298.0, 270.0]

	plots, times, freqs, /data, symsize=3, psym=1, thick=4, color=0
	plots, times, freqs, /data, symsize=3, psym=1, thick=1, color=4

	if keyword_set(postscript) then begin 
		device, /close
		set_plot, 'x'
	endif	
	

END
