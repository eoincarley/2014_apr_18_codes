pro nrh_imgs_20140418

	;Code to produce pngs of NRH observations of the 2014 April 18 event 
	;Produces pngs for all frequencies
	;Written 2014-Oct-2
	
	cd,'~/Data/2014_Apr_18/nrh/'
	filenames = findfile('*.fts')
	;--------------------------------------------------------;
	;	  Read Data 5 min chunks to prevent RAM overload
	;
	window, 0, xs=700, ys=700, retain=2
	loadct, 3, /silent
	!p.charsize=1.5
	tstart = anytim(file2time('20110922_124800'),/utim)
	tend   = anytim(file2time('20110922_132158'),/utim)
	FOR k=1, n_elements(filenames)-1 DO BEGIN			;LOOP THROUGH THE FILES
		FOR j=0., 6. DO BEGIN							;LOOP THROUGH 5 MIN CHUNKS
			t0 = anytim(tstart, /utim) + j*5.0*60.0
			t1   = anytim(tstart, /utim) + (j+1.0)*5.0*60.0
			
			IF t1 le tend then t1 = t1 else t1 = tend
			t0 = anytim(t0, /yoh, /trun, /time_only)
			t1   = anytim(t1, /yoh, /trun, /time_only)
		
			print,' '
			print, t0
			print, t1
			print,' '
			print, anytim(tend, /yoh)
			
			read_nrh, filenames[k], $
					  nrh_hdr, $
					  nrh_data, $
					  hbeg=t0, $ 
					  hend=t1
			
			index2map, nrh_hdr, nrh_data, $
					   nrh_map  
			
			nrh_str_hdr = nrh_hdr
			nrh_times = nrh_hdr.date_obs
			
			;--------------------------------------------------------;
			;					Plot Total I
			;
			freq_tag = string(nrh_hdr[0].freq, format='(I03)')
			IF j eq 0. THEN spawn,'mkdir '+freq_tag+'mhz'
			cd, freq_tag+'mhz'
			
			FOR i=0, n_elements(nrh_times)-1, 10 DO BEGIN	;LOOP THROUGH IMAGES
				plot_map, nrh_map[i], $
						  title='NRH '+string(nrh_hdr[0].freq, format='(I03)')+' MHz '+$
						  string( anytim( nrh_times[i], /yoh, /trun) )+' UT'
				
				plot_helio, nrh_times[i], $
							/over, $
							gstyle=1, $
							gthick=1.0, $
							gcolor=254, $
							grid_spacing=15.0
							
				x2png, 'nrh_'+freq_tag+'_'+time2file(nrh_times[i], /sec)+'.png'			
			ENDFOR			
			cd,'..'		
		ENDFOR
	ENDFOR
END
