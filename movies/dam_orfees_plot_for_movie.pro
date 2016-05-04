pro plot_spec, data, time, freqs, frange, trange, scl0=scl0, scl1=scl1
	

	print, 'Processing: '+string(freqs[0], format=string('(I4)')) + $
			' to ' + $
			string(freqs[n_elements(freqs)-1], format=string('(I4)'))+ ' MHz'

	trange = anytim(file2time(trange), /utim)


	spectro_plot, data > (scl0) < (scl1), $
  				time, $
  				freqs, $
  				/xs, $
  				/ys, $
  				/ylog, $
  				ytitle='Frequency (MHz)', $
  				title = 'Orfees and DAM', $
  				yr=[ frange[0], frange[1] ], $
  				xrange = [ trange[0], trange[1] ], $
  				/noerase, $
  				position = [0.5, 0.14, 0.95, 0.86], $
  				xticklen = -0.012, $
  				yticklen = -0.015;, $
  				;xtickformat='(A1)', $
  				;xtitle = ' '
		
END


pro dam_orfees_plot_for_movie, orf_spec, orf_time, orf_freqs, dam_spec, dam_time, dam_freqs, time_marker=time_marker

	; Code to read and plot DAM and Orfees together

	; For use in the aia three colour and dynamic spectra movie for the 2014-April-18 paper

	!p.charsize=0.8
	freq0 = 10
	freq1 = 1000
	time0 = '20140418_122500'
	time1 = '20140418_132000'

	;***********************************;
	;			   PLOT
	;***********************************;	

	loadct, 74, /silent
	reverse_ct

	plot_spec, smooth(dam_spec, 5), dam_time, dam_freqs, [freq0, freq1], [time0, time1], scl0=-0.05, scl1=0.4
	plot_spec, orf_spec, orf_time, reverse(orf_freqs), [freq0, freq1], [time0, time1], scl0=-0.18, scl1=1.5

	if keyword_set(time_marker) then begin
		!p.thick=4
		set_line_color

		plots, [time_marker, time_marker], [1000.0, 10.0], color=1, thick=5
		plots, [time_marker, time_marker], [1000.0, 10.0], color=0, linestyle=2, thick=5

		freqs = [150, 173, 228, 270, 298, 327, 408, 432, 445]
		colors = [2,3,4,5,6,7,8,9,10]
		time_line0 = anytim(file2time(time0), /utim)
		time_line1 = anytim(file2time(time1), /utim)
		

		i=0
		plots, [time_line0, time_line1], [freqs[i], freqs[i]], color=colors[i], linestyle=2, /data, thick=4
		xyouts, [time_line1+25.], [freqs[i]], string(freqs[i], format='(I3)')+' MHz', /data, alignment=0, charsize=0.6, color=0
		xyouts, [time_line1+15.], [freqs[i]], string(freqs[i], format='(I3)')+' MHz', /data, alignment=0, charsize=0.6, color=0
		xyouts, [time_line1+20.], [freqs[i]], string(freqs[i], format='(I3)')+' MHz', /data, alignment=0, charsize=0.6, color=colors[i]

		for i=1, n_elements(freqs)-3 do begin
			plots, [time_line0, time_line1], [freqs[i], freqs[i]], color=colors[i], linestyle=2, /data, thick=4
			xyouts, [time_line1+20.], [freqs[i]], string(freqs[i], format='(I3)')+' MHz', /data, alignment=0, charsize=0.6, color=colors[i]
		endfor	

		plots, [time_line0, time_line1], [freqs[7], freqs[7]], color=colors[7], linestyle=2, /data, thick=4
		xyouts, [time_line1+20.], [freqs[7]+15.], string(freqs[i], format='(I3)')+' MHz', /data, alignment=0, charsize=0.6, color=colors[7]

		plots, [time_line0, time_line1], [freqs[8], freqs[8]], color=colors[8], linestyle=2, /data, thick=4
		xyouts, [time_line1+20.], [freqs[8]+40.], string(freqs[i], format='(I3)')+' MHz', /data, alignment=0, charsize=0.6, color=colors[8]

	endif	

			

END
