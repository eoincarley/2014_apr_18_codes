pro nrh_aia_imgs_all_freqs_20140418_v2

	window, xs=2000, ys=8000, retain = 2
	!p.charsize=1.5


	cd,'~/Data/2014_Apr_18/sdo/171A/'
	
	; First filter for correct exposure times.
	aia_files = findfile('aia*.fits')
	mreadfits_header, aia_files, ind, only_tags='exptime'
	aia_files = aia_files[where(ind.exptime gt 1.)]
	mreadfits_header, aia_files, ind
	aia_times = anytim(ind.date_obs, /utim)
	
	tstart = anytim(file2time('20140418_124800'), /utim)
	times = dindgen(7)*60.0 + tstart

	file_indices = intarr(n_elements(times))
	for i=0, n_elements(times)-1 do file_indices[i] = closest(aia_times, times[i])
	aia_files = aia_files[file_indices]


	xbottom = 0.05
	xtop = 0.2
	aia_img_pos = [ [[xbottom, 0.05, xtop, 0.2]], $
				    [[xbottom, 0.25, xtop, 0.4]], $
				    [[xbottom, 0.45, xtop, 0.6]], $
				    [[xbottom, 0.35, xtop, 0.8]], $
				    [[xbottom, 0.45, xtop, 0.5]], $
				    [[xbottom, 0.55, xtop, 0.6]], $
				    [[xbottom, 0.65, xtop, 0.7]] ]

  

	FOR i = 5, n_elements(aia_files)-1 DO BEGIN
		cd,'~/Data/2014_Apr_18/sdo/171A/'
		;-------------------------------------------------;
		;				 	Plot AIA
		;
		read_sdo, aia_files[i-5], $
			he_aia_pre, $
			data_aia_pre
		read_sdo, aia_files[i], $
			he_aia, $
			data_aia

		index2map, he_aia_pre, $
			smooth(data_aia_pre, 7)/he_aia_pre.exptime, $
			map_aia_pre, $
			outsize = 2048
		index2map, he_aia, $
			smooth(data_aia, 7)/he_aia.exptime, $
			map_aia, $
			outsize = 2048		
	  
		;--------------------------------------------------;
		;				  Plot diff image
		;	
		FOV = [25.0, 25.0]
		CENTER = [500.0, -350.0]
		loadct, 1, /silent
		plot_map, diff_map(map_aia, map_aia_pre), $
			dmin = -25.0, $
			dmax = 25.0, $
			fov = FOV, $
			center = CENTER, $
			position = aia_img_pos[*, *, i]


		plot_helio, he_aia.date_obs, $
			/over, $
			gstyle=0, $
			gthick=1.0, $	
			gcolor=255, $
			grid_spacing=15.0


	ENDFOR		


END