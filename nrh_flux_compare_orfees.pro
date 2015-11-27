function nrh_flux_compare_orfees, time0, time1
	
	folder = '~/Data/2014_apr_18/radio/nrh/'
	cd, folder
	nrh_filenames = findfile('*.fts')
	;---------------------------------------------------------------;
	;	  Read Data 5 min chunks to prevent RAM overload
	;
	window, 0, xs=400, ys=400, retain=2
	window, 1, xs=400, ys=400, retain=2
	loadct, 39, /silent
	
	tstart = anytim(file2time(time0), /utim)
	tend = anytim(file2time(time1), /utim)

	nseconds = tend - tstart
	Ray = 32.0								; Solar_R in nrh_hdr_array
	domega = FLOAT(16 * 3E-4 /Ray)^2. 		; Solid angle. Below is a summation of pixels of Tb, which is effectively and integral
											; of Tbx1unit pixels. We need an integral of TbxDomega. So after the summation of Tb
											; we multiply by a factor of solid angle per pixel. 16 here is degrees of solar radius.
											; 32 is number of pixels per radius. 3e-14 comes from (1/60)x(pi/180), conversion ot degrees
											; then to radians.
	c = 299792458. 			; Speed of light in m/s
	k_B = 0.138				; Boltzmann constant k=1.38e-23, for SFU: K*e+22

	FOR i=0, n_elements(nrh_filenames)-1 DO BEGIN							
		print, 'Calculating flux on '+nrh_filenames[i]
		for j=0., nseconds do begin
			loadct, 39, /silent
			t0 = tstart + j*1.0D

			t0str = anytim(t0, /yoh, /trun, /time_only)
			;t1str = anytim(tend, /yoh, /trun, /time_only)

			read_nrh, nrh_filenames[i], $
					  nrh_hdr, $
					  nrh_data, $
					  hbeg=t0str;, $ 
					  ;hend=t1str
			
			;index2map, nrh_hdr, nrh_data, $
			;	   nrh_map  

			nrh_str_hdr = nrh_hdr
			nrh_time = nrh_hdr.date_obs
			freq_tag = string(nrh_hdr.freq, format='(I03)')
			
			;--------------------------------------------------------;
			;					Plot Total I
			;
			;wset, 0
			;plot_map, nrh_map, $
			;		  title='NRH '+freq_tag+' MHz '+$
			;		  string( anytim( nrh_time, /yoh, /trun) )+' UT'		  
			
			;set_line_color
			;plot_helio, nrh_times, $
			;			/over, $
			;			gstyle=1, $
			;			gthick=1.0, $
			;			gcolor=1, $
			;			grid_spacing=15.0			
	
				
			;loadct, 39, /silent
			
			;-------------------------------------;
			;	   Now plot raw data structure
			;
			;nrh_data = nrh_map.data
			data_section = nrh_data[75:120, 30:70]
			indices = where(data_section ge max(data_section)*0.5)
			xy_indices = array_indices(data_section, indices)
			
			;wset, 1
			;plot_image, data_section > 1e5
			
			;loadct, 0
			;plots, xy_indices[0, *], xy_indices[1, *], /data, psym=1, color=255

			total_Tb = TOTAL(data_section[indices])		;summing over specified source area
			freq = nrh_hdr.freq * 1e6			;calculate flux
			lambda = c / freq
			constant = (2.* k_B * domega) / (lambda^2.)
			flux = constant * total_Tb	; in SFU

			;print, 'Source Flux: '+string(flux)+' (sfu)'

			if j eq 0. then fluxes = flux else fluxes = [fluxes, flux]
			if j eq 0. then times = nrh_time else times = [times, nrh_time]
		endfor			

		times = anytim(times, /utim)
		if i eq 0 then flux_struct = create_struct(name='nrh_fluxes', 'nrh_'+freq_tag, [[times], [fluxes]] ) $
			else flux_struct = add_tag(flux_struct, [[times], [fluxes]], 'nrh_'+freq_tag) 
	
	ENDFOR
	save, flux_struct, filename='flux_density_spectrum.sav', description='From type IIIs to type IV.'
	return, flux_struct
		
END
