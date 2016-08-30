pro setup_ps, name
  
  set_plot,'ps'
  !p.font=0
  !p.charsize=1.5
  !p.thick=5
  device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=6, $
          ysize=6, $
          /encapsulate, $
          yoffset=5

end

pro plot_ace_20140418_paper_v2

	; v2 now looks at 5 second cadence data.

	loadct, 39
	ace_folder = '/Users/eoincarley/ELEVATE/data/2014-04-18/ACE/'
	time0 = anytim('2014-04-18T12:00:00', /utim)
	time1 = anytim('2014-04-18T17:00:00', /utim)
	yyyymmdd = time2file(time0, /date)
	
	setup_ps, '~/ace_epam' + yyyymmdd + '.eps'		

	;-----------------------------;
	;	  Reading ACE EPAM
	;
	; ACE EPAM data  Time P1 P2 P3 P4 P5 P6 P7 P8 E1p E2p E3p E4p FP5p FP6p FP7p 
	ace_file = file_search(ace_folder + 'ace_epam_5s*.txt')
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
	epam_electrons = epam_data[1:3, *]

	smoothing = 10
	utplot, epam_data[0, *], smooth(epam_electrons[0, *], smoothing), $
			/xs, $
			yr = [10, 1e5], $
			/ylog, $
			ytitle = 'Particle Intensity (cm!U-2!N sr!U-1!N s!U-1!N MeV!U-1!N)', $
			position = [0.15, 0.15, 0.9, 0.9], $
			xticklen = 1.0, $
			xgridstyle = 1.0, $
			yticklen = 1.0, $
			ygridstyle = 1.0, $
			/normal;, $
			;thick=5;, $
			;/noerase

	for i=1, 2  do begin
		outplot, epam_data[0, *], smooth(epam_electrons[i, *], smoothing), $
				color = i*70.0, linestyle=0;, thick=7
	endfor	

	device, /close
	set_plot, 'x'	
    

END