pro nrh_imgs_20140418, folder, f1, f2, win

	;Code to produce pngs of NRH observations of the 2014 April 18 event 
	;Produces pngs for all frequencies
	;Written 2014-Oct-2
	cd, folder
	filenames = findfile('*.fts')
	;---------------------------------------------------------------;
	;	  Read Data 5 min chunks to prevent RAM overload
	;
	window, win, xs=700, ys=700, retain=2
	loadct, 39, /silent
	!p.charsize=1.5
	tstart = anytim(file2time('20140418_124800'),/utim)
	tend   = anytim(file2time('20140418_130000'),/utim)


	FOR k=f1, f2 DO BEGIN			;LOOP THROUGH THE FILES
		image_count = 0
		FOR j=0., 5. DO BEGIN							;LOOP THROUGH 5 MIN CHUNKS
			
			t0 = anytim(tstart, /utim) + j*5.0*60.0
			t1   = anytim(tstart, /utim) + (j+1.0)*5.0*60.0 < tend

			t0str = anytim(t0, /yoh, /trun, /time_only)
			t1str = anytim(t1, /yoh, /trun, /time_only)

			print, t0str
			print, t1str
			print, '-----------'


			read_nrh, filenames[k], $
					  nrh_hdr, $
					  nrh_data, $
					  hbeg=t0str, $ 
					  hend=t1str
			
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
			
			FOR i=0, n_elements(nrh_times)-1 DO BEGIN	;LOOP THROUGH IMAGES
				plot_map, nrh_map[i], $
						  title='NRH '+string(nrh_hdr[0].freq, format='(I03)')+' MHz '+$
						  string( anytim( nrh_times[i], /yoh, /trun) )+' UT'
				
				set_line_color
				plot_helio, nrh_times[i], $
							/over, $
							gstyle=1, $
							gthick=1.0, $
							gcolor=1, $
							grid_spacing=15.0			
			
				;x2png, 'nrh_'+freq_tag+'_'+time2file(nrh_times[i], /sec)+'_nr_scl.png'			
				loadct, 39, /silent
				cgcolorbar, range = [min(nrh_map[i].data), max(nrh_map[i].data)], $
						/vertical, $
						/right, $
						color=255, $
						/ylog, $
						pos = [0.87, 0.15, 0.88, 0.85], $
						title = 'Brightness Temperature (log(T[K]))', $
						FORMAT = '(e10.1)'
		

				x2png, 'nrh_'+string(image_count, format='(I03)')+'.png'
				image_count = image_count+1

			ENDFOR			
			cd,'..'		
			if t1 ge tend then BREAK

		ENDFOR
		cd, freq_tag+'mhz'
		spawn, 'ffmpeg -y -r 25 -i nrh_%03d.png -vb 50M nrh_'+freq_tag+'mhz_'+time2file(tstart, /sec)+'_ncl.mpg'
		spawn, 'rm *.png'
		cd,'..'	
	ENDFOR
END
