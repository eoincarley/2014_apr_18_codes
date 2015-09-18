pro nrh_aia_special_oplot

  ;NRH and AIA composite images for 2014 April 18 event
  
  ;-------------------------------------------------;
  ;			Choose files unaffected by AEC
  cd,'~/Data/2014_Apr_18/sdo/171A/'
  aia_files = findfile('aia*.fits')
  mreadfits_header, aia_files, ind, only_tags='exptime'
  f = aia_files[where(ind.exptime gt 1.)]
  
  tstart = anytim(file2time('20140418_124800'),/utim)
  tend   = anytim(file2time('20140418_132158'),/utim)
  
  mreadfits_header, f, ind
  aia_files = f[where(anytim(ind.date_obs, /utim) ge tstart) - 5]
  
  winsz = 800.0
  loadct, 1
  !p.background=255
  !p.color=0
  window, xs=winsz, ys=winsz, retain = 2
  !p.charsize=1.5
  
  FOR i = 5, n_elements(aia_files)-6 DO BEGIN
  	  cd,'~/Data/2014_Apr_18/sdo/171A/'
	  ;-------------------------------------------------;
	  ;				 	Plot AIA
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
	  FOV = [16.6, 16.6]
	  CENTER = [500.0, -350.0]
	  loadct, 1, /silent
	  plot_map, diff_map(map_aia, map_aia_pre), $
			dmin = -25.0, $
			dmax = 25.0, $
			fov = FOV,$
			center = CENTER, $
			/notitle
			
	  plot_helio, he_aia.date_obs, $
			/over, $
			gstyle=0, $
			gthick=1.0, $	
			gcolor=255, $
			grid_spacing=15.0
	
	
	  ;x2png, 'aia_'+string(he_aia.wavelnth, format='(I3)')+'A_'$
	  ;			+time2file(he_aia.date_obs, /sec)+'_rdiff.png'


	x1 = 520.0
	y1 = -210.0
	npoints = 100.0
	angles = [20.0, 340.0, 300.0, 260.0]
	for j = 0, n_elements(angles)-1 do begin
		radius = 300	;arcsec
		angle = angles[j]
		x2 = x1 + radius*cos(angle*!dtor)	;808.0	
		y2 = y1 + radius*sin(angle*!dtor)	;-120.0
		xlin = ( findgen(npoints)*(x2 - x1)/(npoints-1) ) + x1
		ylin = ( findgen(npoints)*(y2 - y1)/(npoints-1) ) + y1	 			
	 	set_line_color
		plots, xlin, ylin, /data, color=4, thick=2.5
	endfor	
		    
	  ;-------------------------------------------------;
	  ;					PLOT NRH
	  tstart = anytim(he_aia.date_obs, /utim) 
	  tend = anytim(he_aia.date_obs, /utim) + 1.0*60.0
	  t0 = anytim(tstart, /yoh, /trun, /time_only)
	  t1   = anytim(tend, /yoh, /trun, /time_only)
  	  
	  cd,'~/Data/2014_Apr_18/radio/nrh/'
	  nrh_filenames = findfile('*.fts')
	  read_nrh, nrh_filenames[n_elements(nrh_filenames)-2], $	; 432 MHz
				nrh_hdr, $
				nrh_data, $
				hbeg=t0, $ 
				hend=t1	
							
	  index2map, nrh_hdr, nrh_data, $
				 nrh_map  
	  
	  nrh_data = alog10(nrh_data)
	  nrh_map.data = nrh_data
			
	  ;			Find closest NRH image to AIA		
	  nrh_str_hdr = nrh_hdr
	  nrh_times = nrh_hdr.date_obs
	  nrh_index = closest( anytim(nrh_times, /utim), anytim(he_aia.date_obs, /utim) )
	  
	  
	  loadct,3
	  CENTER[0] = CENTER[0] - nrh_map[nrh_index].xc
	  CENTER[1] = CENTER[1] - nrh_map[nrh_index].yc
	  
	  
	  nrh_data = nrh_data^10.0
	  nrh_map.data = nrh_data
	  
	  ;     Using tv, so everything needs to be defined in window and array coordinates.
	  gridx = (winsz*0.85 - winsz*0.15)
	  nrh_data_new = nrh_data[*,*, nrh_index]
	  nrh_data_new = congrid(nrh_data_new, gridx, gridx)
	  
	  ;window, 2, xs=winsz, ys=winsz
	  array_dimen = size(nrh_data_new)
	  xpix = array_dimen[1]
	  newdx = ( nrh_map[nrh_index].dx/ (gridx/128.0) ) ; "/pixel
	  zoomx = ((FOV[0]*60.0)/ newdx)/2.0
	  pix0 = (xpix/2.0 + center[0]/newdx) - zoomx
	  pix1 = (xpix/2.0 + center[0]/newdx) + zoomx
	  pix2 = (xpix/2.0 + center[1]/newdx) - zoomx
	  pix3 = (xpix/2.0 + center[1]/newdx) + zoomx
	  
	  data_zoom = nrh_data_new[pix0:pix1, pix2:pix3]	
	  tv, bytscl(congrid(data_zoom, gridx, gridx), 0.1*max(data_zoom, /nan), max(data_zoom, /nan) ), $
	  		channel=1, $
	  		0.15, $
	  		0.15, $
	  		/normal
	  	
			
	  plot_helio, he_aia.date_obs, $
			/over, $
			gstyle=0, $
			gthick=1.0, $	
			gcolor=255, $
			grid_spacing=15.0		
	 
	  ;     Now over plot the contours.	 
	  nrh_data = alog10(nrh_data)
	  nrh_map.data = nrh_data
	  ;			Define contour levels
	  max_val = max( (nrh_data[*, *, nrh_index]) ,/nan) 									   
	  nlevels=5.0   
	  top_percent = 0.97
	  levels = (dindgen(nlevels)*(max_val - max_val*top_percent)/(nlevels-1.0)) $
				+ max_val*top_percent  
	  
	  ;			Overlay NRH contours
	  set_line_color
	  plot_map, nrh_map[nrh_index], $
			/overlay, $
			/cont, $
			levels=levels, $
			/noxticks, $
			/noyticks, $
			/noaxes, $
			thick=2.5, $
			color=6		
	 
	 
	 freq_tag = string(nrh_hdr[0].freq, format='(I03)')
	 xyouts, 0.5, 0.86, 'AIA 171A, NRH '+freq_tag+' MHz  '+he_aia.date_obs+' UT', $
	 		/normal, $
	 		alignment=0.5, $
	 		charsize=2.0
		
	 xyouts, 0.15, 0.05, 'Contour levels: '+$
	 				string(levels[0], format='(f3.1)')+$
	 				' < log!L10!N(T!LB!N [K]) < '+$
	 				string(levels[nlevels-1], format='(f3.1)'), $
	 				/normal, $
	 				charsize=2.0, $
	 				charthick=1.5
	 freq_tag = string(nrh_hdr[0].freq, format='(I03)')
	 x2png, string(i, format='(I03)')+'_'+freq_tag+'.png'; 'aia_'+string(he_aia.wavelnth, format='(I3)')+'A_'$
	  			;+time2file(he_aia.date_obs, /sec)+'_rdiff.png'		

 ENDFOR
 


END