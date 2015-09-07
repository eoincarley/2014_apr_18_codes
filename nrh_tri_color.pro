pro stamp_date, i_a, i_b, i_c
   set_line_color
   !p.charsize = 2.5

   xyouts, 0.02, 0.07, 'NRH '+string(i_a.freq, format='(I03)') +' MHz '+anytim(i_a.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 0, charthick=1
   xyouts, 0.02, 0.07, 'NRH '+string(i_a.freq, format='(I03)') +' MHz '+anytim(i_a.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 3
   
   xyouts, 0.02, 0.045, 'NRH '+string(i_b.freq, format='(I03)') +' MHz '+anytim(i_b.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 0, charthick=1
   xyouts, 0.02, 0.045, 'NRH '+string(i_b.freq, format='(I03)') +' MHz '+anytim(i_b.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 10
   
   xyouts, 0.02, 0.02, 'NRH '+string(i_c.freq, format='(I03)') +' MHz '+anytim(i_c.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 0, charthick=1
   xyouts, 0.02, 0.02, 'NRH '+string(i_c.freq, format='(I03)') +' MHz '+anytim(i_c.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 4
END


pro nrh_tri_color, folder, freqs


	x_size = 7.*128
	y_size = 7.*128
	window, 0, xs = x_size, ys = y_size, retain=2

	t0 = anytim(file2time('20140418_124800'), /utim)
	;tend   = anytim(file2time('20140418_124000'),/utim)
	
	times = t0 + dindgen(20.0*60.0)
	t0str = anytim(times, /yoh, /trun, /time_only)



	cd, folder
	filenames = findfile('*.fts')


	for i=0, n_elements(t0str)-1 do begin
		read_nrh, filenames[freqs[0]], $
				nrh_hdr0, $
				nrh_data0, $
				hbeg=t0str[i];, $ 
				;hend=t1str

		read_nrh, filenames[freqs[1]], $
				nrh_hdr1, $
				nrh_data1, $
				hbeg=t0str[i]

		read_nrh, filenames[freqs[2]], $
				nrh_hdr2, $
				nrh_data2, $
				hbeg=t0str[i]

		max_value0 = max(nrh_data0)
		max_value1 = max(nrh_data1)
		max_value2 = max(nrh_data2)

		max_value = max([nrh_data0, nrh_data1, nrh_data2])

		nrh_data0 = nrh_data0 > max_value*0.5 < max_value*0.9
		nrh_data1 = nrh_data1 > max_value*0.5 < max_value*0.9
		nrh_data2 = nrh_data2 > max_value*0.5 < max_value*0.9 


	 	truecolorim = [[[nrh_data0]], [[nrh_data1]], [[nrh_data2]]]

		img = rebin(truecolorim, x_size, y_size, 3)
		!p.multi=[0,1,2]
	    expand_tv, img, x_size, y_size, 0, 0, true = 3, pos=[0,0,0,0]

		pixrad = (1.0d*x_size/nrh_hdr0.naxis1)*nrh_hdr0.solar_r
		xcen = (1.0d*x_size/nrh_hdr1.naxis1)*nrh_hdr1.crpix1
		ycen = (1.0d*x_size/nrh_hdr2.naxis2)*nrh_hdr2.crpix2
		tvcircle, pixrad, xcen, ycen, /device

		stamp_date, nrh_hdr0, nrh_hdr1, nrh_hdr2

		stop
		;x2png, folder + '/image_'+string(i, format='(I03)' )+'.png'

	endfor

	date = time2file(t0, /date_only)
	freq_string = string(nrh_hdr0.freq, format='(I03)') + '_'+ string(nrh_hdr1.freq, format='(I03)') + '_' +string(nrh_hdr2.freq, format='(I03)')
	;spawn, 'ffmpeg -y -r 25 -i image_%03d.png -vb 50M NRH_'+date+'_'+freq_string+'_v2.mpg'
	;spawn, 'rm *.png'

END