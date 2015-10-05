pro plot_nrh_aia_nda_orfees

	loadct,0
	!p.color=0
	!p.background=255
	window, xs=1500, ys=1500, retain = 2
	!p.charsize=2.0

	dam_orfees_oplot_v0, time_points = time_points, freq_points=freq_points
	

	;nrh_aia_imgs_all_freqs_20140418_v2, time_points, freq_points

	; Put in a version three here that produces a separate plot plotting
	; all nrh+aia frequencies for the chosen times
	;
	nrh_aia_imgs_all_freqs_20140418_v3, time_points, freq_points
	
	;times = anytim(['2014-04-18T12:48:00.000', $
	;			 '2014-04-18T12:49:00.000', $
	;			 '2014-04-18T12:50:00.000', $
	;			 '2014-04-18T12:51:00.000', $
	;			 '2014-04-18T12:56:00.000', $
	;			 '2014-04-18T12:58:00.000', $
	;			 '2014-04-18T12:59:30.000' ], /utim)


END

;-----------------------------------------------------------------;
;
;							Version 2.0
;
;-----------------------------------------------------------------;

pro nrh_aia_imgs_all_freqs_20140418_v2, times, freqs

	;This version will plot the chosen points underneath the dynmaic spectrum

	cd,'~/Data/2014_Apr_18/sdo/171A/'
	
	; First filter for correct exposure times.
	aia_files = findfile('aia*.fits')
	mreadfits_header, aia_files, ind, only_tags='exptime'
	aia_files = aia_files[where(ind.exptime gt 1.)]
	mreadfits_header, aia_files, ind
	aia_times = anytim(ind.date_obs, /utim)
	
	tstart = anytim(file2time('20140418_124800'), /utim)
	;times = dindgen(7)*60.0*1.3 + tstart

	;times = [tstart, $
	;		 tstart + 60*1.0, $
	;		 tstart + 60*1.0*2.0, $
	;		 tstart + 60*1.0*3.0, $
	;		 tstart + 60*1.0*8.0, $
	;		 tstart + 60*1.0*10.0, $
	;		 tstart + 60*1.0*11.5 ]


	aia_file_indices = intarr(n_elements(times))
	for i=0, n_elements(times)-1 do aia_file_indices[i] = closest(aia_times, times[i])


	ybottom = 0.05
	ytop = 0.25
	aia171_img_pos = [ [[0.05, ybottom, 0.2, ytop ]], $
				       [[0.2, ybottom, 0.35, ytop ]], $
				       [[0.35, ybottom, 0.5, ytop ]], $
				       [[0.5, ybottom, 0.65, ytop ]], $
				   	   [[0.65, ybottom, 0.8, ytop ]], $
				       [[0.8, ybottom, 0.95, ytop ]] ]

	nrh_freqs = [150.0, 173.0, 228.0, 270.0, 298.0, 327.0, 408.0, 432.0, 445.0]
	nrh_indices = intarr(n_elements(freqs))
	for i=0, n_elements(freqs)-1 do nrh_indices[i] = closest(nrh_freqs, freqs[i])		       

  
	FOR i = 0, n_elements(aia_file_indices)-1 DO BEGIN
		
		cd, '~/Data/2014_Apr_18/sdo/171A/'
		;-------------------------------------------------;
		;				 	Plot AIA
		;
		aia_index = aia_file_indices[i]
		read_sdo, aia_files[aia_index-1], $
			he_aia_pre, $
			data_aia_pre
		read_sdo, aia_files[aia_index], $
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
		pos = aia171_img_pos[*, *, i]
		FOV = [15.0, 15.0]
		CENTER = [600.0, -300.0]
		loadct, 0, /silent
		plot_map, diff_map(map_aia, map_aia_pre), $
			dmin = -25.0, $
			dmax = 25.0, $
			fov = FOV, $
			center = CENTER, $
			position = pos, $
			/noerase, $
			/normal, $
			/notitle, $
			charsize=0.5, $
			/square


		plot_helio, he_aia.date_obs, $
			/over, $
			gstyle=0, $
			gthick=1.0, $	
			gcolor=255, $
			grid_spacing=15.0

		;-------------------------------------------------;
		;					PLOT NRH
		;
		nrh_index = nrh_indices[i]

		tstart = anytim(he_aia.date_obs, /utim) 
		t0 = anytim(tstart, /yoh, /trun, /time_only)

		  
		cd,'~/Data/2014_Apr_18/radio/nrh/'
		nrh_filenames = findfile('*.fts')
		read_nrh, nrh_filenames[nrh_index], $	; 445 MHz
				nrh_hdr, $
				nrh_data, $
				hbeg=t0
							
		index2map, nrh_hdr, nrh_data, $
				 nrh_map  

		nrh_data = alog10(nrh_data)		
		nrh_map.data = nrh_data 

		;			Define contour levels
		max_val = max( (nrh_data) ,/nan) 									   
		nlevels=5.0   
		top_percent = 0.95
		levels = (dindgen(nlevels)*(max_val - max_val*top_percent)/(nlevels-1.0)) $
				+ max_val*top_percent  

		set_line_color
		plot_map, nrh_map, $
			/overlay, $
			/cont, $
			levels=levels, $
			/noxticks, $
			/noyticks, $
			/noaxes, $
			thick=2, $
			color=[i+2];, $

		xyouts, pos[0]+0.01, pos[1]+0.01, 'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz', /normal, charsize=1.0, color=i+2
		xyouts, pos[0]+0.01, pos[3]+0.01, t0+' UT', /normal, charsize=1.0


			print, i
			print, he_aia.date_obs
			print, 'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz'
			print,'----'
			
			if i eq 1 then freqs = nrh_hdr.freq else freqs = [freqs, nrh_hdr.freq] 

	ENDFOR		


END

;-----------------------------------------------------------------;
;
;							Version 3.0
;
;-----------------------------------------------------------------;

pro nrh_aia_imgs_all_freqs_20140418_v3, times, freqs

	;This version will plot the chosen points for all chosen frequencies in a mosaic.

	cd,'~/Data/2014_Apr_18/sdo/171A/'
	
	; First filter for correct exposure times.
	aia_files = findfile('aia*.fits')
	mreadfits_header, aia_files, ind, only_tags='exptime'
	aia_files = aia_files[where(ind.exptime gt 1.)]
	mreadfits_header, aia_files, ind
	aia_times = anytim(ind.date_obs, /utim)
	
	tstart = anytim(file2time('20140418_124800'), /utim)
	;times = dindgen(7)*60.0*1.3 + tstart

	;times = [tstart, $
	;		 tstart + 60*1.0, $
	;		 tstart + 60*1.0*2.0, $
	;		 tstart + 60*1.0*3.0, $
	;		 tstart + 60*1.0*8.0, $
	;		 tstart + 60*1.0*10.0, $
	;		 tstart + 60*1.0*11.5 ]


	aia_file_indices = intarr(n_elements(times))
	for i=0, n_elements(times)-1 do aia_file_indices[i] = closest(aia_times, times[i])


	ybottom = 0.05
	ytop = 0.20
	aia171_img_pos = [ [[0.05, ybottom, 0.2, ytop ]], $
				       [[0.2, ybottom, 0.35, ytop ]], $
				       [[0.35, ybottom, 0.5, ytop ]], $
				       [[0.5, ybottom, 0.65, ytop ]], $
				   	   [[0.65, ybottom, 0.8, ytop ]], $
				       [[0.8, ybottom, 0.95, ytop ]] ]

	nrh_freqs = [150.0, 173.0, 228.0, 270.0, 298.0, 327.0, 408.0, 432.0, 445.0]	;as they are in folder
	freqs = [445.0, 408.0, 298.0, 228.0];, 228.0, 150.0]	;as you want them plotted, bottom to top.
	nrh_indices = intarr(n_elements(freqs))
	for i=0, n_elements(freqs)-1 do nrh_indices[i] = closest(nrh_freqs, freqs[i])		       



	loadct, 0
    !p.background=255
    !p.color=0
    !p.charsize=2.0
    window, 1, xs=1500, ys=1500
	cd,'~/Data/2014_Apr_18/radio/nrh/'
	nrh_filenames = findfile('*.fts')
	FOR j=0, n_elements(nrh_indices)-1 DO BEGIN

		FOR i = 0, n_elements(aia_file_indices)-1 DO BEGIN
			
			cd, '~/Data/2014_Apr_18/sdo/171A/'
			;-------------------------------------------------;
			;				 	Plot AIA
			;
			aia_index = aia_file_indices[i]
			read_sdo, aia_files[aia_index-1], $
				he_aia_pre, $
				data_aia_pre
			read_sdo, aia_files[aia_index], $
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
			
			pos = aia171_img_pos[*, *, i]
			pos[1] = pos[1] + (ytop - ybottom)*(j)
			pos[3] = pos[3] + (ytop - ybottom)*(j)

			FOV = [10.0, 10.0]
			CENTER = [600.0, -300.0]
			loadct, 0, /silent
			plot_map, diff_map(map_aia, map_aia_pre), $
				dmin = -25.0, $
				dmax = 25.0, $
				fov = FOV, $
				center = CENTER, $
				position = pos, $
				/noerase, $
				/normal, $
				/notitle, $
				charsize=0.5, $
				/square


			plot_helio, he_aia.date_obs, $
				/over, $
				gstyle=0, $
				gthick=1.0, $	
				gcolor=255, $
				grid_spacing=15.0

			;-------------------------------------------------;
			;					PLOT NRH
			;
			nrh_index = nrh_indices[j]

			tstart = anytim(he_aia.date_obs, /utim) 
			t0 = anytim(tstart, /yoh, /trun, /time_only)

			  
			cd,'~/Data/2014_Apr_18/radio/nrh/'
			;nrh_filenames = findfile('*.fts')
			read_nrh, nrh_filenames[nrh_index], $	; 445 MHz
					nrh_hdr, $
					nrh_data, $
					hbeg=t0
								
			index2map, nrh_hdr, nrh_data, $
					 nrh_map  

			nrh_data = alog10(nrh_data)		
			nrh_map.data = nrh_data 

			;			Define contour levels
			max_val = max( (nrh_data) ,/nan) 									   
			nlevels=5.0   
			top_percent = 0.95
			levels = (dindgen(nlevels)*(max_val - max_val*top_percent)/(nlevels-1.0)) $
					+ max_val*top_percent  

			set_line_color
			plot_map, nrh_map, $
				/overlay, $
				/cont, $
				levels=levels, $
				/noxticks, $
				/noyticks, $
				/noaxes, $
				thick=2, $
				color=[nrh_index];, $

			xyouts, pos[0]+0.01, pos[1]+0.01, 'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz', /normal, charsize=1.0, color=nrh_index
			xyouts, pos[0]+0.01, pos[3]+0.01, t0+' UT', /normal, charsize=1.0


			print, i
			print, he_aia.date_obs
			print, 'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz'
			print, '----'
			
			if i eq 1 then freqs = nrh_hdr.freq else freqs = [freqs, nrh_hdr.freq] 

		ENDFOR
		
	ENDFOR			


END

;-----------------------------------------------------------------;
;
;						   Version 4.0
;
;-----------------------------------------------------------------;

pro nrh_aia_imgs_all_freqs_20140418_v4, times, freqs

	;This version will plot the chosen points for all chosen frequencies in a mosaic.

	cd,'~/Data/2014_Apr_18/sdo/171A/'
	
	; First filter for correct exposure times.
	aia_files = findfile('aia*.fits')
	mreadfits_header, aia_files, ind, only_tags='exptime'
	aia_files = aia_files[where(ind.exptime gt 1.)]
	mreadfits_header, aia_files, ind
	aia_times = anytim(ind.date_obs, /utim)
	
	tstart = anytim(file2time('20140418_124800'), /utim)
	;times = dindgen(7)*60.0*1.3 + tstart

	;times = [tstart, $
	;		 tstart + 60*1.0, $
	;		 tstart + 60*1.0*2.0, $
	;		 tstart + 60*1.0*3.0, $
	;		 tstart + 60*1.0*8.0, $
	;		 tstart + 60*1.0*10.0, $
	;		 tstart + 60*1.0*11.5 ]


	aia_file_indices = intarr(n_elements(times))
	for i=0, n_elements(times)-1 do aia_file_indices[i] = closest(aia_times, times[i])


	ybottom = 0.25
	ytop = 0.9
	aia171_img_pos = [ [[0.05, ybottom, 0.2, ytop ]], $
				       [[0.2, ybottom, 0.35, ytop ]], $
				       [[0.35, ybottom, 0.5, ytop ]], $
				       [[0.5, ybottom, 0.65, ytop ]], $
				   	   [[0.65, ybottom, 0.8, ytop ]], $
				       [[0.8, ybottom, 0.95, ytop ]] ]

	nrh_freqs = [150.0, 173.0, 228.0, 270.0, 298.0, 327.0, 408.0, 432.0, 445.0]	;as they are in folder
	freqs = [445.0, 432.0, 408.0, 298.0];, 228.0, 150.0]	;as you want them plotted, bottom to top.
	nrh_indices = intarr(n_elements(freqs))
	for i=0, n_elements(freqs)-1 do nrh_indices[i] = closest(nrh_freqs, freqs[i])		       


	loadct, 0
    !p.background=255
    !p.color=0
    window, 1, xs=2200, ys=500
	cd,'~/Data/2014_Apr_18/radio/nrh/'
	nrh_filenames = findfile('*.fts')

		FOR i = 0, n_elements(aia_file_indices)-1 DO BEGIN
			
			cd, '~/Data/2014_Apr_18/sdo/171A/'
			;-------------------------------------------------;
			;				 	Plot AIA
			;
			aia_index = aia_file_indices[i]
			read_sdo, aia_files[aia_index-1], $
				he_aia_pre, $
				data_aia_pre
			read_sdo, aia_files[aia_index], $
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
			pos = aia171_img_pos[*, *, i]

			FOV = [15.0, 15.0]
			CENTER = [600.0, -300.0]
			loadct, 0, /silent
			plot_map, diff_map(map_aia, map_aia_pre), $
				dmin = -25.0, $
				dmax = 25.0, $
				fov = FOV, $
				center = CENTER, $
				position = pos, $
				/notitle, $
				/noerase, $
				/normal, $
				/square


			plot_helio, he_aia.date_obs, $
				/over, $
				gstyle=0, $
				gthick=1.0, $	
				gcolor=255, $
				grid_spacing=15.0

			;-------------------------------------------------;
			;					PLOT NRH
			;
			  
			cd,'~/Data/2014_Apr_18/radio/nrh/'
			FOR j=0, n_elements(nrh_indices)-1 DO BEGIN
				nrh_index = nrh_indices[j]

				tstart = anytim(he_aia.date_obs, /utim) 
				t0 = anytim(tstart, /yoh, /trun, /time_only)
				;nrh_filenames = findfile('*.fts')
				read_nrh, nrh_filenames[nrh_index], $	; 445 MHz
						nrh_hdr, $
						nrh_data, $
						hbeg=t0
									
				index2map, nrh_hdr, nrh_data, $
						 nrh_map  

				nrh_data = alog10(nrh_data)		
				nrh_map.data = nrh_data 

				;			Define contour levels
				max_val = max( (nrh_data) ,/nan) 									   
				nlevels=5.0   
				top_percent = 0.95
				levels = (dindgen(nlevels)*(max_val - max_val*top_percent)/(nlevels-1.0)) $
						+ max_val*top_percent  

				set_line_color
				plot_map, nrh_map, $
					/overlay, $
					/cont, $
					levels=levels, $
					/noxticks, $
					/noyticks, $
					/noaxes, $
					thick=3, $
					color=0;, $

				plot_map, nrh_map, $
					/overlay, $
					/cont, $
					levels=levels, $
					/noxticks, $
					/noyticks, $
					/noaxes, $
					thick=1, $
					color=[nrh_index];, $	

				xyouts, pos[0]+0.01, pos[1]+0.01, 'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz', /normal, color=nrh_index
				xyouts, pos[0]+0.05, pos[3]+0.01, t0+' UT', /normal


				print, i
				print, he_aia.date_obs
				print, 'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz'
				print, '----'
				
				if i eq 1 then freqs = nrh_hdr.freq else freqs = [freqs, nrh_hdr.freq] 

			ENDFOR
		
	ENDFOR			


END
