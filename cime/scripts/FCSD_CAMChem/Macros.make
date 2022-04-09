SUPPORTS_CXX := FALSE
NETCDF_PATH := $(NETCDF)
PIO_FILESYSTEM_HINTS := gpfs
PNETCDF_PATH := $(PNETCDF)
ifeq ($(COMPILER),gnu)
  SUPPORTS_CXX := TRUE
  CFLAGS :=  -std=gnu99 
  CXX_LINKER := FORTRAN
  FC_AUTO_R8 :=  -fdefault-real-8 
  FFLAGS :=   -fconvert=big-endian -ffree-line-length-none -ffixed-line-length-none 
  FFLAGS_NOOPT :=  -O0 
  FIXEDFLAGS :=   -ffixed-form 
  FREEFLAGS :=  -ffree-form 
  MPICC :=  mpicc  
  MPICXX :=  mpicxx 
  MPIFC :=  mpif90 
  SCC :=  gcc 
  SCXX :=  g++ 
  SFC :=  gfortran 
endif
ifeq ($(COMPILER),intel)
  SUPPORTS_CXX := TRUE
  CFLAGS :=   -qno-opt-dynamic-align -fp-model precise -std=gnu99 
  CXX_LINKER := FORTRAN
  FC_AUTO_R8 :=  -r8 
  FFLAGS :=  -qno-opt-dynamic-align  -convert big_endian -assume byterecl -ftz -traceback -assume realloc_lhs -fp-model source  
  FFLAGS_NOOPT :=  -O0 
  FIXEDFLAGS :=  -fixed -132 
  FREEFLAGS :=  -free 
  HAS_F2008_CONTIGUOUS := FALSE
  MPICC :=  mpicc  
  MPICXX :=  mpicxx 
  MPIFC :=  mpif90 
  SCC :=  icc 
  SCXX :=  icpc 
  SFC :=  ifort 
  CXX_LDFLAGS :=  -cxxlib 
  ifeq ($(MPILIB),mpi-serial)
    ifeq ($(compile_threaded),false)
      PFUNIT_PATH := $(CESMDATAROOT)/tools/pFUnit/pFUnit3.2.8_cheyenne_Intel17.0.1_noMPI_noOpenMP
    endif
  endif
  ifeq ($(MPILIB),mpt)
    ifeq ($(compile_threaded),true)
      PFUNIT_PATH := $(CESMDATAROOT)/tools/pFUnit/pFUnit3.2.8_cheyenne_Intel17.0.1_MPI_openMP
    endif
  endif
endif
ifeq ($(COMPILER),pgi)
  CFLAGS :=  -gopt  -time 
  CXX_LINKER := CXX
  FC_AUTO_R8 :=  -r8 
  FFLAGS :=   -i4 -gopt  -time -Mextend -byteswapio -Mflushz -Kieee  
  FFLAGS_NOOPT :=  -O0 -g -Ktrap=fp -Mbounds -Kieee  
  FIXEDFLAGS :=  -Mfixed 
  FREEFLAGS :=  -Mfree 
  LDFLAGS :=  -time -Wl,--allow-multiple-definition 
  MPICC :=  mpicc 
  MPICXX :=  mpicxx 
  MPIFC :=  mpif90 
  SCC :=  pgcc 
  SCXX :=  pgc++ 
  SFC :=  pgf95 
endif
ifeq ($(MODEL),pop)
  CPPDEFS := $(CPPDEFS)  -D_USE_FLOW_CONTROL 
endif
ifeq ($(MODEL),gptl)
  CPPDEFS := $(CPPDEFS)  -DHAVE_NANOTIME -DBIT64 -DHAVE_VPRINTF -DHAVE_BACKTRACE -DHAVE_SLASHPROC -DHAVE_COMM_F2C -DHAVE_TIMES -DHAVE_GETTIMEOFDAY 
endif
ifeq ($(COMPILER),gnu)
  CPPDEFS := $(CPPDEFS)  -DFORTRANUNDERSCORE -DNO_R16 -DCPRGNU
  SLIBS := $(SLIBS)  -ldl 
  ifeq ($(compile_threaded),true)
    CFLAGS := $(CFLAGS)  -fopenmp 
    FFLAGS := $(FFLAGS)  -fopenmp 
  endif
  ifeq ($(DEBUG),TRUE)
    CFLAGS := $(CFLAGS)  -g -Wall -Og -fbacktrace -ffpe-trap=invalid,zero,overflow -fcheck=bounds 
    FFLAGS := $(FFLAGS)  -g -Wall -Og -fbacktrace -ffpe-trap=zero,overflow -fcheck=bounds 
  endif
  ifeq ($(DEBUG),FALSE)
    CFLAGS := $(CFLAGS)  -O 
    FFLAGS := $(FFLAGS)  -O 
  endif
  ifeq ($(MODEL),pio1)
    CPPDEFS := $(CPPDEFS)  -DNO_MPIMOD 
  endif
  ifeq ($(compile_threaded),true)
    LDFLAGS := $(LDFLAGS)  -fopenmp 
  endif
endif
ifeq ($(COMPILER),intel)
  FFLAGS := $(FFLAGS)  -qopt-report -xCORE_AVX2 -no-fma
  CFLAGS := $(CFLAGS)  -qopt-report -xCORE_AVX2 -no-fma
  CPPDEFS := $(CPPDEFS)  -DFORTRANUNDERSCORE -DCPRINTEL
  ifeq ($(compile_threaded),true)
    FFLAGS := $(FFLAGS)  -qopenmp 
  endif
  ifeq ($(MODEL),mom)
    FFLAGS := $(FFLAGS)  -r8 
  endif
  ifeq ($(compile_threaded),true)
    CFLAGS := $(CFLAGS)  -qopenmp 
  endif
  ifeq ($(DEBUG),FALSE)
    CFLAGS := $(CFLAGS)  -O2 -debug minimal 
    FFLAGS := $(FFLAGS)  -O2 -debug minimal 
  endif
  ifeq ($(DEBUG),TRUE)
    CFLAGS := $(CFLAGS)  -O0 -g 
    FFLAGS := $(FFLAGS)  -O0 -g -check uninit -check bounds -check pointers -fpe0 -check noarg_temp_created 
    CMAKE_OPTS := $(CMAKE_OPTS)  -DPIO_ENABLE_LOGGING=ON 
  endif
  ifeq ($(MPILIB),mpich)
    SLIBS := $(SLIBS)  -mkl=cluster 
  endif
  ifeq ($(MPILIB),mpich2)
    SLIBS := $(SLIBS)  -mkl=cluster 
  endif
  ifeq ($(MPILIB),mvapich)
    SLIBS := $(SLIBS)  -mkl=cluster 
  endif
  ifeq ($(MPILIB),mvapich2)
    SLIBS := $(SLIBS)  -mkl=cluster 
  endif
  ifeq ($(MPILIB),mpt)
    SLIBS := $(SLIBS)  -mkl=cluster 
  endif
  ifeq ($(MPILIB),openmpi)
    SLIBS := $(SLIBS)  -mkl=cluster 
  endif
  ifeq ($(MPILIB),impi)
    SLIBS := $(SLIBS)  -mkl=cluster 
  endif
  ifeq ($(MPILIB),mpi-serial)
    SLIBS := $(SLIBS)  -mkl 
  endif
  ifeq ($(compile_threaded),true)
    FFLAGS_NOOPT := $(FFLAGS_NOOPT)  -qopenmp 
    LDFLAGS := $(LDFLAGS)  -qopenmp 
  endif
endif
ifeq ($(COMPILER),pgi)
  CPPDEFS := $(CPPDEFS)  -DFORTRANUNDERSCORE -DNO_SHR_VMATH -DNO_R16  -DCPRPGI 
  SLIBS := $(SLIBS)  -llapack -lblas 
  ifeq ($(compile_threaded),true)
    FFLAGS := $(FFLAGS)  -mp 
  endif
  ifeq ($(MODEL),datm)
    FFLAGS := $(FFLAGS)  -Mnovect 
  endif
  ifeq ($(MODEL),dlnd)
    FFLAGS := $(FFLAGS)  -Mnovect 
  endif
  ifeq ($(MODEL),drof)
    FFLAGS := $(FFLAGS)  -Mnovect 
  endif
  ifeq ($(MODEL),dwav)
    FFLAGS := $(FFLAGS)  -Mnovect 
  endif
  ifeq ($(MODEL),dice)
    FFLAGS := $(FFLAGS)  -Mnovect 
  endif
  ifeq ($(MODEL),docn)
    FFLAGS := $(FFLAGS)  -Mnovect 
  endif
  ifeq ($(DEBUG),TRUE)
    FFLAGS := $(FFLAGS)  -O0 -g -Ktrap=fp -Mbounds -Kieee 
  endif
  ifeq ($(MPILIB),mpi-serial)
    SLIBS := $(SLIBS)  -ldl 
  endif
  ifeq ($(compile_threaded),true)
    CFLAGS := $(CFLAGS)  -mp 
    FFLAGS_NOOPT := $(FFLAGS_NOOPT)  -mp 
    LDFLAGS := $(LDFLAGS)  -mp 
  endif
endif
