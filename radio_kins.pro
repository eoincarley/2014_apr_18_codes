pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.0
   !p.thick=6
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=4, $
          ysize=5, $
          bits_per_pixel=16, $
          /encapsulate, $
          yoffset=5

end

pro radio_kins
	
	;
	; Uses output of ft_to_speed. Only the frequency and time values are used!! Speed is calculated here again as a
	; function of model fold. The fold at which the model gives a pre defined height for a given frequency is saved.
	;
	; A code to examine the influence of different models and radio drift of various features using 2014-Apr-18 event.
	;

	!p.charsize=1.5
	set_line_color
	c = 2.9e5   ; km/s
	rsun = 6.95e8	; m
	models = ['saito', 'newkirk', 'baum', 'st_hilaire_0', 'leblanc'];, 'mann', 'hydro_stat']
	colors=[4, 5, 6, 7, 8, 10]	
	folder = '~/Data/2014_apr_18/radio/kinematics/type_III/'
	radio_drift_files = findfile(folder+'/*drift*.sav')	
	nsteps = 100
	max_fold = alog10(100.)
	min_fold = -1

	for i=0, n_elements(radio_drift_files)-1 do begin

		folds = 10^( (findgen(nsteps)*(max_fold-min_fold)/(nsteps-1))+min_fold )
		speeds = fltarr(nsteps)
		all_model_speeds = findgen(n_elements(speeds), n_elements(models))

		print, '**************************************'
		print, 'Restoring: ' + radio_drift_files[i]
		restore, radio_drift_files[i], /verb
		times = radio_drift.times   	;From ft_to_speed
		freqs = radio_drift.freqs
		tim_sec = times - times[0]

		window, 5, xs=400, ys=400, xpos=2000, ypos=2000
		plot, tim_sec, freqs, $
			/xs, $
			/ys, $
			;xr=[-0.1, 0.4], $
			psym=4, $
			;yr=[290, 140], $
			xtitle='Time (s)', $
			ytitle='Freqyency (MHz)'



		oplot, tim_sec, freqs	 
		result = linfit(tim_sec, freqs, yfit=yfit)	 
		drift_rate = result[1]
		oplot, tim_sec, yfit, linestyle=1

		density = freq_to_dens( (freqs*1e6)/2.0 )
		density0 = freq_to_dens( 298e6/2.0 )		;Frequency chosen to normalise models

		;---------------------------------------------------------;
		;		Set up kinematics structure for each burst
		;
		burst_speeds = {name:models[i], times:radio_drift.times}

		;setup_ps, folder+'/radio_kins_model_test_'+radio_kins.name+'.eps'
		window, i, xs=400, ys=500
		set_line_color
		plot, [10.^min_fold, 10.^max_fold], [1e4, 1e6], $
				/xs, $
				/ys, $
				/ylog, $
				/xlog, $
				/nodata, $
				xr=[10.0^min_fold, 10.0^max_fold], $
				;xtitle='Fold of the model', $
				;xtickformat='(A1)', $
				ytitle='Speed (km s!U-1!N)', $
				;title=radio_kins.name, $
				position = [0.18, 0.4, 0.95, 0.95]		

		;-----------------------------------------------;
		; Plot speeds as a function of model and fold
		for j=0, n_elements(models)-1 do begin
			limit_found = 0
			for k=0, n_elements(folds)-1 do begin
				
				rads = density_to_radius(density, model=models[j], fold=folds[k])
				result = linfit(tim_sec, rads, yfit=yfit)
				speeds[k] = result[1]*rsun/1e3 	; km/s

				rads0 = density_to_radius(density0, model=models[j], fold=folds[k])

				;if limit_found eq 0 and total(rads ge 1.1) eq float(n_elements(rads)) then begin
				;	physical_limit = [folds[k], speeds[k]]
				;	print, folds[k]
				;	limit_found = 1
				;endif	

				; This finds the model fold at which the 445.0 MHz (lowest heigt) is
				; is close to an sigmoid height of ~50 Mm or ~1.07 Rsun heliocentric distance.
				; print, rads0
				if min(rads0) ge 1.16 and limit_found eq 0 then begin
					physical_limit = [folds[k], speeds[k]]
					limit_found = 1
					print, 'Drift Rate (MHz/s): '+ string(drift_rate)
					print, 'Model: '+string(models[j])
					print, 'Fold: '+string(folds[k])
					speed = speeds[k]
					print, 'Apparent speed (c): ' + string(speed/c)

					v_app = speed
					v_real = (c*v_app)/( c + v_app)
					print, 'Real speed (c): ' + string(v_real/c)
					print, '-----------------'
					print, ' '

				endif	

			endfor
					
			set_line_color		
			oplot, folds, speeds, $
				color=colors[j]

			plots, physical_limit[0], physical_limit[1], psym=4, color=3, symsize=1, thick=2	

			burst_speeds = add_tag(burst_speeds, [physical_limit[0], physical_limit[1]], models[j]+'_fold_speed')

			all_model_speeds[*, j] = speeds

		endfor
		folder = '~/'
		;save, burst_speeds, filename=folder+radio_kins.name+'_burst_model_speeds_100Mm.sav'

		if i eq 1 then result=execute("legend, models, color=colors, linestyle=[0,0,0,0,0,0], box=0., /right, /top") else $
			result=execute("legend, models, color=colors, linestyle=[0,0,0,0,0,0], box=0., /right, /bottom")

		
		;---------------------------------------------------------;
		;
		; Plot standard deviation as function of model and fold		
		; The fold that fives the smallest standard deviation is 
		; the one to be used.
		;
		sigma_letter = Greek('sigma')

		sdev = stddev(all_model_speeds, dim=2, /nan)
		plot, folds, sdev, $
			;	yr=[1e, 1000], $
				/xs, $
				/ys, $
				/ylog, $
				/xlog, $
				xtitle='Fold of the model', $
				ytitle=sigma_letter+'!X (km s!U-1!N)', $
				;title=radio_kins.name, $
				position = [0.18, 0.10, 0.95, 0.35], $
				/noerase	

		fold_min_sig = folds[where(sdev eq min(sdev))]		

		xyouts, 0.20, 0.15, 'Fold at min '+sigma_letter+': '+string(fold_min_sig, format='(f4.1)')+'!X', /normal

		;device, /close
		set_plot, 'x'
STOP
	endfor


END