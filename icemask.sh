#!/usr/bin/env bash

# Purpose: Perform entire workflow to generate intersection masks from raw RACMO, ELM data
# Workflow invokes NCO and three subsidiary scripts, racmw_raw2std.sh, msk_mk.nco, and msk_nsx.nco

# Usage:
# ~/icemask/icemask.sh 
# ~/icemask/icemask.sh > ~/foo.txt 2>&1 &

# Convert raw RACMO gridfiles to standardized gridfiles and derive SCRIP grids
if false; then
    ~/icemask/racmo_raw2std.sh 
fi # !false
    
# Compute mapfiles from derived grids
if false; then
    ncremap -a traave -s ${DATA}/grids/racmo_gis_566x438.nc -g ${DATA}/grids/r05_360x720.nc --map=${DATA}/maps/map_racmo_gis_566x438_to_r05_traave.20240801.nc
    ncremap -a traave -s ${DATA}/grids/racmo_ais_591x726.nc -g ${DATA}/grids/r05_360x720.nc --map=${DATA}/maps/map_racmo_ais_591x726_to_r05_traave.20240801.nc
    # r05->RACMO maps: TR algorithms must use --a2o option and switch grid orders
    ncremap --a2o -a traave -s ${DATA}/grids/r05_360x720.nc -g ${DATA}/grids/racmo_gis_566x438.nc --map=${DATA}/maps/map_r05_to_racmo_gis_566x438_traave.20240801.nc
    ncremap --a2o -a traave -s ${DATA}/grids/r05_360x720.nc -g ${DATA}/grids/racmo_ais_591x726.nc --map=${DATA}/maps/map_r05_to_racmo_ais_591x726_traave.20240801.nc
fi # !false

# AIS RACMO:
ncap2 -O --script="*flg_ais=1;*flg_rcm=1;" -S ~/icemask/msk_mk.nco ${HOME}/msk_ais_rcm24.nc ${HOME}/msk_ais_rcm.nc
ncremap --sgs_frc=Icemask_rcm --map=${DATA}/maps/map_racmo_ais_591x726_to_r05_traave.20240801.nc ${HOME}/msk_ais_rcm.nc ${HOME}/msk_ais_rcm_r05.nc

# GrIS RACMO:
ncap2 -O --script="*flg_gis=1;*flg_rcm=1;" -S ~/icemask/msk_mk.nco ${HOME}/msk_gis_rcm24.nc ${HOME}/msk_gis_rcm.nc
ncks -A -C -v Icemask_rcm23 ${HOME}/msk_gis_rcm23.nc ${HOME}/msk_gis_rcm.nc # Append RACMO 2.3 ice mask for completeness
ncremap --sgs_frc=Icemask_rcm --map=${DATA}/maps/map_racmo_gis_566x438_to_r05_traave.20240801.nc ${HOME}/msk_gis_rcm.nc ${HOME}/msk_gis_rcm_r05.nc

# AIS ELM
ncap2 -O --script="*flg_ais=1;*flg_elm=1;" -S ~/icemask/msk_mk.nco ${HOME}/QICE_1998-2020_climo.nc ${HOME}/msk_ais_elm.nc
ncks -O -6 -C -x -v time,time_bounds ${HOME}/msk_ais_elm.nc ${HOME}/msk_ais_elm.nc
ncatted -O -a _FillValue,'[lat]|[lon]',d,, -a missing_value,'[lat]|[lon]',d,, ${HOME}/msk_ais_elm.nc ${HOME}/msk_ais_elm.nc
ncremap --sgs_frc=Icemask_qice --map=${DATA}/maps/map_r05_to_racmo_ais_591x726_traave.20240801.nc ${HOME}/msk_ais_elm.nc ${HOME}/msk_ais_elm_rcm.nc

# GrIS ELM
ncap2 -O --script="*flg_gis=1;*flg_elm=1;" -S ~/icemask/msk_mk.nco ${HOME}/QICE_1998-2020_climo.nc ${HOME}/msk_gis_elm.nc
ncks -O -6 -C -x -v time,time_bounds ${HOME}/msk_gis_elm.nc ${HOME}/msk_gis_elm.nc
ncatted -O -a _FillValue,'[lat]|[lon]',d,, -a missing_value,'[lat]|[lon]',d,, ${HOME}/msk_gis_elm.nc ${HOME}/msk_gis_elm.nc
ncremap --sgs_frc=Icemask_qice --map=${DATA}/maps/map_r05_to_racmo_gis_566x438_traave.20240801.nc ${HOME}/msk_gis_elm.nc ${HOME}/msk_gis_elm_rcm.nc

# Once all trimmed mask files exist, append the ELM masks to the RACMO mask files so intersection masks can be computed
ncks -A -C -v QICE,Icemask_qice ${HOME}/msk_ais_elm.nc ${HOME}/msk_ais_rcm_r05.nc
ncks -A -C -v QICE,Icemask_qice ${HOME}/msk_gis_elm.nc ${HOME}/msk_gis_rcm_r05.nc
ncks -A -C -v QICE,Icemask_qice ${HOME}/msk_ais_elm_rcm.nc ${HOME}/msk_ais_rcm.nc
ncks -A -C -v QICE,Icemask_qice ${HOME}/msk_gis_elm_rcm.nc ${HOME}/msk_gis_rcm.nc

# Compute intersection and difference masks
ncap2 -O -S ~/icemask/msk_nsx.nco ${HOME}/msk_ais_rcm_r05.nc ${HOME}/msk_ais_r05.nc # AIS intersection masks on ELM r05 grid
ncap2 -O -S ~/icemask/msk_nsx.nco ${HOME}/msk_ais_rcm.nc ${HOME}/msk_ais_rcm.nc # AIS intersection masks on RACMO grid
ncap2 -O -S ~/icemask/msk_nsx.nco ${HOME}/msk_gis_rcm_r05.nc ${HOME}/msk_gis_r05.nc # GrIS intersection masks on ELM r05 grid
ncap2 -O -S ~/icemask/msk_nsx.nco ${HOME}/msk_gis_rcm.nc ${HOME}/msk_gis_rcm.nc # GrIS intersection masks on RACMO grid

# Move data from working directory (${HOME}) to grid directory in ${DATA} to prevent confusion
/bin/mv ${HOME}/msk_ais_r05.nc ${DATA}/grids
/bin/mv ${HOME}/msk_ais_rcm.nc ${DATA}/grids
/bin/mv ${HOME}/msk_gis_r05.nc ${DATA}/grids
/bin/mv ${HOME}/msk_gis_rcm.nc ${DATA}/grids

