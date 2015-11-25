pro nrh_flux_pulsations

	; Calculate the flux of remote sources during the pulsations of 2014-04-18.
	
	folder = '~/Data/2014_apr_18/radio/nrh/'
	cd, folder
	nrh_filenames = findfile('*.fts')
	;---------------------------------------------------------------;
	;	  Read Data 5 min chunks to prevent RAM overload
	;
	window, 0, xs=400, ys=400, retain=2
	window, 1, xs=400, ys=400, retain=2
	loadct, 39, /silent
	!p.charsize=1.5
	
	tstart = anytim(file2time('20140418_125400'), /utim)
	tend = anytim(file2time('20140418_125800'), /utim)

	nseconds = tend - tstart
	Ray = 32.0								; Solar_R in nrh_hdr_array
	domega = FLOAT(16 * 3E-4 /Ray)^2. 		; Solid angle. Below is a summation of pixels of Tb, which is effectively and integral
											; of Tbx1unit pixels. We need an integral of TbxDomega. So after the summation of Tb
											; we multiply by a factor of solid angle per pixel. 16 here is degrees of solar radius.
											; 32 is number of pixels per radius. 3e-14 comes from (1/60)x(pi/180), conversion ot degrees
											; then to radians.
	c = 299792458. 			; Speed of light in m/s
	k_B = 0.138				; Boltzmann constant k=1.38e-23, for SFU: K*e+22

	;;FOR i=0, n_elements(nrh_filenames)-1 DO BEGIN							
		i=1
		for j=0., nseconds do begin
			loadct, 39, /silent
			t0 = tstart + j*1.0D
		    ;tend = anytim(file2time('20140418_131500'), /utim)

			t0str = anytim(t0, /yoh, /trun, /time_only)
			;t1str = anytim(tend, /yoh, /trun, /time_only)

			read_nrh, nrh_filenames[i], $
					  nrh_hdr, $
					  nrh_data, $
					  hbeg=t0str;, $ 
					  ;hend=t1str
			
			index2map, nrh_hdr, nrh_data, $
					   nrh_map  

			nrh_str_hdr = nrh_hdr
			nrh_time = nrh_hdr.date_obs
			
			;--------------------------------------------------------;
			;					Plot Total I
			;
			freq_tag = string(nrh_hdr.freq, format='(I03)')
		
			wset, 0
			plot_map, nrh_map, $
					  title='NRH '+freq_tag+' MHz '+$
					  string( anytim( nrh_time, /yoh, /trun) )+' UT'		  
			
			set_line_color
			plot_helio, nrh_times, $
						/over, $
						gstyle=1, $
						gthick=1.0, $
						gcolor=1, $
						grid_spacing=15.0			
		
			;x2png, 'nrh_'+freq_tag+'_'+time2file(nrh_times[i], /sec)+'_nr_scl.png'			
			loadct, 39, /silent
			cgcolorbar, range = [min(nrh_map.data), max(nrh_map.data)], $
					/vertical, $
					/right, $
					color=255, $
					/ylog, $
					pos = [0.87, 0.15, 0.88, 0.85], $
					title = 'Brightness Temperature (log(T[K]))', $
					FORMAT = '(e10.1)'

			;--------------------------------------;
			;	   Now plot raw data structure
			;
			nrh_data = nrh_map.data
			data_section = nrh_data[40:100, 10:70]
			indices = where(data_section ge max(data_section)*0.5)
			xy_indices = array_indices(data_section, indices)
			wset, 1
			plot_image, data_section > 1e5

			if j eq 0 then begin
				print, 'Choose source region '
				point, x, y, /data
			endif			
			source_section  = data_section[ x[0]:x[1], y[0]:y[1]]	

			;loadct, 0
			;plots, xy_indices[0, *], xy_indices[1, *], /data, psym=1, color=255

			total_Tb = TOTAL(source_section)		;summing over specified source area
			freq = nrh_hdr.freq * 1e6			;calculate flux
			lambda = c / freq
			constant = (2.* k_B * domega) / (lambda^2.)
			flux = constant * total_Tb	; in SFU

			print, 'Source Flux: '+string(flux)+' (sfu)'

			if j eq 0. then fluxes = flux else fluxes = [fluxes, flux]
			if j eq 0. then times = nrh_time else times = [times, nrh_time]

		endfor			

		window, 2, xs=1000, ys=400
		times = anytim(times, /utim)
		utplot, times, fluxes, $
			ytitle = 'Flux (SFU)', $
			/xs, $
			/ys, $
			/ylog

STOP
		if i eq 0 then flux_struct = create_struct(name='nrh_fluxes', 'nrh_'+freq_tag, [[times], [fluxes]] ) $
			else flux_struct = add_tag(flux_struct, [[times], [fluxes]], 'nrh_'+freq_tag) 
	
	;ENDFOR

	STOP
END
