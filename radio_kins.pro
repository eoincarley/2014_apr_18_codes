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
	; A code to examine the influence of different models and radio drift of various features using 2014-Apr-18 event.
	;

	rsun = 6.95e8	; m
	models = ['saito', 'newkirk', 'baum', 'leblanc', 'mann'];, 'hydro_stat']
	colors=[4, 5, 6, 7, 10]	
	folder = '~/Data/2014_apr_18/radio/kinematics/'
	radio_kins_files = findfile(folder+'/*kins*.sav')
	nsteps = 100
	max_fold = 20.
	min_fold = 1.

	for i=0, n_elements(radio_kins_files)-1 do begin

		folds = (findgen(nsteps)*(max_fold-min_fold)/(nsteps-1))+min_fold
		speeds = fltarr(nsteps)
		all_model_speeds = findgen(n_elements(speeds), n_elements(models))

		restore, radio_kins_files[i], /verb
		times = radio_kins.times
		freqs = radio_kins.freqs
		tim_sec = times - times[0]
		density = freq_to_dens( (freqs*1e6)/2.0 )

		;---------------------------------------------------------;
		;		Set up kinematics structure for each burst
		;
		burst_speeds = {name:radio_kins.name, times:radio_kins.times}

		setup_ps, folder+'/radio_kins_model_test_'+radio_kins.name+'.eps'
		;window, i, xs=400, ys=500
		;set_line_color
		plot, [min_fold, max_fold], [100, 4000], $
				/xs, $
				/ys, $
				/ylog, $
				/nodata, $
				;xtitle='Fold of the model', $
				xtickformat='(A1)', $
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

				;if limit_found eq 0 and total(rads ge 1.1) eq float(n_elements(rads)) then begin
				;	physical_limit = [folds[k], speeds[k]]
				;	print, folds[k]
				;	limit_found = 1
				;endif	

				; This finds the model fold at which the largest frequency (lowest heigt) data position
				; is close to and active region height ~150 Mm or ~1.2 Rsun heliocentric distance.
				if min(rads) ge 1.14 and limit_found eq 0 then begin
					physical_limit = [folds[k], speeds[k]]
					limit_found = 1
					print, folds[k]
				endif	


			endfor
					
			oplot, folds, speeds, $
				color=colors[j]

			plots, physical_limit[0], physical_limit[1], psym=4, color=3, symsize=1, thick=2	

			burst_speeds = add_tag(burst_speeds, [physical_limit[0], physical_limit[1]], models[j]+'_fold_speed')

			all_model_speeds[*, j] = speeds

		endfor
	
		save, burst_speeds, filename=folder+radio_kins.name+'_burst_model_speeds.sav'

		if i eq 1 then result=execute("legend, models, color=colors, linestyle=[0,0,0,0,0], box=0., /right, /top") else $
			result=execute("legend, models, color=colors, linestyle=[0,0,0,0,0], box=0., /right, /bottom")

		
		;---------------------------------------------------------;
		; Plot standard deviation as function of model and fold		
		; The fold that fives the smallest standard deviation is the one to be used.
		sigma_letter = Greek('sigma')

		sdev = stddev(all_model_speeds, dim=2, /nan)
		plot, folds, sdev, $
				yr=[10, 1000], $
				/xs, $
				/ys, $
				/ylog, $
				xtitle='Fold of the model', $
				ytitle=sigma_letter+'!X (km s!U-1!N)', $
				;title=radio_kins.name, $
				position = [0.18, 0.12, 0.95, 0.37], $
				/noerase	

		fold_min_sig = folds[where(sdev eq min(sdev))]		

		xyouts, 0.20, 0.15, 'Fold at min '+sigma_letter+': '+string(fold_min_sig, format='(f4.1)')+'!X', /normal

		device, /close
		set_plot, 'x'


	endfor


END