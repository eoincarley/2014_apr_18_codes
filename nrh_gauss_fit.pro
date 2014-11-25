pro nrh_gauss_fit

;Now uses mpfit2dfun and gauss2dfit...

	window, 0, xs=1000, ys=700
	window, 1, xs=800, ys=800
	window, 2, xs=500, ys=500, xpos=1000, ypos=100
	window, 3, xs=500, ys=500, xpos=600, ypos=100
	window, 4, xs=500, ys=500, xpos=200, ypos=100
	!p.multi = [0,1,1]
	!p.charsize = 1.5
	cd, '~/Data/2014_apr_18/radio/nrh'
	files = findfile('*.fts') 
	tstart = anytim(file2time('20140418_124800'), /yoh, /trun, /time_only)
	tend   = anytim(file2time('20140418_132158'), /yoh, /trun, /time_only)
	read_nrh, files[n_elements(files)-2], $
			nrh_hdr, $
			nrh_data, $
			hbeg=tstart, $
			hend=tend
			
	index2map, nrh_hdr, nrh_data, nrh_struc  
	nrh_struc_hdr = nrh_hdr
	nrh_times = nrh_hdr.date_obs

	gauss_pos = fltarr(2, n_elements(nrh_times) )
	gauss_peak = fltarr( n_elements(nrh_times) )
	gauss_fits = fltarr(7, n_elements(nrh_times) )
	manual_peak = fltarr( n_elements(nrh_times) )
	manual_pos = fltarr(2, n_elements(nrh_times) )
	box = 4
	
	FOR i=0, n_elements(nrh_times)-1 DO BEGIN

		;-------------------------------------------;
		; 			Define Map Params
		img = nrh_data[*, *, i]
		map_nrh = make_map(img)
		map_nrh.dx = 29.9410591125 ;arcseconds per pixel
		map_nrh.dy = 29.9410591125 ;arcseconds per pixel
		map_nrh.xc = 64. ;center pixel value
		map_nrh.yc = 64. ; 
		
		;-------------------------------------------;
		; 			Plot the map and image
		wset, 1
		loadct, 3, /silent
		plot_image, img, title=nrh_times[i]
	
		;-------------------------------------------;
		; 			Select Source Peak
		IF i eq 0 THEN BEGIN
			print, 'Please select source peak...'
			cursor, x, y
			x = round(x) 
			y = round(y) 
			manual_pos[0,i] = x 
			manual_pos[1,i] = y 
		ENDIF ELSE BEGIN    
			x = manual_pos[0, i-1]
			y = manual_pos[1, i-1]
		ENDELSE	
		
		;-------------------------------------------;
		; 			Extract image section
		x1 = x - box
		x2 = x + box 
		y1 = y - box
		y2 = y + box 
		data_section = img[x1:x2, y1:y2]
		manual_peak[i] = max(data_section)    
		pos_index = where(data_section eq manual_peak[i] )
		xy_pos = array_indices(data_section, pos_index)
		xpos = x1 + xy_pos[0]
		ypos = y1 + xy_pos[1]
		manual_pos[0,i] = xpos
		manual_pos[1,i] = ypos
		plots, xpos, ypos, psym=4, color=5
		
		wset, 0
		!p.multi=[0, 2, 2]
		plot_image, data_section
		shade_surf, data_section, charsize=3
		
		;-------------------------------------------;
		; Embed image section in large array of constant values 
		; (easier for Gauss-fit to handle)
		x_len = (size(data_section))[1]
		y_len = (size(data_section))[2]
		mode = get_mode(img)
		junk_array = dblarr(x_len + 50.0, y_len + 50) + mode[0] ;Mode is good estimate of quiet thermal
		junk_array[25:25+x_len-1, 25:25+y_len-1] = alog10(data_section) > mode[0]
		
		
		;---------------------------------------
		;			  FIT 2D Gauss 
		result = gauss2dfit(junk_array, a, /tilt)
			;Since gauss2dfit doens't give errors, use 'a' as start values
			;for mpfit2dfun (which provides errors).
		start_parms = a
		xjunk = dindgen( n_elements(junk_array[*,0]) )
		yjunk = dindgen( n_elements(junk_array[0,*]) )
		gauss_fit = MPFIT2DFUN('my2Dgauss', xjunk, yjunk, junk_array, ERR, $
			start_parms, perror=perror, yfit=yfit)
		
		loadct, 3, /silent
		plot_image, yfit
		shade_surf, yfit, charsize=3.0
	
		IF finite(max(yfit)) eq 1 THEN BEGIN
			peak_result = where(yfit eq max(yfit))
			loc_result = array_indices(yfit, peak_result)
			loc_section = loc_result - 25.0
			peak_TB = max(yfit)
		ENDIF ELSE BEGIN
			print,'Not using Gaussian fit'	
			save, data_section, filename = 'test_on_gauss_2d.sav'
			peak = max(data_section)
			peak_loc = where(data_section eq peak)
			loc_section = array_indices(data_section, peak_loc)
			peak_TB = peak
		ENDELSE
		
		; Put location in the image section (extracted above) back into whole image
		gauss_fit[4] = gauss_fit[4] - 25. + x1
		gauss_fit[5] = gauss_fit[5] - 25. + y1
		loc_whole = [loc_section[0] + x1, loc_section[1] + y1]
		gauss_pos[0,i] = loc_whole[0]
		gauss_pos[1,i] = loc_whole[1]
		gauss_peak[i] = peak_TB
		gauss_fits[*, i] = gauss_fit[*]
		
		loadct, 3, /silent 
		!p.multi = [0,1,1]
		wset, 2
		plot_image, data_section, charsize=1.0
		set_line_color
		plots, loc_section[0], loc_section[1], psym=1, color=5, symsize=3
		plots, xy_pos[0], xy_pos[1], psym=4, color=3, symsize=3
		
		loadct, 3, /silent 
		wset, 3
		plot_image, img, title=nrh_times[i]
		set_line_color
		plots, loc_whole[0], loc_whole[1], psym=1, color=5, symsize=3
		plots, xpos, ypos, psym=1, color=4, symsize=3
		tvcircle, (nrh_struc_hdr[i].SOLAR_R), $
			64.0, 64.0, 254, /data, color=255, thick=1
		
		result = my2Dgauss_test( findgen(128), findgen(128), gauss_fit)
		wset, 4
		loadct, 3
		plot_image, result,	title=nrh_times[i]
		tvcircle, (nrh_struc_hdr[i].SOLAR_R), $
			64.0, 64.0, 254, /data, color=255, thick=1	
			
	ENDFOR

	window, 5, xs=800, ys=500, xpos=100, ypos=100 
	utplot, nrh_times, manual_peak, /xs, psym=1
	save, manual_pos, manual_peak, gauss_fits, nrh_times, $
		filename = 'src1_xypeak_432mhz.sav', $
		description = 'Source 1 at active region center'
	
	
END

; 			End main procedure
;***********************************************

function get_mode, img

	array4mode = alog10(img)
	remove_nans, array4mode, array4mode
	distfreq = Histogram(array4mode, MIN=Min(array4mode))
	maxfreq= Max(distfreq)
	mode = Where(distfreq EQ maxfreq) + Min(array4mode)
	return, mode
	
END	

function my2Dgauss, x, y, pars

	;This is for use in mpfit2dfun above

	z = dblarr(n_elements(x),n_elements(y))

	FOR i = 0, n_elements(x)-1.0 DO BEGIN
		FOR j=0, n_elements(y)-1.0 DO BEGIN
			T = pars[6]
			xp = (x[i]-pars[4])*cos(T) - (y[j]-pars[5])*sin(T)
			yp = (x[i]-pars[4])*sin(T) - (y[j]-pars[5])*cos(T)
			U = (xp/pars[2])^2.0 + (yp/pars[3])^2.0
			z[i,j] = pars[0] + pars[1]*exp(-U/2.0)
		ENDFOR
	ENDFOR	

	return, z
END


