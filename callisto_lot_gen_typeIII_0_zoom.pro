pro callisto_lot_gen_typeIII_0_zoom, save_orfees = save_orfees, postscript=postscript, time_marker=time_marker

	; First type III
	; Code to read and process DAM and Orfees together

	; If /save_orfees chosen, it will process and save Orfees dynamic spectrum. This uses slide_backsub on
	; Orfees, which takes ~5-20 mins depending on paramaters chosen.

	callisto_folder = '~/Data/2014_apr_18/radio/callisto/'
	freq0 = 10
	freq1 = 1000
	time0 = '20140418_123400'
	time1 = '20140418_123500'
	date_string = time2file(file2time(time0), /date)

	;------------------------------------;

	callisto_file = findfile(callisto_folder + '*.fit')

	radio_spectro_fits_read, callisto_file[0], data, time, freq

	data = constbacksub(data, /auto)

	trange = [anytim(file2time(time0), /utim), anytim(file2time(time1), /utim)]
	
	spectro_plot, sigrange(data), $
  				time, $
  				freq, $
  				/xs, $
  				/ys, $
  				xr = trange, $
  				;/ylog, $
  				ytitle='Frequency (MHz)', $
  				xticklen = -0.016, $
  				yticklen = -0.015, $
  				xtitle = 'Time (UT)'

END	