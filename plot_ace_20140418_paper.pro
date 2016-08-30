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

pro plot_ace_20140418_paper

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
	ace_file = file_search(ace_folder + 'ace_ep_*.sav')
	restore, ace_file, /verb
	epam_data = date_ep

	index = where(epam_data[0, *] gt time0 and epam_data[0, *] lt time1)
	
	epam_data = epam_data[*, index]
	
	epam_electrons = epam_data[9:11, *]


	utplot, epam_data[0, *], smooth(epam_electrons[0, *], 3), $
			/xs, $
			yr = [10, 1e5], $
			/ylog, $
			ytitle = 'Particle Intensity (cm!U-2!N sr!U-1!N s!U-1!N MeV!U-1!N)', $
			position = [0.15, 0.15, 0.9, 0.9], $
			xticklen = 1.0, $
			xgridstyle = 1.0, $
			yticklen = 1.0, $
			ygridstyle = 1.0, $
			/normal, $
			thick=5;, $
			;/noerase

	for i=1, 2  do begin
		outplot, epam_data[0, *], smooth(epam_electrons[i, *], 3), $
				color = i*70.0, linestyle=i+1, thick=7
	endfor	

	device, /close
	set_plot, 'x'	
    

END