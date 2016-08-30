pro manual_detection, date, ints, average_window, tonset, $
				onset_times = onset_times, plot_sep = plot_sep

	; manual_detection_linfit in a seperate .pro file is also an option here 

	plot_sep_zoom = "utplot, date, ints, /noerase, /xs, /ys, yr = yzoom, xr=xzoom, /ylog, ytitle = 'Intensity (cm!U-2!N sr!U-1!N s!U-1!N MeV!U-1!N)', xticklen = 1.0, xgridstyle = 1.0, yticklen = 1.0, ygridstyle = 1.0, /normal"
	print, 'Choose region of zoom: '
	cursor, t_zoom_point, i_zoom_point, /data

	; Choose 1 hr around this window.
	t0_zoom	= t_zoom_point - 1.0*60.*60.;2.0*60.*60.
	t1_zoom	= t_zoom_point + 0.5*60.*60.;5.0*60.*60.
	xzoom = [t0_zoom, t1_zoom]

	i0_zoom = i_zoom_point - i_zoom_point*0.25
	i1_zoom = i_zoom_point + i_zoom_point*2.5
	yzoom = [i0_zoom, i1_zoom]

	window, 1, xs=600, ys=600
	junk = execute(plot_sep_zoom)

	ints_zoom = ints[ where(date gt t0_zoom and date lt t1_zoom) ]
	date_zoom = date[ where(date gt t0_zoom and date lt t1_zoom) ]
	
	i_mean = mean(  ints[ where(date gt t0_zoom and date lt t_zoom_point) ] )
	i_stdv = stdev( ints[ where(date gt t0_zoom and date lt t_zoom_point) ] )

	mean_line = ints_zoom
	mean_line[*] = i_mean
	sd_line = ints_zoom
	sd_line[*] = i_stdv

	set_line_color
	plots, date_zoom, i_mean, color=3
	plots, date_zoom, i_mean + 2.0*i_stdv, linestyle=3, color=5
	
	;point, x, y, /data
	;print, (x[1]-x[0])/60.0

	print, 'Choose onset: '
	cursor, tonset, i_junk, /data
	;tonset=x[1]
	print, 'Onset time: ' + anytim(tonset, /cc)

END


pro sigma_detection, date, ints, onset, average_window, $
				onset_times = onset_times, plot_sep = plot_sep

	; Simple standard deviation threshold detection
	; Outlined in Malandraki et al. (2012)
			
	set_line_color
	minutes = average_window

	for i=0, n_elements(ints)-5 do begin	; Loop throw intensity v time until detection found
		
		junk = execute(plot_sep)
		tcenter = date[i]
		plots, tcenter, ints[i], /data, psym=1, symsize=3, color=3

		t0 = tcenter - minutes*60.0
		t1 = tcenter + minutes*60.0

		t0_index = closest(date, t0)
		t1_index = closest(date, t1)  <  (n_elements(ints)-5)

		ints_sub = ints[t0_index:t1_index]
		time_sub = date[t0_index:t1_index]

		plots, time_sub, ints_sub, /data, color=5
		;plots, erne_date[t1_index+1], ints[t1_index+1], /data, psym=4, symsize=3, color=4	

		ints_mean = mean( ints_sub )
		ints_sdev = stdev( ints_sub ) > 0.05*ints_mean 
			;if i mod 10 eq 0 then print, ints_sdev/ints_mean

		dummy_img = dist(450, 800)
		dummy_img[*] = 0.0
		tv, dummy_img	

		hist = HISTOGRAM( ints_sub, binsize = 0.15*ints_mean ) 
		bins = (  FINDGEN( N_ELEMENTS(hist) )*(MAX(ints_sub) - MIN(ints_sub))/(N_ELEMENTS(hist))  ) + MIN( ints_sub ) 
		PLOT, bins, hist, $
			;xr = [0, 5], $
			YRANGE = [MIN(hist)-1, MAX(hist)+1], $
			PSYM = 10, $ 
   			XTITLE = 'Particle Intensity', $
   			YTITLE = 'Density per Bin', $
   			pos = [0.07, 0.6, 0.35, 0.95], $
   			/normal, $
   			/noerase
   													;----------------------------------------------------------;
		threshold = ints_mean + 2.0*ints_sdev	    ; 	   CHOOSE THE THRESHOLD HERE (standard deviations)
		int_next = ints[t1_index+1]					;----------------------------------------------------------;

		pass = 1
		ints_next = ints[t1_index+1:t1_index+4]		; IF the next 4 points are above the threshold...
		foreach elem, ints_next do pass = [pass, elem gt threshold]

		if total(pass) eq 5 then begin ;if int_next gt threshold then begin
			junk = execute(plot_sep)
			plots, date[t1_index], ints[t1_index], /data, psym=6, symsize=1, color=4
			print, 'Onset time: ' + anytim(date[t1_index], /cc)
			onset = date[t1_index]
			BREAK
		endif	

		if ISA(onset_times) then begin
			gone_ahead = (time_sub[n_elements(time_sub)-1] - onset_times[n_elements(onset_times)-1])
			if gone_ahead gt 60.0*60.0 then BREAK
		endif	

	endfor

END

pro cusum_detection, date, ints, average_window, $
							tonset, onset_times = onset_times, plot_sep = plot_sep

	; Cumulative sum quality-control scheme.
	; Outlined in Huttunen-Heikinmaa et al. (2005)

	set_line_color
	minutes = average_window	; 7 hours of data

	junk = execute(plot_sep)
	tcenter = date[0]

	t0 = tcenter ;- minutes*60.0
	t1 = tcenter + minutes*60.0

	t0_index = closest(date, t0)
	t1_index = closest(date, t1)  <  (n_elements(ints)-5)

	ints_sub = ints[t0_index:t1_index]
	time_sub = date[t0_index:t1_index]

	plots, time_sub, ints_sub, /data, color=5

	mu_a = mean( ints_sub )
	sig_a = stdev( ints_sub ) ;> 0.05*mu_a 	
	mu_d = mu_a + 2.0*sig_a
	k = (mu_d - mu_a)/(alog(mu_d) - alog(mu_a))
	if k gt 1.0 then h=1.0
	if k le 1.0 then h=2.0

	if ~isa(h) then h=1.0

	pass=1
	for j=1, n_elements(ints)-5 do begin

		sum = 0.0	;total(ints[0:j])
		sum = max([0, ints[j+1] - k + sum])
		
		plots, date[j], [sum], /data, psym=1, symsize=1, color=7

		if sum ge h then begin
			pass = [pass, 1] 
		endif else begin
			pass = 1
		endelse	

		num_points = 30.0
		; If thirty out of control points are found then detection is positive
		if n_elements(pass) ge num_points and (where(pass ne 1))[0] eq -1 then begin
			plots, date[j-num_points], ints[j-num_points], /data, psym=2, symsize=3, color=6
			print, 'Onset time: ' + anytim(date[j-num_points], /cc)
			tonset = date[j-num_points]
			BREAK
		endif
	
	endfor	
	wait, 2.0

END

			;**********************************************************;
			;					MASTER CODE BELOW		               ;
			;**********************************************************;


pro velocity_disp_ace_epam_20140418, date_folder, erne = erne, epam_p = epam_p, epam_e = epam_e, $
						write_info = write_info, $
						sigma=sigma, cusum = cusum, manual = manual, mlinfit = mlinfit

; NOTE: Copy of velocity_dispersion.pro. Doing a quick hack to process ACE EPAM 5 second cadence data.

;+
;
; NAME:
;    VELOCITY_DISPERSION
;       
; PURPOSE:
;    Use velocity dispersion analysis of proton and electron data to 
;	 figure out particle release time. 
;
; CALLING SEQUENCE:
;    velocity_dispersion, date_folder
;
; INPUTS: 
;    date_folder: Folder date in the elevate catalogue.
;				  Format of 'YYYY-MM-DD'	
;
; KEYWORD PARAMETERS:
;	erne: Use SOHO ERNE proton data
;	epam_p: Use ACE EPAM proton data
;	epam_e: Use ACE EPAM electron data	   
;	counts: Use particle count values for the detection (available for ERNE only)
;	flux: Use particle flux
;
; OUTPUTS: 
;    saves 'info' structure at the end of the procedure
;
; OPTIONAL OUTPUT
;    NONE
;
;
; REVISION HISTORY:
;    2015-Jul-21, Eoin Carley.       
;                                      
;-                                       


	!p.charsize = 1.5
	event_folder = '/Users/eoincarley/ELEVATE/data/' +date_folder+ '/'
	ace_folder = event_folder + 'ACE/'
	soho_folder = event_folder + '/SOHO/ERNE/'

	yrange = '[1e-4, 1e4]'		; To be used in case that CUSUM method is chosen and particle counts are used.		 
	ace_e_energies = ['0.053', '0.079', '0.133', '0.232']	;MeV
		

	loadct, 39
	ace_folder = '/Users/eoincarley/ELEVATE/data/2014-04-18/ACE/'
	time0 = anytim('2014-04-18T12:00:00', /utim)
	time1 = anytim('2014-04-18T17:00:00', /utim)
	yyyymmdd = time2file(time0, /date)
	
	;setup_ps, '~/ace_epam' + yyyymmdd + '.eps'		

	;-----------------------------;
	;	  Reading ACE EPAM
	;
	; ACE EPAM data  Time P1 P2 P3 P4 P5 P6 P7 P8 E1p E2p E3p E4p FP5p FP6p FP7p 
	ace_file = file_search(ace_folder + 'ace_epam_12s*.txt')
	readcol, ace_file, yyyy, doy, format = 'F, F'
	good_inds = where(doy eq 108)
	readcol, ace_file, yyyy, doy, hh, mm, sec, E1p, E2p, E3p, E4p, format = 'F, F, F, F, F, F, F, F, F', $
		skipline = 68.0+good_inds[0], numline = n_elements(good_inds)

	for i=0, n_elements(doy)-1 do begin
		DOY2date, doy[i], yyyy[i], month, day
		ss = fix(sec[i])
		msec = (sec[i] - float(ss))*1000.0
		date_time_ex = fix( [hh[i], mm[i], ss, msec, day, month, yyyy[i]] )
		date_time = anytim(date_time_ex, /utim)
		if i eq 0 then date_times = date_time else date_times = [date_times, date_time]
	END		

	good_inds = where(E1p gt 0.0)
	date_times = date_times[good_inds]
	E1p = E1p[good_inds]
	E2p = E2p[good_inds]
	E3p = E3p[good_inds]
	E4p = E4p[good_inds]

	epam_data =  [ transpose([date_times]), transpose([E1p]), transpose([E2p]), transpose([E3p]), transpose([E4p]) ]
	index = where(epam_data[0, *] gt time0 and epam_data[0, *] lt time1)
	epam_data = epam_data[*, index]	
	epam_electrons = epam_data[1:4, *]


	if keyword_set(epam_e) then begin	
		
		if file_test(ace_folder+'params_for_vda.sav') then begin
			restore, ace_folder+'params_for_vda.sav', /verb
		endif else begin
			param_struct = {name:'ACE EPAM ELECTRONS', date:epam_data[0, 0], smooth_param:1, average_window:180}
			save, param_struct, filename=ace_folder+'params_for_vda.sav', description = 'Parameters used in the VDA of for this event'
		endelse	

		yrange = '[1e0, 1e7]'
		particle_data = epam_electrons
		particle_date = epam_data[0, *]
		chan_start = 0
		chan_end = 2
		chan_step = 1
		chan_name = 0	;for indexing erne_energies
		chan_energies = ace_e_energies
		instrument = 'ACE EPAM ELECTRONS'
		particle_type = 'electron'
		smooth_param = 10.0;param_struct.smooth_param ;5
		average_window = 40.;param_struct.average_window ;120.0
		detection_time_err = 2.0 	; minutes

		;param_struct = {name:instrument, date:particle_date[0], smooth_param:smooth_param, average_window:average_window}
		;save, param_struct, filename=ace_folder+'params_for_vda.sav', description = 'Paramaeters used in the VDA of for this event'

	endif	


	yyyymmdd = time2file(particle_date[0, 0])
	xtitle = strjoin(strsplit(anytim(particle_date[0,0], /cc, /trun), 'T', /extract, /regex), ' ') + ' UT'
	plot_sep = "utplot, date, ints, /noerase, /xs, /ys, yr = "+yrange+", /ylog, ytitle = 'Intensity (cm!U-2!N sr!U-1!N s!U-1!N MeV!U-1!N)', title = '"+instrument+"', xticklen = 1.0, xgridstyle = 1.0, yticklen = 1.0, ygridstyle = 1.0, position = [0.45, 0.1, 0.93, 0.95], /normal"


	for channel=chan_start, chan_end, chan_step do begin		; Loop through energy channels
		window, 0, xs=1200, ys=700
		good = where(particle_data[channel, *] gt 0.0)
		if good[0] ne -1 then begin
			ints = smooth(particle_data[channel, good], smooth_param, /edge_mirror)		; Smoothness is an important parameter
			date = particle_date[good]
			nels = n_elements(date)

			junk = execute(plot_sep)
	
			xyouts, date[nels-1] +60.0*2.0, ints[nels-1], chan_energies[chan_name] + ' MeV', /data

			;----------------------------------------------------------;
			;		     Choose detection method here 		  		   ;
			
			if keyword_set(sigma) then sigma_detection, date, ints, tonset, average_window, $
							onset_times = onset_times, plot_sep = plot_sep

			if keyword_set(cusum) then cusum_detection, date, ints, average_window, $
							tonset, onset_times = onset_times, plot_sep = plot_sep	
			
			if keyword_set(manual) then manual_detection, date, ints, average_window, $
							tonset, onset_times = onset_times, plot_sep = plot_sep

			if keyword_set(mlinfit) then manual_detection_linfit, date, ints, average_window, $
							tonset, onset_times = onset_times, plot_sep = plot_sep								

			;
			;----------------------------------------------------------;						

			if ISA(onset_times) eq 0 then begin
				onset_times = tonset
				energy = float(chan_energies[chan_name])
			endif

			time_diff = (onset_times[n_elements(onset_times)-1] - tonset)
			if ISA(onset_times) ne 0 then begin ;time_diff ne 0.0 then begin ;and time_diff lt 1.5*60.0*60.0 then begin
				onset_times = [onset_times, tonset]
				energy = [energy, float(chan_energies[chan_name])]
			endif	

		endif else begin
			print, 'No valid data in channel '+chan_energies[chan_name] + ' MeV'
		endelse	
		chan_name = chan_name + 1.0
	endfor	

	;----------------------------------------------------------;
	;		Calculate energy and particle release time 		   ;
	;----------------------------------------------------------;

	date_string = time2file(onset_times[n_elements(onset_times)-1], /date_only)
	day_start = anytim(file2time(date_string+'_000000'), /utim)
	day_fraction = (onset_times - day_start)/(24.0*60.0*60.0)

	case particle_type of
		'proton': p_mass = 1.67e-27 	;kg
		'electron': p_mass = 9.11e-31	;kg
	endcase	

	eV = energy*1e6
	kin_e = eV*1.602e-19	 	 ;J
	c = 2.99792458e8		 	 ;m/s
	rest_E = p_mass*(c^2.0)  	 ;J
	c_fraction = sqrt(1.0 - (rest_E/(kin_e + rest_E))^2.0)

	wset, 0
	plot, 1.0/[c_fraction], [day_fraction], $
		/xs, $
		/ys, $
		xr = [min(1.0/[c_fraction])-0.1, max(1.0/[c_fraction])+0.1], $
		yr = [min(day_fraction)-0.01, max(day_fraction)+0.01], $
		psym = 1, $
		symsize = 1.0, $
		pos = [0.07, 0.08, 0.35, 0.52], $
		xtitle = 'Inverse velocity (Beta!U-1!N)', $
		ytitle = 'Day fraction', $
		/noerase, $
		/normal

	yerr = day_fraction
	yerr[*] = detection_time_err/(24.0*60.0)					; number of mins error on in-situ detection time
	xerr = day_fraction
	xerr[*] = 0.0
	oploterror, 1.0/[c_fraction], [day_fraction], $
				xerr, yerr

	;----------------- Fitting --------------------;
	result = linfit(1.0/[c_fraction], [day_fraction], yfit = yfit)	

	start = [0.0087, result[0]]		;[slope, intercept] ;Start of with 1.5 AU 
	fit = 'p[0]*x + p[1]'

	par_lim = replicate({fixed:0, limited:[0,0], limits:[0.D,0.D]},2)

	par_lim(0).limited(0) = 1 		;Activate lower boundary
	par_lim(0).limits(0) = 0.00578	;Constrians travel dist to be greater than 1.0 AU

	par_lim(0).limited(1) = 1 		;Activate upper boundary
	par_lim(0).limits(1) = 0.0202	;Constrians travel dist to be less than 3.0 AU
	; Slope of the fit m = (8.33*60.0*s)/(nos) 	; where s is in astronomical units. and nos is number of seconds in a day.
	; Divide by nos because my fits are expressed in fractions of a day. So with 3.0 AU, m is 0.0174

	p = mpfitexpr(fit, 1.0/[c_fraction], [day_fraction], $
					yerr, $
					yfit=yfit, $
					start, $
					parinfo = par_lim, $
					perror = perror, $
					bestnorm = bestnorm, $
					dof=dof)

	oplot, 1.0/[c_fraction], yfit

	t_release = p[1]*(24.0*60.*60.0) + day_start
	t_release = anytim(t_release, /cc)

	em_detection = p[1]*(24.0*60.*60.0) + day_start + 8.33*60.0
	em_detection = anytim(em_detection, /cc)

	day_frac_lt = 8.33/(24.0*60.0) 	; Day fraction of light travel time
	travel_dist = p[0]/day_frac_lt
	dist_string = +string(travel_dist, format = '(f4.2)')

	perror = perror*SQRT(bestnorm / dof)	
	t0_error = perror[1]*(24.0*60.) ; Release time error in minutes
	s_error = perror[0]/day_frac_lt

	box_message, str2arr('Estimated ' +particle_type+ ' release time from:,'$
						+ t_release + ' UT (+/- '+string(t0_error, format='(f4.1)')+' min), ,' $
						+'Estimated EM start time:,' $
						+ em_detection + ' UT (+/- '+string(t0_error, format='(f4.1)')+' min), , Estimated '$
						+ particle_type+ ' travel distance:,'$
						+ dist_string + ' +/- '+ string(s_error, format='(f4.2)') + ' AU' )


	chisqr_prob = chisqr_pdf(bestnorm, dof)*100.0
	box_message, str2arr('Probability of better chi-square:,'+string(chisqr_prob, format = '(f5.2)' )+' %')


	;----------------------------------------------------------;
	;		 Write ASCII file containing event info	 		   ;
	;----------------------------------------------------------;
	sav_dir_name = event_folder + date_string+'_event_info_structure.sav'
	txt_dir_name = event_folder + date_string+'_event_info_structure.txt'
	csv_dir_name = event_folder + date_string+'_event_info_structure.csv'

	
	particle_tag = particle_type + '_vda_t0'
	if keyword_set(write_info) then event_info_to_text, event_folder, date_string, particle_tag, t_release+' UT'

	particle_tag = particle_type + '_vda_s'
	if keyword_set(write_info) then event_info_to_text, event_folder, date_string, particle_tag, dist_string+' AU'


STOP
	;-----------------------------------------;
	;			Plot VDA for paper.			  ;
	;										  ;  
	set_plot,'ps'
	!p.font=0
	!p.charsize=1.5
	!p.thick=3
	device, filename = '~/velocity_dispersion_20140418.eps', $
	      /color, $
	      /helvetica, $
	      /inches, $
	      xsize=4, $
	      ysize=4, $
	      /encapsulate, $
	      yoffset=5

	plot, 1.0/[c_fraction], [day_fraction], $
		/xs, $
		/ys, $
		xr = [min(1.0/[c_fraction])-0.1, max(1.0/[c_fraction])+0.1], $
		yr = [min(day_fraction)-0.005, max(day_fraction)+0.005], $
		psym = 1, $
		symsize = 1.0, $
		pos = [0.25, 0.25, 0.99, 0.99], $
		xtitle = 'Inverse velocity ('+cgGreek('beta')+'!U-1!N)', $
		ytitle = 'Day fraction', $
		/noerase, $
		/normal

	beta_sim = findgen(100)*(2.6 - 1.0)/99.0 + 1.0
	ysim= p[0]*beta_sim + p[1]	
	oplot, beta_sim, ysim, linestyle=1

	oploterror, 1.0/[c_fraction], [day_fraction], $
				xerr, yerr, psym=1

	device, /close	
	set_plot, 'x'


STOP
END