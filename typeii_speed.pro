pro typeii_speed, ps = ps

	!p.font = 0
	!p.charsize = 0.8
	!p.charthick = 0.5
	cd, '~/Data/2014_Apr_18/radio/'
	
	if keyword_set(ps) then begin
		set_plot, 'ps'
		device, filename='typeii_kins_20140418.eps', $
				/encapsulate, $
				/color, $ 
				/inches, $
				/helvetica, $
				bits_per_pixel=32, $
				xs=4, $
				ys=10
	endif else begin
		window, 0, xs=400, ys=1000
	endelse
	
	xposl = 0.15
	xposr = 0.9

	cd,'~/Data/2014_Apr_18/radio/orfees'
	restore,'ft_dam_orfees_20140418.sav', /verb
	
	;---------------------------------;
	;		Plot frequency time
	;
	utplot, ft[0,*], ft[1,*], $
			/ylog, $
			ytitle = 'Frequency (MHz)', $
			title = 'Frequency-time points for 2014-Apr-18 type II', $
	  		position = [xposl, 0.71, xposr, 0.97], $
	  		/noerase, $
	  		psym=6

	;---------------------------------;
	;		Plot density time
	;
	n_e = freq2dens((ft[1,*]*1e6)/2.0)
	utplot, ft[0, *], n_e, $
			title='Electron desnity, assuming 2nd harmonic', $
			/ylog, $
			ytitle = 'Electron number density (cm!U-3!N)', $
	  		position = [xposl, 0.38, xposr, 0.63], $
	  		/noerase, $
	  		psym=5
	
	;-------------------------------------------;
	;		Plot heliocentric distance-time
	;
	hd = density_to_radius(n_e)		
	utplot, ft[0, *], hd , $
			title='Heliocen. dist., 5xSaito QS model', $
			ytitle = 'Heliocentric distance of radio burst (Rsun)', $
			yr = [1, 3.0], $
			psym=4, $
	  		position = [xposl, 0.05, xposr, 0.30], $
	  		/noerase
			
			
	;--------------------------------------;
	;			Linear fit
	;
	tim_sec = ft[0, *]  - ft[0,0]
	result = linfit(tim_sec, hd, yfit=yfit)
	speed = result[1]*6.695e5  ; km/s
	
	print,'--------------------------------------'
	print,'Linear fit				 '
	print,'Speed: '+string(speed) + ' km/s'
	print,'--------------------------------------'
	tim_sim = (dindgen(100)*(30.0*60.0 - (-10.0*60.0) )/99.0 ) -10.0*60.0
	hd_sim = result[0] + result[1]*tim_sim
	outplot, ft[0, 0] + tim_sim, hd_sim, linestyle=1
	
	;--------------------------------------;
	;			Non-linear fit fit
	;
	start = [0, result[1], result[0]]
	
	fit = 'p[0]*x^2 + p[1]*x + p[2]'			
	p = mpfitexpr(fit, tim_sec , hd, err, yfit=yfit, start)

	set_line_color
	tim_sim = (dindgen(100)*(30.0*60.0 - (-10.0*60.0) )/99.0 ) -10.0*60.0
	hd_sim = p[0]*tim_sim^2.0 + p[1]*tim_sim + p[2]
	outplot, ft[0,0] + tim_sim, hd_sim, color=5, thick=4
	
	speed = p[1]*6.695e5		; km/s 
	accel = p[0]*6.695e8		; m/s/s
	print,'--------------------------------------'
	print,'Non-linear fit				 '
	print,'Speed: '+string(speed) + ' km/s'
	print,'Accel: '+string(accel) + ' m/s/s'
	print,'--------------------------------------'
	
	
	legend, ['Linear fit: ', $
			 '  -Speed: '+string(result[1]*6.695e5, format='(I04)')+' (km s!U-1!N)', $
			 'Quadratic fit: ', $
			 '  -Init. speed: '+ string(speed, format='(I03)')+' (km s!U-1!N)', $
			 '  -Accel.: '+ string(accel, format='(I03)')+' (m s!U-2!N)'], $
			color=[0, 1, 5, 1, 1], $
			linestyle = [1, 0, 0, 0, 0], $
			box=0, $
			/left, $
			/top
	
	if keyword_set(ps) then begin
		device, /close
		set_plot,'x'
	endif
		
END