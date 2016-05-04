pro oplot_nrh_on_three_color_for_movie, tstart

	;				PLOT NRH
	tstart = anytim(tstart, /utim) - 3.0
	  
	folder = '~/Data/2014_Apr_18/radio/nrh/clean_wresid/'
	cd, folder
	nrh_filenames = reverse(findfile('*.fts'))
	t0 = anytim(tstart, /yoh, /trun, /time_only)
							;[10,	9,	 8,	  7,   6,	5,	 4,	  3,	2]
							;[445, 432, 408, 327, 298, 270, 228, 173, 150]
	set_line_color						
	colors = reverse( [2,3,4,5,6,7,8,9,10] )
	inds = [0,1,2,3,4,5,6,7,8]

	for j=0, n_elements(inds)-1 do begin
	
		nrh_file_index = inds[j]

		read_nrh, nrh_filenames[nrh_file_index], $	; 432 MHz
				nrh_hdr, $
				nrh_data, $
				hbeg=t0			
							
		index2map, nrh_hdr, nrh_data, $
				 nrh_map  

		freq_tag = string(nrh_hdr.freq, format='(I3)')		 
		nrh_data = smooth(nrh_data, 5)
		nrh_data = alog10(nrh_data)
		nrh_map.data = nrh_data	
		data_roi = nrh_data[40:111, 0:68] 	; For determinging source max for 2014-04-18 event

		max_val = max( (data_roi), /nan) 							   
		nlevels=5.0   
		top_percent = 0.99	; 0.7 if linear, 0.99 if log
		levels = ( (dindgen(nlevels)*(max_val - max_val*top_percent)/(nlevels-1.0)) $
					+ max_val*top_percent ) > 6.5
		

		if j eq 0 then plot_helio, nrh_hdr.date_obs, $
			/over, $
			gstyle=0, $
			gthick=2.0, $	
			gcolor=255, $
			grid_spacing=15.0			 

		plot_map, nrh_map, $
			/overlay, $
			/cont, $
			/noerase, $
			levels=levels, $
			;/noxticks, $
			;/noyticks, $
			/noaxes, $
			thick=6, $
			color=1

		plot_map, nrh_map, $
			/overlay, $
			/cont, $
			levels=levels, $
			/noxticks, $
			/noyticks, $
			/noaxes, $
			thick=4, $
			color=colors[j]			


		;print, 'Brightness temperature max at '+freq_tag+'  MHz: '+string(levels)
		;print, 'Frequency: '+freq_tag+' MHz '+'. Color: '+string(j+2)
		;print, '--------'
			

	endfor						 

	xyouts, 0.075+0.0012, 0.78-0.025, 'NRH '+anytim(nrh_hdr.date_obs, /cc, /trun)+' UT', $
			/normal, $
			color=0, $
			charsize=1.2
	xyouts, 0.075-0.0012, 0.78-0.025, 'NRH '+anytim(nrh_hdr.date_obs, /cc, /trun)+' UT', $
			/normal, $
			color=0, $
			charsize=1.2
	xyouts, 0.075, 0.78-0.025, 'NRH '+anytim(nrh_hdr.date_obs, /cc, /trun)+' UT', $
			/normal, $
			color=1, $
			charsize=1.2

 END