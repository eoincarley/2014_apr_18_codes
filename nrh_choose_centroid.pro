pro nrh_choose_centroid

	;Code to produce pngs of NRH observations of the 2014 April 18 event 
	;Produces pngs for all frequencies
	;Written 2014-Oct-2

	cd, '~/Data/2014_apr_18/radio/nrh'
	filenames = findfile('*.fts')

	window, 0, xs=700, ys=700, retain=2
	!p.charsize=1.5
	

	tstart = anytim(file2time('20140418_124830'), /utim)
	tstop = anytim(file2time('20140418_125310'), /utim) 
	i=0

	while tstart lt tstop do begin

		t0str = anytim(tstart, /yoh, /trun, /time_only)

		read_nrh, filenames[7], $
				  nrh_hdr, $
				  nrh_data, $
				  hbeg=t0str;, $ 
				  ;hend=t1str
				
		index2map, nrh_hdr, nrh_data, $
				   nrh_map  
				
		nrh_str_hdr = nrh_hdr
		nrh_times = nrh_hdr.date_obs
				
		;------------------------------------;
		;			Plot Total I
		freq = nrh_hdr.FREQ
		loadct, 3, /silent
		FOV = [10, 10]
		CENTER = [700, -100]
		plot_map, nrh_map, $
			fov = FOV, $
			center = CENTER, $
			dmin = 1e3, $
			dmax = 3e8, $
			title='NRH '+string(nrh_hdr.freq, format='(I03)')+' MHz '+ $
			string( anytim( nrh_times, /yoh, /trun) )+' UT'
			  
					
		set_line_color
		plot_helio, nrh_times, $
					/over, $
					gstyle=1, $
					gthick=1.0, $
					gcolor=1, $
					grid_spacing=15.0

		max_val = max( (nrh_data) ,/nan) 									   
		nlevels=5.0   
		top_percent = 0.50
		levels = (dindgen(nlevels)*(max_val - max_val*top_percent)/(nlevels-1.0)) $
				+ max_val*top_percent  

		set_line_color
		plot_map, nrh_map, $
			/overlay, $
			/cont, $
			levels=levels, $
			/noxticks, $
			/noyticks, $
			/noaxes, $
			thick=1, $
			color=5		

		;-------------------------------;
		;	   Choose data points	    ;
		;								;
		cursor, x, y, /data
		if i eq 0 then begin
			xarcs = x
			yarcs = y
			times = nrh_times
		endif else begin
			xarcs = [xarcs, x]
			yarcs = [yarcs, y]
			times = [times, nrh_times]
		endelse	
					
		tstart = tstart + 10.0
		i=i+1
	endwhile				

	;window, 1
	plots, xarcs, yarcs

	window, 1
	arc_displ = fltarr(n_elements(xarcs)-1)

	for i=0, n_elements(xarcs)-2 do begin
		x1 = xarcs[i]
		x2 = xarcs[i+1]
		y1 = yarcs[i]
		y2 = yarcs[i+1]
		arc_displ[i] = sqrt( (x2 - x1)^2. + (y2 - y1)^2.)
	endfor	

	displ = tan((arc_displ/3600.)*!dtor)*149e6*1e3
	for i=0, n_elements(displ)-1 do displ[i] = total(arc_displ[0:i]) 

	times = anytim(times[1:n_elements(times)-1], /utim)
	times_sec = times - times[0]


	plot, times_sec, displ;, /ylog
			
	stop		
			
END