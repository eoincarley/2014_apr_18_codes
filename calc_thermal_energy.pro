pro calc_thermal_energy

	; Based on the rate of change of density of the overlying structure 
	; fromt the 2014-04-18 event, we can calculate the work done due to thermal expansion

	xi = 1.0  	;ionization ratio
	T = 1e6		; Kelvin
	kB = 1.38e-23	;J K^-1
	dndt = 2e6*1e6	; m^-3 s^-1
	dPdt = 2.0*xi*kB*T*dndt
	time = 5.0*60.0
	P = dPdt*time

	; Calculate distance travelled in burst liftime
	speed = 500e3 	; m/s
	displ = speed*time
	; Estimate volume change from self similar expansion
	dV = displ^3.0	; m^3

	W = P*dV 	; Joules
	W = W*1e7	; ergs
	print, 'Work done due to thermal expansion: ' + string(W) + ' (ergs)'


END