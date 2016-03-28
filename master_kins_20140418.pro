pro master_kins_20140418, postscript=postscript

	folder = '~/Data/2014_apr_18/combos/'
	set_line_color
	if keyword_set(postscript) then begin
		!p.font = 0
		!p.charsize = 1.2
		!p.thick=1
		set_plot, 'ps'
		device, filename=folder+'kinematics_plot_v2.eps', $
				/encapsulate, $
				/color, $ 
				/inches, $
				/helvetica, $
				;bits_per_pixel=8, $
				xs=6, $
				ys=10

	endif else begin
		!p.background=255
		!p.color=0
		!p.symsize=1
		!p.charsize = 1.5
		!p.charthick = 0.5
		;!p.thick=1
		window, 1, xs=600, ys=1200
	endelse

	tstart = anytim('2014-apr-18T12:20:00', /utim)
	tend = anytim('2014-apr-18T13:30:00', /utim)

	plotlinsy = [findgen(10), 10.0*findgen(10), 100*findgen(10), 1000, 2000]
	plotlinsx = tstart + findgen(14)*5.0*60.0
	loadct, 0
	utplot, [tstart, tend], [1, 3000], $
		/nodata, $
		/ys, $
		/xs, $, 
		/ylog, $
		position = [0.15, 0.07, 0.9, 0.52]

	for i=1, n_elements(plotlinsy)-1 do outplot, [tstart, tend], [plotlinsy[i], plotlinsy[i]], color=210, linestyle=0, thick=0.5
	for i=1, n_elements(plotlinsx)-1 do outplot, [plotlinsx[i], plotlinsx[i]], [1, 3000],  color=210, linestyle=0, thick=0.5


	set_line_color
	deproject = 1./cos(45.0*!dtor)
	;---------------------------;
	;		AIA kinematics
	;
	aia_dt_kins, tstart, tend, deproject

	;deproject = 1.
	;---------------------------;
	;	  Radio kinematics
	;
	colors=[4,5,6,7,10]	
	radio_kins_files = findfile('~/Data/2014_apr_18/radio/kinematics/*_burst_model_speeds.sav')
	for i=0, n_elements(radio_kins_files)-1 do begin

		restore, radio_kins_files[i], /verb
		times = burst_speeds.times
		median_time = median(times)
		time_range = abs([times[0], times[n_elements(times)-1]] - median_time)
		rvels = [ burst_speeds.SAITO_FOLD_SPEED[1], $
				  burst_speeds.NEWKIRK_FOLD_SPEED[1], $
				  burst_speeds.BAUM_FOLD_SPEED[1], $
				  burst_speeds.LEBLANC_FOLD_SPEED[1], $
				  burst_speeds.MANN_FOLD_SPEED[1] ];, $
				  ;burst_speeds.ST_HILAIRE_FOLD_SPEED[1] ]
					  
		max_vel = max(rvels)
		min_vel = min(rvels)
		mean_vel = mean(rvels) 

		PLOTSYM, 0, /fill
		outplot, [median_time], [mean_vel], psym=8, color=0, symsize=1.2
		outplot, [median_time], [mean_vel], psym=8, color=colors[i], symsize=1.0
		PLOTSYM, 0
		oploterror, [median_time], [mean_vel], time_range[0], [max_vel-mean_vel]*deproject, /nobar, /hibar, /nohat, psym=8, color=0, symsize=1.2
		oploterror, [median_time], [mean_vel], time_range[0], [min_vel-mean_vel], /lobar, /nohat, psym=8, color=0, symsize=1.2

		print, '-------------------'
		print, 'Speed for '+radio_kins_files[i]+': '+string(mean_vel)+' + '+string([max_vel-mean_vel]*deproject)+' - '+string([min_vel-mean_vel])
		STOP
	endfor


	;---------------------------------;
	;	Radio source motion kinematics
	;	Derived using nrh_plot_xy_motion.pro
	;
	rad_src_speed = 370.0;*deproject
	radio_src_tim0 = anytim('2014-04-18T12:48:30', /utim)
	radio_src_tim1 = anytim('2014-04-18T12:52:30', /utim)
	radio_src_tim2 = anytim('2014-04-18T12:56:10', /utim)
	radio_src_tim_range = [radio_src_tim1 - radio_src_tim0]



	PLOTSYM, 0, /fill
	outplot, radio_src_tim1, [rad_src_speed], psym=8, color=9, symsize=1.2
	PLOTSYM, 0
	outplot, radio_src_tim1, [rad_src_speed], psym=8, color=0, symsize=1.2
	oploterror, radio_src_tim1, [rad_src_speed], radio_src_tim_range, [80*deproject] + [rad_src_speed*deproject - rad_src_speed], /hibar, /nohat, psym=8, color=0, symsize=1.2
	oploterror, radio_src_tim1, [rad_src_speed], radio_src_tim_range, [80], /lobar, /nohat, psym=8, color=0, symsize=1.2


	;---------------------------------;
	;	EUV front kinematics
	;	Derived using aia_three_color.pro point and click to get x and y arcsecs, 
	;	then using euv_front_kins.pro to get velocity from the displacment.
	;
	euv_front_speed = 817.0;*deproject ;km/s
	euv_front_time = anytim('2014-04-18T12:59:11', /utim)
	euv_front_time_range = [anytim('2014-04-18T12:56:23.620', /utim), anytim('2014-04-18T13:01:59.630', /utim)] - anytim('2014-04-18T12:59:11', /utim)

	PLOTSYM, 0, /fill
	outplot, [euv_front_time], [euv_front_speed], psym=8, color=0, symsize=1.2
	outplot, [euv_front_time], [euv_front_speed], psym=8, color=3, symsize=1.2
	PLOTSYM, 0
	oploterror, [euv_front_time], [euv_front_speed], euv_front_time_range[0], [180.0]*deproject  + [euv_front_speed*deproject - euv_front_speed], /hibar, /nohat, psym=8, color=0, symsize=1.2
	oploterror, [euv_front_time], [euv_front_speed], euv_front_time_range[0], [180.0], /lobar, /nohat, psym=8, color=0, symsize=1.2

	;---------------------------------;
	;	CME front kinematics
	;	Derived using cme_kins_20140418.pro point and click
	;
	cme_speed = 1140.0;*deproject
	cme_time = anytim('2014-04-18T13:25:00', /utim)
	cme_time_range = [anytim('2014-04-18T13:25:00', /utim), anytim('2014-04-18T13:30:00', /utim)] - cme_time

	PLOTSYM, 0, /fill
	outplot, [cme_time], [cme_speed], psym=8, color=0, symsize=1.2
	outplot, [cme_time], [cme_speed], psym=8, color=0, symsize=1.2
	
	PLOTSYM, 0
	oploterror, [cme_time], [cme_speed], [170.]*deproject + [cme_speed*deproject - cme_speed], /hibar, /nohat, psym=8, color=0, symsize=1.2
	oploterror, [cme_time], [cme_speed], [170.], /lobar, /nohat, psym=8, color=0, symsize=1.2
	oploterror, [cme_time], [cme_speed], cme_time_range[1], [0.0]*deproject, /nohat, /hibar, psym=8, color=0, symsize=1.2

	if keyword_set(postscript) then begin
		device, /close
		set_plot, 'x'
	endif
STOP

END