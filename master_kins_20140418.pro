pro master_kins_20140418

	loadct, 0
	!p.background=255
	!p.color=0
	!p.symsize=1
	!p.font = 0
	!p.charsize = 1.5
	!p.charthick = 0.5
	!p.thick=1
	set_line_color

	if keyword_set(ps) then begin
		set_plot, 'ps'
		device, filename=folder+'kinematics_plot.eps', $
				/encapsulate, $
				/color, $ 
				/inches, $
				/helvetica, $
				bits_per_pixel=32, $
				xs=5, $
				ys=9
	endif else begin
		window, 1, xs=600, ys=1200
	endelse

	tstart = anytim('2014-apr-18T12:20:00', /utim)
	tend = anytim('2014-apr-18T13:30:00', /utim)

	;utplot, [tstart, tend], [1, 2500], $
	;	/xs, $
	;	/ys, $
	;	/nodata

	;---------------------------;
	;		AIA kinematics
	;
	aia_kins, tstart, tend

	
	;---------------------------;
	;	  Radio kinematics
	;
	colors=[4,5,6,7,10]	
	radio_kins_files = findfile('~/Data/2014_apr_18/radio/kinematics/*kins*.sav')
	for i=0, n_elements(radio_kins_files)-1 do begin

		restore, radio_kins_files[i], /verb
		times = radio_kins.times
		start_time = median(times)
		rvels = [ radio_kins.mann, $
				 radio_kins.saito, $
				 radio_kins.newkirk, $
				 radio_kins.baum];, $ 
				; radio_kins.leblanc ]	
					  
		max_vel = max(rvels)
		min_vel = min(rvels)
		mean_vel = mean(rvels) 

		PLOTSYM, 0, /fill
		outplot, [start_time], [mean_vel], psym=8, color=0, symsize=1.2
		outplot, [start_time], [mean_vel], psym=8, color=colors[i], symsize=1.0
		PLOTSYM, 0
		oploterror, [start_time], [mean_vel], max_vel, /hibar, psym=8, color=0, symsize=1.2
		oploterror, [start_time], [mean_vel], min_vel, /lobar, psym=8, color=0, symsize=1.2

	endfor

END