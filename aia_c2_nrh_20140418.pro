pro aia_c2_nrh_20140418

  ; Code to combine AIA, NRH and C2 observations of eruptive event on 2014-Apr-18
  
  winsz=700
  !p.charsize=1.5
  loadct,3
  window, 0, xs=winsz, ys=winsz
  
  ;--------------------------------------;
  ;----------------C2 Data---------------;
  ;--------------------------------------;
  cd,'~/Data/2014_Apr_18/white_light/lasco/c2/l1/'
  c2_files = findfile('*.fts')
  
  c2index=1
  pre = lasco_readfits(c2_files[c2index], c2hdr_pre)
  mask = lasco_get_mask(c2hdr_pre)
  pre = pre*mask
  
  img = lasco_readfits(c2_files[c2index+1], c2hdr)
  img = img*mask
  
  imgbs = img - pre
  imgbs = (imgbs- mean(imgbs))/stdev(imgbs)
  
  ;img_filt = disk_nrgf(img, c2hdr, 0, 0)
  ;pre_filt = disk_nrgf(pre, c2hdr_pre, 0, 0) 
  ;imgbs = img_filt - pre_filt
  
  c2map = make_map(imgbs)
  c2map.dx = 11.9
  c2map.dy = 11.9
  c2map.xc = 14.4704
  c2map.yc = 61.2137
  
  FOV = [5500/60.0, 5500/60.0]
  CENTER = [1000.0, -1000.0]
	
  plot_map, c2map, $
  		dmin = -1.0, $
  		dmax = 2.0, $
		title='AIA NRGF, LASCO BASE DIFF', $
		fov=FOV, $
		center = CENTER
  
  
  ;--------------------------------------;
  ;---------------AIA Data---------------;
  ;--------------------------------------;
  cd,'~/Data/2014_Apr_18/sdo/171A/'
  aia_files = findfile('aia*.fits')
  mreadfits_header, aia_files, ind, only_tags='exptime'
  f = aia_files[where(ind.exptime gt 1.)]
  mreadfits_header, f, ind
  aia_times = anytim(ind.date_obs, /utim)
  
  index = closest(aia_times, anytim(c2hdr.date_obs, /utim))
  
  read_sdo, f[index-5], $
		hdr_aia_pre, $
		data_aia_pre
  read_sdo, f[index], $
		hdr_aia, $
		data_aia
  index2map, hdr_aia_pre, $
		smooth(data_aia_pre, 1)/hdr_aia_pre.exptime, $
		map_aia_pre, $
		outsize = 1024
  index2map, hdr_aia, $
		smooth(data_aia, 1)/hdr_aia.exptime, $
		map_aia, $
		outsize = 1024		

	  ;redu_factor = he_aia_pre.naxis1/(size(map_aia_pre.data))[1]*1d
	  ;he_aia_pre.naxis1 = (size(map_aia_pre.data))[1]
	  ;he_aia_pre.naxis2 = (size(map_aia_pre.data))[1]
	  ;he_aia_pre.cdelt1 = he_aia_pre.cdelt1*redu_factor
	  ;he_aia_pre.cdelt2 = he_aia_pre.cdelt2*redu_factor
	  ;he_aia_pre.crpix1 = he_aia_pre.crpix1/redu_factor
	  ;he_aia_pre.crpix2 = he_aia_pre.crpix2/redu_factor	
	  
	  ;read_sdo, f[i], $
		;	he_aia, $
		;	data_aia
	  
	  ;index2map, he_aia, $
	;		smooth(data_aia, smoothing)/he_aia.exptime, $
;			map_aia, $
;			outsize = 2048
	  	
	  redu_factor = hdr_aia.naxis1/(size(map_aia.data))[1]*1d
	  hdr_aia.naxis1 = (size(map_aia.data))[1]
	  hdr_aia.naxis2 = (size(map_aia.data))[1]
	  hdr_aia.cdelt1 = hdr_aia.cdelt1*redu_factor
	  hdr_aia.cdelt2 = hdr_aia.cdelt2*redu_factor
	  hdr_aia.crpix1 = hdr_aia.crpix1/redu_factor
	  hdr_aia.crpix2 = hdr_aia.crpix2/redu_factor
	  
	  ;map_aia_pre.data = disk_nrgf(map_aia_pre.data, he_aia_pre, 0, 0)
	  map_aia.data = disk_nrgf(map_aia.data, hdr_aia, 0, 0)
  ;				  Plot diff image	
  
  loadct,3
  plot_map, map_aia, $ 			;diff_map(map_aia, map_aia_pre), $
  		/composite, $
  		/average, $
		dmin = -1.0, $
		dmax = 3.0, $
		/noaxes
		
  set_line_color
  plot_helio, hdr_aia.date_obs, $
  		/over, $
  		gstyle=1, $
  		gthick=1, $
  		gcolor=1, $
  		grid_spacing=15
  		
  ;--------------------------------------;
  ;---------------NRH Data---------------;
  ;--------------------------------------;		
  cd,'~/Data/2014_Apr_18/radio/nrh/'
  tstart = anytim(hdr_aia.date_obs, /utim) - 10.0*60.0 
  tend = anytim(file2time('20140418_132154'), /utim)  
  t0 = anytim(tstart, /yoh, /trun, /time_only)
  t1   = anytim(tend, /yoh, /trun, /time_only)
  
  nrh_filenames = findfile('*.fts')
  read_nrh, nrh_filenames[n_elements(nrh_filenames)-2], $	; 445 MHz
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
  nrh_index = closest( anytim(nrh_times, /utim), anytim(hdr_aia.date_obs, /utim) )
  
  ;     Now over plot the contours.	 
  nrh_map.data = nrh_data
  ;			Define contour levels
  max_val = max( (nrh_data[*, *, nrh_index]) ,/nan) 									   
  nlevels=5.0   
  top_percent = 0.95
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
		thick=1.0, $
		color=4		

  freq_tag = string(nrh_hdr[0].freq, format='(I03)')
  wave_tag = string(hdr_aia.WAVELNTH, format='(I03)')
  xyouts, 0.15, 0.90, 'NRH '+freq_tag+' MHz:  '+nrh_hdr[nrh_index].date_obs +' UT', /normal
  xyouts, 0.15, 0.93, 'AIA '+wave_tag+'A:  '+ hdr_aia.date_obs +' UT', /normal
  xyouts, 0.15, 0.96, 'LASCO C2:  '+ c2hdr.date_obs +' UT', /normal
stop
END