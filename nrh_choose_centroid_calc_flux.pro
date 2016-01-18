pro nrh_choose_centroid_calc_flux

	;Code to choose where the source is then calulcate flux for that source only.

	cd, '~/Data/2014_apr_18/radio/nrh'
	filenames = findfile('*.fts')

	window, 0, xs=400, ys=400, retain=2
	window, 1, xs=400, ys=400, retain=2
	window, 2, xs=400, ys=400, retain=2
	!p.charsize=1.5
	
	Ray = 32.0								; Solar_R in nrh_hdr_array
	domega = FLOAT(16 * 3E-4 /Ray)^2. 		; Solid angle. Below is a summation of pixels of Tb, which is effectively and integral
											; of Tbx1unit pixels. We need an integral of TbxDomega. So after the summation of Tb
											; we multiply by a factor of solid angle per pixel. 16 here is degrees of solar radius.
											; 32 is number of pixels per radius. 3e-14 comes from (1/60)x(pi/180), conversion of degrees
											; then to radians.
	c = 299792458. 			;speed of light in m/s
	k_B = 0.138				;Boltzmann constant k=1.38e-23, for SFU: K*e+22

	nrh_index = [3];,3,2]			;[4,3,2,1,0]

	for k=0, n_elements(nrh_index)-1 do begin

		tstart = anytim(file2time('20140418_124700'), /utim)
		tstop = anytim(file2time('20140418_125600'), /utim) 
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
			FOV = [16, 16]
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

			max_val = max( (nrh_data) ,/nan) 									   
			nlevels=5.0   
			top_percent = 0.50
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

			loadct, 3, /silent
						
			;-------------------------------------;
			;
			;	  Now plot raw data structure
			;
			wset, 1
			x0 = (CENTER[0]/nrh_hdr.cdelt1 + (nrh_hdr.naxis1/2.0)) - (FOV[0]*60.0/nrh_hdr.cdelt1)/2.0
	        x1 = (CENTER[0]/nrh_hdr.cdelt1 + (nrh_hdr.naxis1/2.0)) + (FOV[0]*60.0/nrh_hdr.cdelt1)/2.0
	        y0 = (CENTER[1]/nrh_hdr.cdelt2 + (nrh_hdr.naxis2/2.0)) - (FOV[1]*60.0/nrh_hdr.cdelt2)/2.0
	        y1 = (CENTER[1]/nrh_hdr.cdelt2 + (nrh_hdr.naxis2/2.0)) + (FOV[1]*60.0/nrh_hdr.cdelt2)/2.0
			nrh_data = nrh_map.data
			data_section = nrh_data[x0:x1, y0:y1]
			plot_image, data_section > 1e5
			max_tb = max(data_section)

			;-------------------------------;
			;								;
			;	   Choose data points	    ;
			;								;
			cursor, x, y, /data
			x0 = x-2 > 0	;3 for AR source
			x1 = x+2
			y0 = y-2 > 0
			y1 = y+2
			source_section = data_section[x0:x1, y0:y1]

			wset, 2
			plot_image, source_section > 1e5

			; Find the max point and mark with a diamond
			index_max = where(source_section eq max(source_section))
			xy_max = array_indices(source_section, index_max)
			plots, xy_max[0, *], xy_max[1, *], /data, psym=4, color=4
			max_tb = source_section[index_max]

			; Find points above 0.4 of max and mark with cross.
			indices = where(source_section ge max(source_section)*0.4)
			if n_elements(indices) eq 1 then indices=0
			xy_indices = array_indices(source_section, indices)

			set_line_color
			plots, xy_indices[0, *], xy_indices[1, *], /data, psym=1, color=5

			total_Tb = TOTAL(source_section[indices])		;summing over specified source area
			freq = nrh_hdr.freq * 1e6						;calculate flux
			lambda = c / freq
			constant = (2.* k_B * domega) / (lambda^2.)
			flux = constant * total_Tb	; in SFU

			print, 'Source Flux at '+anytim(nrh_times, /yoh)+' : '+string(flux)+' (sfu)'
			if i eq 0 then source_Tb = max_tb else source_Tb = [source_Tb, max_tb]
			if i eq 0 then source_flux = flux else source_flux = [source_flux, flux]
			if i eq 0 then times = nrh_times else times = [times, nrh_times]

			tstart = tstart + 1.0
			i=i+1
		endwhile				
STOP
		freq_str = string(nrh_hdr.freq, format='(I03)')
		sfu_time = {name:'sfu_time_'+freq_str, time:times, flux:source_flux, Tb:source_Tb, freq:nrh_hdr.freq}
		;if k eq 0 then sfu_time_struct = sfu_time  else sfu_time_struct = [sfu_time_struct, sfu_time]
		sfu_time_struct = sfu_time
		save, sfu_time_struct, filename='~/Data/2014_apr_18/radio/nrh/nrh_flux_'+freq_str+'_20140418_src2.sav', $
				description='Small moving source to the west of flux rope.'
	
		STOP	
		undefine, source_Tb
		undefine, source_flux
		undefine, times

		print, 'NEXT!!!!!!'		
			
	endfor	

	stop		
			
END