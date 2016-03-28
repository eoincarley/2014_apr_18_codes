pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.0
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=8, $
          ysize=5, $
          bits_per_pixel=16, $
          /encapsulate, $
          yoffset=5

end


;********************
pro plot_fermi, date_start, date_end

	FermiGBM_file= '~/Data/2014_apr_18/fermi/fermi_ctime_n0_20140418_v00.sav'   

	restore, FermiGBM_file

	tims = anytim(ut, /utim)
	counts = (smooth(binned[2,*], 50))
	counts = counts/max(counts)
	;indices = indgen((n_elements(counts)-1)/10.0)*10.0


	utplot, tims, counts, $
			/ylog, $
			yr=[0.1, 1.0], $
			linestyle=2, $
			thick=0.5, $
			xtitle=' ', $
			XTICKFORMAT="(A1)", $
			YTICKFORMAT="(A1)", $
			xticklen=0.001, $
			yticklen=0.001, $
			/noerase, $
			/noyticks, $
			timerange=[date_start, date_end], $
  			position = [0.12, 0.15, 0.92, 0.95], $
			ytitle=' ', $
			/xs, $
			/ys, $
			color=7

	;for k=1,3 do outplot, anytim(ut, /utim), binned[k,*], col=k+2


END

pro plot_spec, data, time, freqs, frange, trange, scl0=scl0, scl1=scl1
	

	print, 'Processing: '+string(freqs[0], format=string('(I4)')) + $
			' to ' + $
			string(freqs[n_elements(freqs)-1], format=string('(I4)'))+ ' MHz'

	trange = anytim(file2time(trange), /utim)

	;kernelSize = [2, 2]
	;kernel = REPLICATE(-1., kernelSize[0], kernelSize[1])
	;kernel[1, 1] = 8
	 
	; Apply the filter to the image.
	;data = CONVOL(data, kernel, $
	;  /CENTER, /EDGE_TRUNCATE)


	spectro_plot, data > (scl0) < (scl1), $
  				time, $
  				freqs, $
  				/xs, $
  				/ys, $
  				/ylog, $
  				;ytitle='Frequency (MHz)', $
  				;title = 'Orfees and DAM', $
  				yr=[ frange[0], frange[1] ], $
  				xrange = [ trange[0], trange[1] ], $
  				/noerase, $
  				position = [0.12, 0.15, 0.92, 0.95], $
  				xticklen = -0.012, $
  				yticklen = 0.00001, $
  				ytickformat='(A1)', $
  				xtitle = ' '

  	axis, yaxis=0, yr=[ frange[1], frange[0] ], yticklen = -0.015, /ylog, /ys, ytitle='Frequency (MHz)'

  	set_line_color
  	axis, yaxis=1, yr=[0.1, 1.0], yticklen = -0.015, /ylog, /ys, ytitle='counts [s!u-1!n cm!u-2!n keV!u-1!n]', color=7
		
  	
END


pro dam_orfees_plot_gen_figure5, save_orfees = save_orfees, postscript=postscript, time_marker=time_marker

	; Code to read and process DAM and Orfees together

	; If /save_orfees chosen, it will process and save Orfees dynamic spectrum. This uses slide_backsub on
	; Orfees, which takes ~5-20 mins depending on paramaters chosen.

	dam_folder = '~/Data/2014_apr_18/radio/dam/'
	orfees_folder = '~/Data/2014_apr_18/radio/orfees/'
	freq0 = 140
	freq1 = 1000
	time0 = '20140418_124800'
	time1 = '20140418_125800'
	date_string = time2file(file2time(time0), /date)

	;------------------------------------;
	;			Window params
	if keyword_set(postscript) then begin 
		setup_ps, '~/orfees_dam_fermi_'+date_string+'.eps'
	endif else begin
		loadct, 0
		reverse_ct
		window, 0, xs=1200, ys=800, retain=2
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
	restore, 'NDA_'+date_string+'_1051.sav', /verb
	dam_freqs = nda_struct.freq
	daml = nda_struct.spec_left
	damr = nda_struct.spec_right
	times = nda_struct.times

	restore, 'NDA_'+date_string+'_1151.sav', /verb
	daml = [daml, nda_struct.spec_left]
	damr = [damr, nda_struct.spec_right]
	times = [times, nda_struct.times]

	restore, 'NDA_'+date_string+'_1251.sav', /verb
	daml = [daml, nda_struct.spec_left]
	damr = [damr, nda_struct.spec_right]
	times = [times, nda_struct.times]
	
	dam_spec = damr + daml
	dam_time = times
	
	dam_tim0 = anytim(file2time(time0), /time_only, /trun, /yoh)
	dam_tim1 = anytim(file2time(time1), /time_only, /trun, /yoh)

	;dam_spec = slide_backsub(dam_spec, dam_time, 15.0*60.0, /minimum)	
	;dam_spec = simple_pass_filter(dam_spec, dam_time, dam_freqs, /low_pass, /time_axis, smoothing=10)
	;dam_spec = smooth(dam_spec, 5)	
	
	dam_spec = alog10(dam_spec)
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
	
	;***********************************;
	;			   PLOT
	;***********************************;	

	loadct, 74, /silent
	reverse_ct

	data = orf_spec
	orf_spec_high = simple_pass_filter(data, orf_time, orf_freqs, /high_pass, /time_axis, smoothing=50)
	orf_spec = orf_spec + 0.5*orf_spec_high

	plot_spec, smooth(dam_spec, 5), dam_time, dam_freqs, [freq0, freq1], [time0, time1], scl0=0.05, scl1=0.4

	loadct, 74, /silent
	reverse_ct
	plot_spec, orf_spec, orf_time, reverse(orf_freqs), [freq0, freq1], [time0, time1], scl0=-0.15, scl1=1.5

	time_line0 = anytim(file2time(time0), /utim)
	time_line1 = anytim(file2time(time1), /utim)
	
	if keyword_set(time_marker) then begin
		!p.thick=4
		set_line_color
		;plots, [time_line0, time_line1], [150, 150], color=2, linestyle=2, /data
		;plots, [time_line0, time_line1], [173, 173], color=3, linestyle=2, /data
		;plots, [time_line0, time_line1], [228, 228], color=4, linestyle=2, /data
		plots, [time_line0, time_line1], [270, 270], color=0, linestyle=2, /data
		plots, [time_line0, time_line1], [298, 298], color=0, linestyle=2, /data
		plots, [time_line0, time_line1], [327, 327], color=0, linestyle=2, /data
		;plots, [time_line0, time_line1], [408, 408], color=0, linestyle=2, /data
		plots, [time_line0, time_line1], [432, 432], color=0, linestyle=2, /data
		;plots, [time_line0, time_line1], [445, 445], color=10, linestyle=2, /data

	endif	


	PLOTSYM, 0, thick=5
	plots, anytim('2014-04-18T12:50:40', /utim), [432], psym=8, color=5, symsize=1, thick=10
	plots, anytim('2014-04-18T12:51:30', /utim), [327], psym=8, color=5, symsize=1, thick=10
	plots, anytim('2014-04-18T12:53:10', /utim), [298], psym=8, color=5, symsize=1, thick=10
	plots, anytim('2014-04-18T12:54:30', /utim), [270], psym=8, color=5, symsize=1, thick=10


	plot_fermi, time_line0, time_line1
			
	if keyword_set(postscript) then begin 
		device, /close
		set_plot, 'x'
	endif	



END
