#!/usr/bin/env bash

# Purpose: Convert raw RACMO gridfiles to standardized gridfiles and derive SCRIP grids

# Usage:
# ~/icemask/racmo_raw2std.sh 
# ~/icemask/racmo_raw2std.sh > ~/foo.txt 2>&1 &

# Taken from procedure devised on 20210409 (see crr.txt) for RACMO 2.3p2 Bryce Noel data:
# Basic procedure is to convert 2.4 gridfile to netCDF3 (prior to renaming), eliminate fake coordinates

for ish_nm in ais gis; do

    if [ ${ish_nm} = 'ais' ]; then
	rcm_xpt='PXANT11'
	rcm_km='11'
	rcm_rsn='591x726'
    fi # !ish_nm
    if [ ${ish_nm} = 'gis' ]; then
	rcm_xpt='FGRN055'
	rcm_km='5.5'
	rcm_rsn='566x438'
    fi # !ish_nm
	
    # Process 2.4 gridfiles first...same procedure for AIS and GrIS files
    # Same as /global/cfs/cdirs/fanssie/racmo/raw/RACMO2.4/${rcm_xpt}/${rcm_xpt}_masks.nc
    ncks -O -C -x -v rlat,rlon -6 ${DATA}/racmo/raw/${rcm_xpt}_masks.nc ~/msk_${ish_nm}_rcm24.nc
    # Make lon,lat coordinates, change missing_value to _FillValue
    ncrename -O  -a .missing_value,_FillValue -d .rlon,lon -d .rlat,lat ~/msk_${ish_nm}_rcm24.nc
    # Standardize units, _FillValue is NaN though only used by Basins which we will remove next
    ncatted -O -a units,IceMask,o,c,fraction -a units,LSM,o,c,binary_mask -a units,lat,o,c,degrees_north -a units,lon,o,c,degrees_east -a _FillValue,,d,, ~/msk_${ish_nm}_rcm24.nc
    # Remove Basins completely out of abundance of caution
    ncks -O -x -v Basins ~/msk_${ish_nm}_rcm24.nc ~/msk_${ish_nm}_rcm24.nc
    # Copy original 2.4 mask and area variables into Icemask_rcm24, Icemask, and area for back-compatibility
    ncap2 -O -s 'Icemask_rcm24=Icemask=IceMask;area=area_non_crd=Area' ~/msk_${ish_nm}_rcm24.nc ~/msk_${ish_nm}_rcm24.nc # NB: RACMO GrIS 2.3 uses Icemask_GR, RACMO 2.4 AIS+GrIS use IceMask

    # We also have RACMO 2.3 data for GrIS, though it requires a separate procedure
    if [ ${ish_nm} = 'gis' ]; then

	# Convert 2.3 gridfile to netCDF3 (prior to renaming), eliminate fake coordinates
	ncks -O -C -x -v rlat,rlon -6 ${DATA}/racmo/raw/${rcm_xpt}_Masks_${rcm_km}km.nc ~/msk_${ish_nm}_rcm23.nc
	# Make lon,lat coordinates, change missing_value to _FillValue
	ncrename -O  -a .missing_value,_FillValue -d .rlon,lon -d .rlat,lat ~/msk_${ish_nm}_rcm23.nc
	# Standardize units, _FillValue is -1.0e30 though is not used so remove it completely
	ncatted -O -a units,Icemask_GR,o,c,fraction -a units,LSM_GR,o,c,binary_mask -a units,Promicemask,o,c,enum -a units,lat,o,c,degrees_north -a units,lon,o,c,degrees_east -a _FillValue,,d,, ~/msk_${ish_nm}_rcm23.nc
	# Copy original 2.3 mask and area variables into Icemask and area for back-compatibility
	ncap2 -O -s 'Icemask_rcm23=Icemask=Icemask_GR;area=area_non_crd=Area' ~/msk_${ish_nm}_rcm23.nc ~/msk_${ish_nm}_rcm23.nc # NB: RACMO GrIS 2.3 uses Icemask_GR, RACMO 2.4 AIS+GrIS use IceMask
	
    fi # !ish_nm

    # Infer SCRIP grid-file (NB: RACMO 2.3 and 2.4 _grids_ are identical, though their ice masks differ)
    ncremap --area_dgn -d ~/msk_${ish_nm}_rcm24.nc -g ${DATA}/grids/racmo_${ish_nm}_${rcm_rsn}.nc

done # !ish_nm

