pro dam_plot

	loadct, 0
	reverse_ct
	window, xs=1000, ys=800, retain=2
	!p.multi=[0, 1, 2]
	!p.charsize=1.5

	restore, '~/Data/2014_Apr_18/radio/dam/NDA_20140418_1251_left.sav', /verb
	spectro_l = constbacksub(spectro_l, /auto)
	spectro_plot, spectro_l > (-10) < (70), tim_l, freq, $
				/xs, $
				/ys, $
				ytitle = 'Frequency (MHz)', $
				xrange = '2014-Apr-18 '+['12:51:00','13:16:00'], $
				title='LHCP'
				
				
				
	restore, '~/Data/2014_Apr_18/radio/dam/NDA_20140418_1251_right.sav', /verb
	spectro_r = constbacksub(spectro_r, /auto)
	spectro_plot, spectro_r > (-10) < (70), tim_r, freq, $
				/xs, $
				/ys, $
				ytitle = 'Frequency (MHz)', $
				xrange = '2014-Apr-18 '+['12:51:00','13:16:00'], $
				title='RHCP'	
	
	x2png, 'nancay_dam_20140418.png'

END