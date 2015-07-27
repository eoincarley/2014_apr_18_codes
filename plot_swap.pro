pro plot_swap

  cd,'~/Data/2014_apr_18/swap'
  files = findfile('*.fits')
  window, 0, xs=1300, ys=1300
  loadct, 3
  FOV = [24.0, 24.0]
  CENTER = [900.0, -250.0]
  
  FOR i=1, n_elements(files)-1 DO BEGIN
    
    data_pre = lasco_readfits(files[i-1], hdr)
    index2map, hdr, $
        data_pre, $
        map_swap_pre
    
    data = lasco_readfits(files[i], hdr)
    index2map, hdr, $
        data, $
        map_swap
    
    ;map_swap_pre.data = disk_nrgf(map_swap_pre.data, hdr, 0, 0)		
    ;map_swap.data = disk_nrgf(map_swap.data, hdr, 0, 0)		
    ;map_swap.data = (map_swap.data - mean(map_swap.data))/stdev(map_swap.data)
    
  
  
    plot_map, diff_map(map_swap, map_swap_pre), $
        dmin = -10, $
        dmax = 10, $
        fov = FOV, $
        center = CENTER
  
    plot_helio, hdr.date_obs, $
        /over, $
        gstyle=1, $
        gthick=1.0, $	
        gcolor=255, $
        grid_spacing=15.0
        
        
	ENDFOR		

  stop
END