pro aia_imgs_20140418

  ;Code to produce running difference aia images of the event
  ;on 2014-Apr-14
  
  ;-------------------------------------------------;
  ;			Choose files unaffected by AEC
  cd,'~/Data/2014_Apr_18/sdo/171A/'
  aia_files = findfile('aia*.fits')
  mreadfits_header, aia_files, ind, only_tags='exptime'
  f = aia_files[where(ind.exptime gt 1.)]
  
  ;-------------------------------------------------;
  ;					Read data
  read_sdo, f[0], $
		he_aia_pre, $
		data_aia_pre
  read_sdo, f[1], $
		he_aia, $
		data_aia
  index2map, he_aia_pre, $
  		smooth(data_aia_pre,5)/he_aia_pre.exptime, $
		map_aia_pre, $
		outsize = 1024
  index2map, he_aia, $
  		smooth(data_aia,5)/he_aia.exptime, $
		map_aia, $
		outsize = 1024		
	
  ;-------------------------------------------------;
  ;				  Plot diff image	
  loadct,1
  window, xs=700, ys=700
  ;FOV = [35.0, 35.0]
  ;CENTER = [500.0, -150.0]
  plot_map, diff_map(map_aia, map_aia_pre), $
		dmin = -7.0, $
		dmax = 5.0;, $
		;fov = FOV,$
		;center = CENTER
  
  set_line_color
  plot_helio, he_aia.date_obs, $
		/over, $
		gstyle=0, $
		gthick=1.0, $	
		gcolor=1, $
		grid_spacing=15.0

END
