pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.5
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=9, $
          ysize=8, $
          bits_per_pixel=16, $
          /encapsulate, $
          yoffset=5

end


pro nrh_aia_special_oplot, diff_img=diff_img, hue=hue, postscript=postscript

	;NRH and AIA composite images for 2014 April 18 event

	;-------------------------------------------------;
	;			Choose files unaffected by AEC
	aia_folder = '~/Data/2014_Apr_18/sdo/171/'
	cd, aia_folder
	aia_files = findfile('aia*.fits')
	mreadfits_header, aia_files, ind, only_tags='exptime'
	f = aia_files;[where(ind.exptime gt 1.)]

	tstart = anytim(file2time('20140418_125359'), /utim)
	tend   = anytim(file2time('20140418_132500'), /utim)

	mreadfits_header, f, ind
	aia_files = f[where(anytim(ind.date_obs, /utim) ge tstart) - 5]


	winsz = 600.0
	
	  	FOR i = 5, n_elements(aia_files)-15 DO BEGIN

	  	  	;------------------------------------------------;
			;				 	Plot AIA
			;
	  	  	cd, aia_folder
	  	  	FOV = [9.0, 9.0]
			CENTER = [600.0, -250.0] 	 
			;FOV = [16.6, 16.6]
			;CENTER = [500.0, -350.0]


	  	  	if keyword_set(diff_img) then begin
				read_sdo, aia_files[i-5], $
					he_aia_pre, $
					data_aia_pre
				read_sdo, aia_files[i], $
					he_aia, $
					data_aia
				index2map, he_aia_pre, $
					data_aia_pre/he_aia_pre.exptime, $
					map_aia_pre, $
					outsize = 4096
				index2map, he_aia, $
					data_aia/he_aia.exptime, $
					map_aia, $
					outsize = 4096	
					
				map_aia = diff_map(map_aia, map_aia_pre)
				min_val = -25
				max_val = 25.0	
			endif else begin
				read_sdo, aia_files[i], $
					he_aia, $
					data_aia
			  	index2map, he_aia, $
					data_aia/he_aia.exptime, $
					map_aia, $
					outsize = 4096
			  	min_val = -20
			  	max_val = 200.0		
			endelse		
		  
		  	if keyword_set(postscript) then begin
		  		setup_ps, '~/source_merge1.eps'
			endif else begin
				loadct, 1
				!p.background=255
				!p.color=0
				window, xs=winsz, ys=winsz, retain = 2
				!p.charsize=1.5
			endelse
			;--------------------------------------------------;
			;				  Plot diff image	
			loadct, 0, /silent
			plot_map, map_aia, $
				dmin =  min_val, $
				dmax = max_val, $
				fov = FOV,$
				center = CENTER, $
				/notitle
				
			plot_helio, he_aia.date_obs, $
				/over, $
				gstyle=0, $
				gthick=1.0, $	
				gcolor=255, $
				grid_spacing=15.0

			;x1 = 520.0
			;y1 = -210.0
			;npoints = 100.0
			;angles = [20.0, 340.0, 300.0, 260.0]
			;for j = 0, n_elements(angles)-1 do begin
			;	radius = 300	;arcsec
			;	angle = angles[j]
			;	x2 = x1 + radius*cos(angle*!dtor)	;808.0	
			;	y2 = y1 + radius*sin(angle*!dtor)	;-120.0
			;	xlin = ( findgen(npoints)*(x2 - x1)/(npoints-1) ) + x1
			;	ylin = ( findgen(npoints)*(y2 - y1)/(npoints-1) ) + y1	 			
			;	set_line_color
			;	plots, xlin, ylin, /data, color=4, thick=2.5
			;endfor	
			    
			
			cd, '~/Data/2014_Apr_18/radio/nrh/'
			nrh_filenames = findfile('*.fts')

			;for j=0, n_elements(nrh_filenames)-1 do begin
			j=7
				;-------------------------------------------------;
				;					PLOT NRH
				;
				tstart = anytim(he_aia.date_obs, /utim) ;+ 3.0
				t0 = anytim(tstart, /yoh, /trun, /time_only)
			  	
				nrh_file_index = j
				read_nrh, nrh_filenames[nrh_file_index], $	; 432 MHz
						nrh_hdr, $
						nrh_data, $
						hbeg=t0
										
				index2map, nrh_hdr, nrh_data, $
						 nrh_map  
			  
				
				;     Now over plot the contours.	 
				nrh_data = smooth(nrh_data, 5)
				nrh_data = alog10(nrh_data)
				nrh_map.data = nrh_data		  

				if keyword_set(hue) then begin
					loadct,3
					CENTER[0] = CENTER[0] - nrh_map.xc
					CENTER[1] = CENTER[1] - nrh_map.yc

					;     Using tv, so everything needs to be defined in window and array coordinates.
					gridx = (winsz*0.85 - winsz*0.15)
					nrh_data_new = nrh_data
					nrh_data_new = congrid(nrh_data_new, gridx, gridx)

					;window, 2, xs=winsz, ys=winsz
					array_dimen = size(nrh_data_new)
					xpix = array_dimen[1]
					newdx = ( nrh_map.dx/ (gridx/128.0) ) ; "/pixel
					zoomx = ((FOV[0]*60.0)/ newdx)/2.0
					pix0 = (xpix/2.0 + center[0]/newdx) - zoomx
					pix1 = (xpix/2.0 + center[0]/newdx) + zoomx
					pix2 = (xpix/2.0 + center[1]/newdx) - zoomx
					pix3 = (xpix/2.0 + center[1]/newdx) + zoomx

					data_zoom = nrh_data_new[pix0:pix1, pix2:pix3]	
					max_val = max( (nrh_data) ,/nan) 		
					tv, bytscl(congrid(data_zoom, gridx, gridx), 0.95*max(data_zoom, /nan), max(data_zoom, /nan) ), $ ;bottom value usually 0.9 of max
							channel=1, $
							0.15, $
							0.15, $
							/normal
				endif			
			  	
					
				plot_helio, he_aia.date_obs, $
					/over, $
					gstyle=0, $
					gthick=1.0, $	
					gcolor=255, $
					grid_spacing=15.0		

				;		Define contour levels
				max_val = max( (nrh_data) ,/nan) 							   
				nlevels=5.0   
				top_percent = 0.98
				levels = (dindgen(nlevels)*(max_val - max_val*top_percent)/(nlevels-1.0)) $
							+ max_val*top_percent
				;levels = (dindgen(nlevels)*(max_val - 7.0)/(nlevels-1.0)) $
				;			+ 7.0		

				set_line_color
				plot_map, nrh_map, $
					/overlay, $
					/cont, $
					/noerase, $
					levels=levels, $
					;/noxticks, $
					;/noyticks, $
					/noaxes, $
					thick=7, $
					color=0



				plot_helio, nrh_hdr.date_obs, $
					/over, $
					gstyle=0, $
					gthick=3.0, $	
					gcolor=255, $
					grid_spacing=15.0


				set_line_color
				plot_map, nrh_map, $
					/overlay, $
					/cont, $
					levels=levels, $
					/noxticks, $
					/noyticks, $
					/noaxes, $
					thick=5, $
					color=4


				; Just for black contour labels	
				plot_map, nrh_map, $
					/overlay, $
					/cont, $
					levels=levels, $
					/noxticks, $
					/noyticks, $
					/noaxes, $
					thick=-1, $
					color=1							 	

				freq_tag = string(nrh_hdr.freq, format='(I03)')
				;xyouts, 0.5, 0.86, 'AIA 171A, NRH '+freq_tag+' MHz  '+he_aia.date_obs+' UT', $
				xyouts, 0.5, 0.86, 'AIA '+string(he_aia.wavelnth, format='(I3)')+' '+he_aia.date_obs+' UT', $
						/normal, $
						alignment=0.5, $
						charsize=1.0

				;xyouts, 0.16, 0.82 - (j)/50.0, 'NRH '+freq_tag+' MHz (1e'+string(max_val, format='(f3.1)')+' K)', $
				;		color=0, $
				;		charthick=3, $
				;		/normal	

				;xyouts, 0.16, 0.82 - (j)/50.0, 'NRH '+freq_tag+' MHz (1e'+string(max_val, format='(f3.1)')+' K)', $
				;		color=j, $
				;		charthick=1.5, $
				;		/normal		

				;xyouts, 0.5, 0.82, nrh_hdr.date_obs+' UT', $
				;		/normal, $
				;		color=0, $
				;		charthick=3

				;xyouts, 0.5, 0.82, nrh_hdr.date_obs+' UT', $
				;		/normal, $
				;		color=2, $
				;		charthick=1.5		
	

			;endfor				

			;xyouts, 0.15, 0.05, 'Contour levels: '+$
			;				string(levels[0], format='(f3.1)')+$
			;				' < log!L10!N(T!LB!N [K]) < '+$
			;				string(levels[nlevels-1], format='(f3.1)'), $
			;				/normal, $
			;				charsize=2.0, $
			;				charthick=1.5


			freq_tag = string(nrh_hdr.freq, format='(I03)')
			
			if keyword_set(postscript) then begin
				device, /close
				set_plot,'x'
			endif
			;x2png, 'image_'+string(i-5, format='(I03)')+'.png'			
STOP
			if anytim(he_aia.date_obs, /utim) gt tend then BREAK


	    ENDFOR
STOP
	    cd, '~/Data/2014_Apr_18/radio/nrh/'
	    spawn, 'ffmpeg -y -r 25 -i image_%03d.png -vb 50M aia'+string(he_aia.wavelnth, format='(I3)')+'_nrh_all_freq.mpg'
	    spawn, 'rm image_*.png'
	    spawn, 'mv aia'+string(he_aia.wavelnth, format='(I3)')+'_nrh_all_freq.mpg ~/Data/2014_apr_18'
 



END