function get_orfees_lc, data, fbands, freq

	index = closest(fbands, freq)
	lc = data[index, *]
	return, lc

END

pro radio_lightcurves

	; Extract light curves from various frequencies in Orfees and DAM data
	; from the 2011-Apr-08 event

	;-----------------------------------------------;
	;				Firstly DAM
	cd,'~/Data/2014_apr_18/radio/dam'
	restore,'NDA_20140418_1221_left.sav', /verb
	spectro_l_master = spectro_l
	tim = tim_l
	restore,'NDA_20140418_1251_left.sav', /verb
	spectro_l_master = [spectro_l_master, spectro_l]
	tim = [tim, tim_l]
	
	cd,'~/Data/2014_apr_18/radio/dam'
	restore,'NDA_20140418_1221_right.sav', /verb
	spectro_r_master = spectro_r
	restore,'NDA_20140418_1251_right.sav', /verb
	spectro_r_master = [spectro_r_master, spectro_r]
	
	spectro = spectro_r_master + spectro_l_master
	spectro_plot, spectro, tim, freq, /xs, /ys
	
	; Extract light curves at ~30, 60 MHz
	i0 = closest(freq, 30.0)
	i1 = closest(freq, 60.0)
	dam_freqs = [ freq[i0], freq[i1] ]
	dam_lc0 = spectro[*,i0]
	dam_lc1 = spectro[*,i1]
	save, dam_lc0, dam_lc1, tim, freqs, $
		filename='DAM_lightcurves.sav'
	utplot, tim, smooth(spectro[*,i0]/max(spectro[*,i0]), 5)
	outplot, tim, smooth(spectro[*, i1]/max(spectro[*,i0]), 5)
	
	;-----------------------------------------------;
	;				Orfees
	cd,'~/Data/2014_apr_18/radio/orfees'
        null = mrdfits('orf20140418_101743.fts', 0, hdr0)
        fbands = mrdfits('orf20140418_101743.fts', 1, hdr1)
        null = mrdfits('orf20140418_101743.fts', 2, hdr_bg, row=0)
        tstart = anytim(file2time('20140418_101743'), /utim)

	;--------------------------------------------------;
    ;               Choose time range
	time0='20140418_122200'
	time1='20140418_131600'
	t0 = anytim(file2time(time0), /utim)
	t1 = anytim(file2time(time1), /utim)
	inc0 = (t0 - tstart)*10.0 ;Sampling time is 0.1 seconds
	inc1 = (t1 - tstart)*10.0 ;Sampling time is 0.1 seconds
	range = [inc0, inc1]
	data = mrdfits('orf20140418_101743.fts', 2, hdr2, range = range)
	tstart = anytim(file2time('20140418_000000'), /utim)
    time_b3 = tstart + data.TIME_B3/1000.0

	orf_freqs = [228., 270., 298., 327., 408., 432., 600.0]
	orf_lc0 = get_orfees_lc(data.STOKESI_B1, fbands.freq_B1, orf_freqs[0])
	orf_lc1 = get_orfees_lc(data.STOKESI_B1, fbands.freq_B1, orf_freqs[1])
	orf_lc2 = get_orfees_lc(data.STOKESI_B1, fbands.freq_B1, orf_freqs[2])
	orf_lc3 = get_orfees_lc(data.STOKESI_B2, fbands.freq_B2, orf_freqs[3])
	orf_lc4 = get_orfees_lc(data.STOKESI_B2, fbands.freq_B2, orf_freqs[4])
	orf_lc5 = get_orfees_lc(data.STOKESI_B2, fbands.freq_B2, orf_freqs[5])
	orf_lc6 = get_orfees_lc(data.STOKESI_B2, fbands.freq_B3, orf_freqs[6])
	
	outplot, time_b3, orf_lc0/max(orf_lc0)
	
	save, orf_lc0, orf_lc1, orf_lc2, orf_lc3, orf_lc4, orf_lc5, orf_lc6, time_b3, orf_freqs,$
		filename ='ORF_lightcurves.sav'
	
	


END