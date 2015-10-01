pro aia_imgs_20140418, diff_img=diff_img

  ;Code to produce running difference aia images of the event
  ;on 2014-Apr-14
  
  ;-------------------------------------------------;
  ;			Choose files unaffected by AEC
	
  	folder = '~/Data/2014_Apr_18/sdo/171A/'
	cd, folder
	aia_files = findfile('aia*.fits')
	mreadfits_header, aia_files, ind, only_tags='exptime'
	files = aia_files[where(ind.exptime gt 1.)]

	loadct, 0
	window, 3, xs=1400, ys=700, retain = 2
	!p.color=0
	!p.background=255
	!p.charsize=1.5
	!p.multi=[0,2,1]
	;FOV = [4.0, 4.0]
	;CENTER = [520.0, -200.0]
	FOV = [16.6, 16.6]
	CENTER = [500.0, -350.0]


	FOR i = 10, n_elements(files)-1 DO BEGIN

		;-------------------------------------------------;
		;			 		Read data
		if keyword_set(diff_img) then begin

			read_sdo, aia_files[i-5], $
				he_aia_pre, $
				data_aia_pre
			read_sdo, aia_files[i], $
				he_aia, $
				data_aia
			index2map, he_aia_pre, $
				smooth(data_aia_pre, 1)/he_aia_pre.exptime, $
				map_aia_pre, $
				outsize = 4096
			index2map, he_aia, $
				smooth(data_aia, 1)/he_aia.exptime, $
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
		  	max_val = 260.0		
		endelse		
		
	    ;-------------------------------------;
	    ;			  Plot map

		loadct, 49, /silent		;49 for 131
		reverse_ct
		plot_map, map_aia, $
			dmin = min_val, $	;-20 for 131
			dmax = max_val, $   ;260 for 131
			fov = FOV,$
			center = CENTER

		plot_helio, he_aia.date_obs, $
			/over, $
			gstyle=0, $
			gthick=1.0, $	
			gcolor=255, $
			grid_spacing=15.0

		loadct, 16, /silent
		plot_map, map_aia, $
			dmin = min_val, $
			dmax = max_val, $
			fov = FOV,$
			center = CENTER

		plot_helio, he_aia.date_obs, $
			/over, $
			gstyle=0, $
			gthick=1.0, $	
			gcolor=255, $
			grid_spacing=15.0	
	

	    x2png, folder + '/image_'+string(i-10, format='(I03)' )+'.png', /silent
		
		progress_percent, i, 10, n_elements(files)-1

	ENDFOR		
STOP
	date = '20140418'
	movie_type = '171A_diff'
	cd, folder
	spawn, 'ffmpeg -y -r 25 -i image_%03d.png -vb 50M SDO_AIA_'+date+'_'+movie_type+'.mpg'

END
