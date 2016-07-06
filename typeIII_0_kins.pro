pro typeIII_0_kins

	; This code reads and prints the results of getting ft point with ft_to_speed.pro
	; and then analysing speeds with various model folds using radio_kins.

	c = 2.997e8		; m/s
	folder = '~/Data/2014_apr_18/radio/kinematics/type_IIIs/'
	restore, folder + 'typeIII_0_burst_model_speeds.sav'

	speeds = [ burst_speeds.SAITO_FOLD_SPEED[1], $
				burst_speeds.NEWKIRK_FOLD_SPEED[1], $
				burst_speeds.BAUM_FOLD_SPEED[1], $
				burst_speeds.LEBLANC_FOLD_SPEED[1], $
				burst_speeds.MANN_FOLD_SPEED[1], $
				burst_speeds.ST_HILAIRE_0_FOLD_SPEED[1] ]

	models = ['mann', 'saito', 'newkirk', 'baum', 'leblanc', 'st_hilaire_0'] 

	speeds = speeds*1e3		; m/s	  
	speeds_c = speeds/c
	for i=0, n_elements(speeds_c)-1 do begin
		speed_c = speeds_c[i]	
		energy = rel_energy(speed_c)
		print, '-------------------------------------'		
		print, 'Model: '+models[i]
		print, 'Speed: '+string(speed_c)+' c'
		print, 'Speed: '+string(speed_c*c/1000.0)+' km/s'
		print, 'Energy: '+string(energy[0])+' (keV)'
		print, '-------------------------------------'

	endfor	

	STOP
END