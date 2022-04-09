# This file is for user convenience only and is not used by the model
# Changes to this file will be ignored and overwritten
# Changes to the environment should be made in env_mach_specific.xml
# Run ./case.setup --reset to regenerate this file
source /glade/u/apps/ch/opt/lmod/7.5.3/lmod/lmod/init/sh
module purge 
module load ncarenv/1.3 cmake intel/19.0.5 esmf_libs mkl
module use /glade/p/cesmdata/cseg/PROGS/modulefiles/esmfpkgs/intel/19.0.5/
module load esmf-8.1.0b21-ncdfio-mpt-O mpt/2.21 netcdf/4.7.3 pnetcdf/1.12.1 ncarcompilers/0.5.0
export OMP_STACKSIZE=1024M
export TMPDIR=/glade/scratch/fritzt
export MPI_TYPE_DEPTH=16
export MPI_IB_CONGESTED=1
export MPI_USE_ARRAY=None
export TMPDIR=/glade/scratch/fritzt
export MPI_USE_ARRAY=false