#!/usr/bin/env bash

# Purpose: Perform entire workflow to generate intersection masks from raw RACMO, ELM data
# Workflow invokes NCO and three subsidiary scripts, racmw_raw2std.sh, msk_mk.nco, and msk_nsx.nco

# Usage:
# ~/icemask/icemask.sh 
# ~/icemask/icemask.sh > ~/foo.txt 2>&1 &

# Synchronize generated ice-sheet mask files to local grid directory
# cd ${DATA}/grids;rsync 'zender@imua.ess.uci.edu:data/grids/msk_?is_r??.nc' .;ls -l msk_?is_r??.nc

# Part 1: Convert raw RACMO gridfiles to standardized gridfiles and derive SCRIP grids
# This part is slow and only needs be done when new grids are introduced so usually skip it
if false; then
    ~/icemask/racmo_raw2std.sh 
fi # !false
    
# Part 2: Compute mapfiles from derived grids
# This part is slow and only needs be done once so usually skip it
if false; then
    ncremap -a traave -s ${DATA}/grids/racmo_gis_566x438.nc -g ${DATA}/grids/r05_360x720.nc --map=${DATA}/maps/map_racmo_gis_566x438_to_r05_traave.20240801.nc
    ncremap -a traave -s ${DATA}/grids/racmo_ais_591x726.nc -g ${DATA}/grids/r05_360x720.nc --map=${DATA}/maps/map_racmo_ais_591x726_to_r05_traave.20240801.nc
    ncremap -a traave -s ${DATA}/grids/racmo_gis_566x438.nc -g ${DATA}/grids/r0125_1440x2880.20210401.nc --map=${DATA}/maps/map_racmo_gis_566x438_to_r0125_traave.20240801.nc
    ncremap -a traave -s ${DATA}/grids/racmo_ais_591x726.nc -g ${DATA}/grids/r0125_1440x2880.20210401.nc --map=${DATA}/maps/map_racmo_ais_591x726_to_r0125_traave.20240801.nc
    # ELM->RACMO maps: TR algorithms must use --a2o option and switch grid orders
    ncremap --a2o -a traave -s ${DATA}/grids/r05_360x720.nc -g ${DATA}/grids/racmo_gis_566x438.nc --map=${DATA}/maps/map_r05_to_racmo_gis_566x438_traave.20240801.nc
    ncremap --a2o -a traave -s ${DATA}/grids/r05_360x720.nc -g ${DATA}/grids/racmo_ais_591x726.nc --map=${DATA}/maps/map_r05_to_racmo_ais_591x726_traave.20240801.nc
    ncremap --a2o -a traave -s ${DATA}/grids/r0125_1440x2880.20210401.nc.nc -g ${DATA}/grids/racmo_gis_566x438.nc --map=${DATA}/maps/map_r0125_to_racmo_gis_566x438_traave.20240801.nc
    ncremap --a2o -a traave -s ${DATA}/grids/r0125_1440x2880.20210401.nc.nc -g ${DATA}/grids/racmo_ais_591x726.nc --map=${DATA}/maps/map_r0125_to_racmo_ais_591x726_traave.20240801.nc
fi # !false

# Part 3: Derive, trim, and regrid masks for each ice sheet and each grid
# AIS RACMO:
ncap2 -O --script="*flg_ais=1;*flg_rcm=1;" -S ~/icemask/msk_mk.nco ${HOME}/msk_ais_rcm24.nc ${HOME}/msk_ais_rcm.nc
ncremap --sgs_frc=Icemask_rcm --map=${DATA}/maps/map_racmo_ais_591x726_to_r05_traave.20240801.nc ${HOME}/msk_ais_rcm.nc ${HOME}/msk_ais_rcm_r05.nc
ncremap --sgs_frc=Icemask_rcm --map=${DATA}/maps/map_racmo_ais_591x726_to_r0125_traave.20240801.nc ${HOME}/msk_ais_rcm.nc ${HOME}/msk_ais_rcm_r0125.nc

# GrIS RACMO:
ncap2 -O --script="*flg_gis=1;*flg_rcm=1;" -S ~/icemask/msk_mk.nco ${HOME}/msk_gis_rcm24.nc ${HOME}/msk_gis_rcm.nc
ncks -A -C -v Icemask_rcm23 ${HOME}/msk_gis_rcm23.nc ${HOME}/msk_gis_rcm.nc # Append RACMO 2.3 ice mask for completeness
ncremap --sgs_frc=Icemask_rcm --map=${DATA}/maps/map_racmo_gis_566x438_to_r05_traave.20240801.nc ${HOME}/msk_gis_rcm.nc ${HOME}/msk_gis_rcm_r05.nc
ncremap --sgs_frc=Icemask_rcm --map=${DATA}/maps/map_racmo_gis_566x438_to_r0125_traave.20240801.nc ${HOME}/msk_gis_rcm.nc ${HOME}/msk_gis_rcm_r0125.nc

# AIS ELM r05
ncap2 -O --script="*flg_ais=1;*flg_elm=1;" -S ~/icemask/msk_mk.nco ${HOME}/QICE_1998-2020_climo.nc ${HOME}/msk_ais_elm_r05.nc
ncks -O -6 -C -x -v time,time_bounds ${HOME}/msk_ais_elm_r05.nc ${HOME}/msk_ais_elm_r05.nc
ncatted -O -a _FillValue,'[lat]|[lon]',d,, -a missing_value,'[lat]|[lon]',d,, ${HOME}/msk_ais_elm_r05.nc ${HOME}/msk_ais_elm_r05.nc
ncremap --sgs_frc=Icemask_qice --map=${DATA}/maps/map_r05_to_racmo_ais_591x726_traave.20240801.nc ${HOME}/msk_ais_elm_r05.nc ${HOME}/msk_ais_elm_r05_rcm.nc

# AIS ELM r0125
ncap2 -O --script="*flg_ais=1;*flg_elm=1;" -S ~/icemask/msk_mk.nco ${HOME}/QICE_1998-2020_climo.nc ${HOME}/msk_ais_elm_r0125.nc
ncks -O -6 -C -x -v time,time_bounds ${HOME}/msk_ais_elm_r0125.nc ${HOME}/msk_ais_elm_r0125.nc
ncatted -O -a _FillValue,'[lat]|[lon]',d,, -a missing_value,'[lat]|[lon]',d,, ${HOME}/msk_ais_elm_r0125.nc ${HOME}/msk_ais_elm_r0125.nc
ncremap --sgs_frc=Icemask_qice --map=${DATA}/maps/map_r0125_to_racmo_ais_591x726_traave.20240801.nc ${HOME}/msk_ais_elm_r0125.nc ${HOME}/msk_ais_elm_r0125_rcm.nc

# GrIS ELM r05
ncap2 -O --script="*flg_gis=1;*flg_elm=1;" -S ~/icemask/msk_mk.nco ${HOME}/QICE_1998-2020_climo.nc ${HOME}/msk_gis_elm_r05.nc
ncks -O -6 -C -x -v time,time_bounds ${HOME}/msk_gis_elm_r05.nc ${HOME}/msk_gis_elm_r05.nc
ncatted -O -a _FillValue,'[lat]|[lon]',d,, -a missing_value,'[lat]|[lon]',d,, ${HOME}/msk_gis_elm_r05.nc ${HOME}/msk_gis_elm_r05.nc
ncremap --sgs_frc=Icemask_qice --map=${DATA}/maps/map_r05_to_racmo_gis_566x438_traave.20240801.nc ${HOME}/msk_gis_elm_r05.nc ${HOME}/msk_gis_elm_r05_rcm.nc

# GrIS ELM r0125
ncap2 -O --script="*flg_gis=1;*flg_elm=1;" -S ~/icemask/msk_mk.nco ${HOME}/QICE_1998-2020_climo.nc ${HOME}/msk_gis_elm_r0125.nc
ncks -O -6 -C -x -v time,time_bounds ${HOME}/msk_gis_elm_r0125.nc ${HOME}/msk_gis_elm_r0125.nc
ncatted -O -a _FillValue,'[lat]|[lon]',d,, -a missing_value,'[lat]|[lon]',d,, ${HOME}/msk_gis_elm_r0125.nc ${HOME}/msk_gis_elm_r0125.nc
ncremap --sgs_frc=Icemask_qice --map=${DATA}/maps/map_r0125_to_racmo_gis_566x438_traave.20240801.nc ${HOME}/msk_gis_elm_r0125.nc ${HOME}/msk_gis_elm_r0125_rcm.nc

# Once ALL trimmed mask files exist, append ELM masks to RACMO mask files to enable computation of intersection masks
ncks -A -C -v QICE,Icemask_qice ${HOME}/msk_ais_elm_r05.nc ${HOME}/msk_ais_rcm_r05.nc
ncks -A -C -v QICE,Icemask_qice ${HOME}/msk_gis_elm_r05.nc ${HOME}/msk_gis_rcm_r05.nc
ncks -A -C -v QICE,Icemask_qice ${HOME}/msk_ais_elm_r0125.nc ${HOME}/msk_ais_rcm_r0125.nc
ncks -A -C -v QICE,Icemask_qice ${HOME}/msk_gis_elm_r0125.nc ${HOME}/msk_gis_rcm_r0125.nc

# grd_trg determines which ELM resolution provides the generic Icemask_qice mask used in intersection map calculation
if [ ${grd_trg} = 'r05' ]; then
    ncks -A -C -v QICE,Icemask_qice ${HOME}/msk_ais_elm_r05_rcm.nc ${HOME}/msk_ais_rcm.nc
    ncks -A -C -v QICE,Icemask_qice ${HOME}/msk_gis_elm_r05_rcm.nc ${HOME}/msk_gis_rcm.nc
elif [ ${grd_trg} = 'r0125' ]; then
    ncks -A -C -v QICE,Icemask_qice ${HOME}/msk_ais_elm_r0125_rcm.nc ${HOME}/msk_ais_rcm.nc
    ncks -A -C -v QICE,Icemask_qice ${HOME}/msk_gis_elm_r0125_rcm.nc ${HOME}/msk_gis_rcm.nc
fi # !false

# Unless renamed, r05 and r0125 masks would overwrite eachother in RACMO mask files
ncrename -v Icemask_qice,Icemask_qice_r05 ${HOME}/msk_ais_elm_r05_rcm.nc ${HOME}/msk_ais_elm_r05_rcm.nc
ncrename -v Icemask_qice,Icemask_qice_r05 ${HOME}/msk_gis_elm_r05_rcm.nc ${HOME}/msk_gis_elm_r05_rcm.nc
ncrename -v Icemask_qice,Icemask_qice_r0125 ${HOME}/msk_ais_elm_r0125_rcm.nc ${HOME}/msk_ais_elm_r0125_rcm.nc
ncrename -v Icemask_qice,Icemask_qice_r0125 ${HOME}/msk_gis_elm_r0125_rcm.nc ${HOME}/msk_gis_elm_r0125_rcm.nc

# Append ELM masks with grid-specific names to RACMO mask files
ncks -A -C -v Icemask_qice_r05 ${HOME}/msk_ais_elm_r05_rcm.nc ${HOME}/msk_ais_rcm.nc
ncks -A -C -v Icemask_qice_r05 ${HOME}/msk_gis_elm_r05_rcm.nc ${HOME}/msk_gis_rcm.nc
ncks -A -C -v Icemask_qice_r0125 ${HOME}/msk_ais_elm_r0125_rcm.nc ${HOME}/msk_ais_rcm.nc
ncks -A -C -v Icemask_qice_r0125 ${HOME}/msk_gis_elm_r0125_rcm.nc ${HOME}/msk_gis_rcm.nc

# Compute intersection and difference masks
ncap2 -O -S ~/icemask/msk_nsx.nco ${HOME}/msk_ais_rcm.nc ${HOME}/msk_ais_rcm.nc # AIS intersection masks on RACMO grid
ncap2 -O -S ~/icemask/msk_nsx.nco ${HOME}/msk_gis_rcm.nc ${HOME}/msk_gis_rcm.nc # GrIS intersection masks on RACMO grid
ncap2 -O -S ~/icemask/msk_nsx.nco ${HOME}/msk_ais_rcm_r05.nc ${HOME}/msk_ais_r05.nc # AIS intersection masks on ELM r05 grid
ncap2 -O -S ~/icemask/msk_nsx.nco ${HOME}/msk_gis_rcm_r05.nc ${HOME}/msk_gis_r05.nc # GrIS intersection masks on ELM r05 grid
ncap2 -O -S ~/icemask/msk_nsx.nco ${HOME}/msk_ais_rcm_r0125.nc ${HOME}/msk_ais_r0125.nc # AIS intersection masks on ELM r0125 grid
ncap2 -O -S ~/icemask/msk_nsx.nco ${HOME}/msk_gis_rcm_r0125.nc ${HOME}/msk_gis_r0125.nc # GrIS intersection masks on ELM r0125 grid

# Move data from working directory (${HOME}) to grid directory in ${DATA} to prevent confusion
/bin/mv ${HOME}/msk_ais_rcm.nc ${DATA}/grids
/bin/mv ${HOME}/msk_gis_rcm.nc ${DATA}/grids
/bin/mv ${HOME}/msk_ais_r05.nc ${DATA}/grids
/bin/mv ${HOME}/msk_gis_r05.nc ${DATA}/grids
/bin/mv ${HOME}/msk_ais_r0125.nc ${DATA}/grids
/bin/mv ${HOME}/msk_gis_r0125.nc ${DATA}/grids


