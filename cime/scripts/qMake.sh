#!/bin/bash

#compset=FGC_CLM50
#compset=FC2010climo_GC
#compset=FC2010climoVBS
#compset=FC2000climo_GC
compset=FCSD_GC
#compset=FCHIST_GC
#compset=FCHIST

res=f19_f19_mg17
#res=f09_f09_mg17

#folder=FC2000climo
#folder=CESM-GC_Benchmark
#folder=FCCLIMO_GEOSChem2
folder=FCSD_GEOSChem_CloudSulf
#folder=GC_YearBenchmark
#folder=MOZART_MonthBenchmark
#folder=FCSD_GC_MAM
#folder=FCHIST_GC_MAM
#folder=FCHIST

# Perform checks
./query_config --compsets cam | grep $compset >/dev/null
[[ $? -ne 0 ]] && echo "Compset $compset does not exist!" && exit 1;

./query_config --grids | grep $res >/dev/null
[[ $? -ne 0 ]] && echo "Grid $res does not exist" && exit 1;

[[ -d $folder ]] && echo "Folder $folder already exists!" && exit 1;

# Create new case
./create_newcase --case $folder --compset $compset --res $res --run-unsupported --handle-preexisting-dirs u
[[ $? -ne 0 ]] && echo "create_newcase failed!" && exit 1;

cd $folder || exit

./xmlchange RUN_STARTDATE="2015-01-01"
./xmlchange --subgroup case.run JOB_WALLCLOCK_TIME="12:00:00"; # Limit walltime
./xmlchange STOP_N=14; ./xmlchange STOP_OPTION=ndays; # Change end date
./xmlchange REST_N=3; ./xmlchange REST_OPTION=nmonths; # Change restart intervals
./xmlchange RESUBMIT=8;

TASKS=576; ./xmlchange NTASKS_CPL=$TASKS; ./xmlchange NTASKS_ATM=$TASKS; ./xmlchange NTASKS_LND=$TASKS; ./xmlchange NTASKS_ICE=$TASKS; ./xmlchange NTASKS_OCN=$TASKS ;./xmlchange NTASKS_ROF=$TASKS; ./xmlchange NTASKS_GLC=$TASKS; ./xmlchange NTASKS_WAV=$TASKS;
THRDS=1; ./xmlchange NTHRDS_CPL=$THRDS; ./xmlchange NTHRDS_ATM=$THRDS; ./xmlchange NTHRDS_LND=$THRDS; ./xmlchange NTHRDS_ICE=$THRDS; ./xmlchange NTHRDS_OCN=$THRDS ;./xmlchange NTHRDS_ROF=$THRDS; ./xmlchange NTHRDS_GLC=$THRDS; ./xmlchange NTHRDS_WAV=$THRDS;

#./xmlchange DOUT_S=FALSE
./xmlchange USE_ESMF_LIB=TRUE; ./xmlchange ESMF_LOGFILE_KIND=ESMF_LOGKIND_SINGLE

NTHRDS=$(./xmlquery --value NTHRDS_ATM)
#Note that NTHRDS_ATM ==1, this is required to run CESM-GC!
[[ $compset == *GC ]] && [[ $NTHRDS -ne 1 ]] && echo "NTHRDS needs to be 1 to run CESM-GC!" && exit 1;

## Optional
./xmlchange JOB_QUEUE=regular
#./xmlchange DEBUG=TRUE
./xmlchange DEBUG=FALSE
./xmlchange TIMER_LEVEL=5

search="cam_physics_mesh.*"
if [ $res == f09_f09_mg17 ]; then
    replace="cam_physics_mesh = '/glade/p/cesmdata/cseg/inputdata/atm/cam/coords/fv0.9x1.25_esmf_141008.nc',"
elif [ $res == f19_f19_mg17 ]; then
    replace="cam_physics_mesh = '/glade/p/cesmdata/cseg/inputdata/atm/cam/coords/fv1.9x2.5_esmf_141008.nc',"
else
    echo "Unknown grid for CESM-GC: $res"
    exit 1;
fi
sed -i "s~$search~$replace~g" user_nl_cam

./case.setup
if [ $? != 0 ]; then echo "case.setup failed!"; exit 1; fi

./case.build --clean
if [ $? != 0 ]; then echo "case.build --clean failed!"; exit 1; fi
qcmd -- ./case.build -v
if [ $? != 0 ]; then echo "case.build failed!"; exit 1; fi

echo -e "\n\n Case $folder was created succesfully!"
exit 0;


