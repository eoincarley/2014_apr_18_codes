pro setup_ps, name
  
  set_plot,'ps'
  !p.charsize=1.0
  device, filename = name, $
          /color, $
          /inches, $
          bits_per_pixel = 16, $
          xsize=7, $
          ysize=7, $
          /encapsulate, $
          yoffset=5

end


pro jazzy_nrh_aia_imgs_20140418

  ;NRH and AIA composite images for 2014 April 18 event
  
  ;Jazzing up nrh_aia_imgs_20140418 for the solar group promo catalogue
  
  ;-------------------------------------------------;
  ;			Choose files unaffected by AEC
  cd,'~/Data/2014_Apr_18/sdo/171A/'
  aia_files = findfile('aia*.fits')
  mreadfits_header, aia_files, ind, only_tags='exptime'
  f = aia_files[where(ind.exptime gt 1.)]
  
  tstart = anytim(file2time('20140418_124800'),/utim)
  tend   = anytim(file2time('20140418_124958'),/utim)
  
  mreadfits_header, f, ind
  aia_files = f[where(anytim(ind.date_obs, /utim) ge tstart) - 5]
  
  ;window, xs=700, ys=700, retain = 2
  ;!p.charsize=1.5
  setup_ps, 'jazzy_aia_nrh.eps'
  
  	i = 5
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
	  
	  ;-----------------------------;
	  ;				  Plot diff image	
	  FOV = [15.0, 15.0]
	  CENTER = [500.0, -350.0]
	  loadct, 1, /silent
	  plot_map, diff_map(map_aia, map_aia_pre), $
			dmin = -25.0, $
			dmax = 25.0, $
			fov = FOV,$
			center = CENTER, $
			title = ' ', $
			xtitle = ' ', $
			ytitle = ' '
			
	  plot_helio, he_aia.date_obs, $
			/over, $
			gstyle=0, $
			gthick=7.0, $	
			gcolor=255, $
			grid_spacing=15.0
	
		    
	  ;------------------------------;
	  ;					PLOT NRH
	  tstart = anytim(he_aia.date_obs, /utim) 
	  tend = anytim(he_aia.date_obs, /utim) + 1.0*60.0
	  t0 = anytim(tstart, /yoh, /trun, /time_only)
	  t1   = anytim(tend, /yoh, /trun, /time_only)
  	  
	  cd,'~/Data/2014_Apr_18/radio/nrh/'
	  nrh_filenames = findfile('*.fts')
	  read_nrh, nrh_filenames[n_elements(nrh_filenames)-1], $	; 445 MHz
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
	  
	  ;			Define contour levels
	  max_val = max( (nrh_data[*, *, nrh_index]) ,/nan) 									   
	  nlevels=5.0   
	  top_percent = 0.95
	  levels = (dindgen(nlevels)*(max_val - max_val*top_percent)/(nlevels-1.0)) $
				+ max_val*top_percent  
	  
	  set_line_color
	  plot_map, nrh_map[nrh_index], $
			/overlay, $
			/cont, $
			levels=levels, $
			/noxticks, $
			/noyticks, $
			/noaxes, $
			thick=7, $
			color=6
			
		device, /close
		set_plot, 'x'	
	 
	 ;tv, bytscl( congrid(map_nrh_V_neg.data, 402, 402), -1e7, 5e7), channel=1, 0.58, 0.55, /normal		


END