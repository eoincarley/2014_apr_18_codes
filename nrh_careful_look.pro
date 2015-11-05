pro nrh_careful_look

	;Code to choose where the source is then calulcate flux for that source only.

	cd, '~/Data/2014_apr_18/radio/nrh'
	filenames = findfile('*.fts')

	window, 0, xs=700, ys=700, retain=2

	!p.charsize=1.5


	nrh_index = [2,1,0]
	for k=0, n_elements(nrh_index)-1 do begin
		tstart = anytim(file2time('20140418_125600'), /utim)
		tstop = anytim(file2time('20140418_130000'), /utim) 
		nseconds = tstop - tstart
		i=0
		while tstart lt tstop do begin

			t0str = anytim(tstart, /yoh, /trun, /time_only)

			read_nrh, filenames[nrh_index[k]], $
					  nrh_hdr, $
					  nrh_data, $
					  hbeg=t0str;, $ 
					  ;hend=t1str
					
			index2map, nrh_hdr, nrh_data, $
					   nrh_map  
					
			nrh_str_hdr = nrh_hdr
			nrh_times = nrh_hdr.date_obs
					
			;------------------------------------;
			;			Plot Total I
			wset, 0
			freq = nrh_hdr.FREQ
			loadct, 3, /silent
			FOV = [15, 15]
			CENTER = [700, -100]
			plot_map, nrh_map, $
				fov = FOV, $
				center = CENTER, $
				dmin = 1e3, $
				dmax = 3e8, $
				title='NRH '+string(nrh_hdr.freq, format='(I03)')+' MHz '+ $
				string( anytim( nrh_times, /yoh, /trun) )+' UT'
				  
						
			set_line_color
			plot_helio, nrh_times, $
						/over, $
						gstyle=1, $
						gthick=1.0, $
						gcolor=1, $
						grid_spacing=15.0

			max_val = max( (nrh_data), /nan) 									   
			nlevels=5.0   
			top_percent = 0.40
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
				thick=1, $
				color=5		

			tstart = tstart + 1.0
			i=i+1	
			loadct, 3, /silent
			wait, 0.1
		endwhile
	endfor		
END

