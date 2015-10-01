pro aia_diff_imgs_20140418

  ;Code to produce running difference aia images of the event
  ;on 2014-Apr-14
  
  ;-------------------------------------------------;
  ;			Choose files unaffected by AEC
  cd,'~/Data/2014_Apr_18/sdo/211A/'
  aia_files = findfile('aia*.fits')
  mreadfits_header, aia_files, ind, only_tags='exptime'
  f = aia_files[where(ind.exptime gt 1.)]
  
  window, xs=700, ys=700, retain = 2
  !p.charsize=1.5
  loadct, 3
  
  FOR i = 60, 200 DO BEGIN ;n_elements(f)-2 DO BEGIN
  	  print,i
  	  ;-------------------------------------------------;
      ;			 		Read data
	  read_sdo, f[i], $
			he_aia_pre, $
			data_aia_pre
	  read_sdo, f[i+5], $
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
		
	  ;-------------------------------------------------;
	  ;				  Plot diff image	
	  FOV = [15.0, 15.0]
	  CENTER = [500.0, -350.0]
	  plot_map, diff_map(map_aia, map_aia_pre), $
			dmin = -25.0, $
			dmax = 25.0, $
			fov = FOV,$
			center = CENTER
	  
	  plot_helio, he_aia.date_obs, $
			/over, $
			gstyle=0, $
			gthick=1.0, $	
			gcolor=255, $
			grid_spacing=15.0
	
	  ;x2png, 'aia_'+string(he_aia.wavelnth, format='(I3)')+'A_'$
	  			;+time2file(he_aia.date_obs, /sec)+'_rdiff.png'
	  stop
  ENDFOR		

END
