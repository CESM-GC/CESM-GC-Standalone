module mo_apex

!-------------------------------------------------------------------------------
! Purpose:
!
!   Calculate apex coordinates and magnetic field magnitudes
!   at global geographic grid for year of current model run. 
!
! Method: 
!
!   The magnetic field parameters output by this module are time and height
!     independent. They are chunked for waccm physics, i.e., allocated as 
!     (pcols,begchunk:endchunk)
!   Interface sub apexmag is called once per run from sub inti.
!     Sub apexmag may be called for years 1900 through 2005.
!   This module is dependent on routines in apex_subs.F (modified IGRF model).
!   Apex_subs has several authors, but has been modified and maintained
!     in recent years by Roy Barnes (bozo@ucar.edu).
!   Subs apxmka and apxmall are called with the current lat x lon grid 
!     resolution.
!
! Author: Ben Foster, foster@ucar.edu (Nov, 2003)
!-------------------------------------------------------------------------------

   use shr_kind_mod,    only: r8 => shr_kind_r8
   use ppgrid,          only: pcols, begchunk, endchunk          ! physics grid
   use cam_abortutils,  only: endrun
   use cam_logfile,     only: iulog
   use spmd_utils,      only: masterproc
   !use apex,            only: apex_mka, apex_mall, apex_dypol, apex_set_igrf
   !use apex,            only: apex_beg_yr, apex_end_yr
   implicit none

   private
   public :: mo_apex_readnl
   public :: mo_apex_init
   public :: mo_apex_init1
   public :: alatm, alonm, bnorth, beast, bdown, bmag
   public :: d1vec, d2vec, colatp, elonp
   public :: maglon0 ! geographic longitude at the equator where geomagnetic longitude is zero (radians)

   ! year to initialize apex
   real(r8), public, protected :: geomag_year = -1._r8
   logical, public, protected :: geomag_year_updated = .true.

   integer :: fixed_geomag_year = -1

!-------------------------------------------------------------------------------
! Magnetic field output arrays, chunked for physics:
! (these are allocated (pcols,begchunk:endchunk) by sub allocate_arrays)
!-------------------------------------------------------------------------------
   real(r8), protected, allocatable, dimension(:,:) :: & ! (pcols,begchunk:endchunk)
     alatm,  & ! apex mag latitude at each geographic grid point (radians)
     alonm,  & ! apex mag longitude at each geographic grid point (radians)
     bnorth, & ! northward component of magnetic field
     beast,  & ! eastward component of magnetic field
     bdown,  & ! downward component of magnetic field
     bmag      ! magnitude of magnetic field
   real(r8), protected, allocatable, dimension(:,:,:) :: & ! (3,pcols,begchunk:endchunk)
     d1vec,    & ! base vectors more-or-less magnetic eastward direction
     d2vec       ! base vectors more-or-less magnetic downward/equatorward direction
   real(r8), protected :: &
     colatp,   & ! geocentric colatitude of geomagnetic dipole north pole (deg)
     elonp       ! East longitude of geomagnetic dipole north pole (deg)

   real(r8), protected :: maglon0

   character(len=256) :: igrf_geomag_coefs_file = 'igrf_geomag_coefs_file'

contains

!======================================================================
!======================================================================
subroutine mo_apex_readnl(nlfile)

  use namelist_utils, only : find_group_name
  use units,          only : getunit, freeunit
  use spmd_utils,     only : mpicom, masterprocid, mpi_integer, mpi_character

  character(len=*), intent(in) :: nlfile  ! filepath for file containing namelist input

  !! Local variables
  !integer :: unitn, ierr
  !character(len=*), parameter :: subname = 'mo_apex_readnl'

  !namelist /geomag_nl/ fixed_geomag_year, igrf_geomag_coefs_file

  !! Read namelist
  !if (masterproc) then
  !   unitn = getunit()
  !   open( unitn, file=trim(nlfile), status='old' )
  !   call find_group_name(unitn, 'geomag_nl', status=ierr)
  !   if (ierr == 0) then
  !      read(unitn, geomag_nl, iostat=ierr)
  !      if (ierr /= 0) then
  !         call endrun(subname // ':: ERROR reading namelist')
  !      end if
  !   end if
  !   close(unitn)
  !   call freeunit(unitn)
  !end if

  !! Broadcast namelist variables
  !call mpi_bcast(fixed_geomag_year,  1, mpi_integer, masterprocid, mpicom, ierr)
  !call mpi_bcast(igrf_geomag_coefs_file,  len(igrf_geomag_coefs_file), mpi_character, masterprocid, mpicom, ierr)

end subroutine mo_apex_readnl

!======================================================================
!======================================================================
subroutine mo_apex_init1()
   use time_manager,  only: get_curr_date
   use dyn_grid,      only: get_horiz_grid_dim_d


end subroutine mo_apex_init1

!======================================================================
!======================================================================
subroutine mo_apex_init(phys_state)
!-------------------------------------------------------------------------------
! Driver for apex code to calculate apex magnetic coordinates at 
!   current geographic spatial resolution for given year. This calls
!   routines in apex_subs.F.
!
! This is called once per run from sub inti.
!-------------------------------------------------------------------------------

   use physconst,only : pi
   use physics_types, only: physics_state
   !use epp_ionization,only: epp_ionization_setmag

   ! Input/output arguments
   type(physics_state), intent(in), dimension(begchunk:endchunk) :: phys_state

!!-------------------------------------------------------------------------------
!! Local variables
!!-------------------------------------------------------------------------------
!   real(r8), parameter :: re    = 6.378165e8_r8 ! earth radius (cm)
!   real(r8), parameter :: h0    = 9.0e6_r8      ! base height (90 km)
!   real(r8), parameter :: hs    = 1.3e7_r8
!   real(r8), parameter :: eps   = 1.e-6_r8      ! epsilon
!   real(r8), parameter :: cm2km = 1.e-5_r8
!
!   integer  :: c, i, ist           ! indices
!   integer  :: ncol
!
!   real(r8) :: alt, hr, alon, alat, & ! apxmall args
!               vmp, w, d, be3, sim, xlatqd, f, si, collat, collon
!
!!-------------------------------------------------------------------------------
!! Non-scalar arguments returned by APXMALL:
!!-------------------------------------------------------------------------------
!   real(r8) :: bhat(3)
!   real(r8) :: d3(3)
!   real(r8) :: e1(3), e2(3), e3(3)
!   real(r8) :: f1(2), f2(2)
!
!   real(r8) :: bg(3), d1g(3), d2g(3), bmg
!
!   real(r8) :: rdum
!
!   real(r8) :: maglat(pcols,begchunk:endchunk)
!
!   real(r8), parameter :: rtd = 180._r8/pi     ! radians to degrees
!   real(r8), parameter :: dtr = pi/180._r8     ! degrees to radians
!
!   call mo_apex_init1()
!   if ((.not.geomag_year_updated) .and. (allocated(alatm))) return
!
!!-------------------------------------------------------------------------------
!! Allocate output arrays
!!-------------------------------------------------------------------------------
!   call allocate_arrays()
!
!   alt   = hs*cm2km    ! altitude for apxmall (km)
!   hr    = alt         ! reference altitude (km)
!
!!------------------------------------------------------------------------------
!! Apex coords alon, alat are returned for each geographic grid point:
!! first form global arrays
!!------------------------------------------------------------------------------
!   do c = begchunk, endchunk
!      ncol = phys_state(c)%ncol
!      do i = 1,ncol
!         collat = phys_state(c)%lat(i)*rtd  ! latitude of current column (deg)
!         collon = phys_state(c)%lon(i)*rtd  ! latitude of current column (deg)
!         if ( collon < -180._r8 ) collon = collon+360._r8
!         if ( collon >  180._r8 ) collon = collon-360._r8
!         call apex_mall(                                  &
!           collat, collon, alt, hr,           & ! Inputs
!           bg, bhat, bmag(i,c), si,     & ! Mag Fld
!           alon, alat,                                  & ! Apex lon,lat output
!           vmp, w, d, be3, sim, d1vec(:,i,c), d2vec(:,i,c),  d3, e1, e2, e3, & ! Mod Apex
!           xlatqd, f, f1, f2, ist )                       ! Qsi-Dpl
!         if( ist /= 0 ) then
!           write(iulog,"(/,'>>> mo_apex_init: Error from apxmall: ist=',i4)") ist
!           call endrun('mo_apex_init: Error from apxmall')
!         end if
!         beast (i,c) = bg(1)
!         bnorth(i,c) = bg(2)
!         bdown (i,c) = -bg(3)
!         alonm (i,c) = alon*dtr       ! mag lons (radians)
!         alatm (i,c) = alat*dtr       ! mag lats (radians)
!         maglat(i,c) = alat  ! mag lats (degrees)
!      enddo
!   enddo
!
!   ! find geograghic latitude ( maglon0 ) where the geomagnetic latitude is zero at the equator
!   ! by first extracting the geographic coordinates at zero degrees longitude ...
!   collat = 0._r8
!   collon = 0._r8
!   call apex_mall(                                     &
!        collat, collon, alt, hr,                       & ! Inputs
!        bg, bhat, bmg, si,                             & ! Mag Fld
!        alon, alat,                                    & ! Apex lon,lat output
!        vmp, w, d, be3, sim, d1g, d2g, d3, e1, e2, e3, & ! Mod Apex
!        xlatqd, f, f1, f2, ist )                         ! Qsi-Dpl
!
!   if( ist /= 0 ) then
!      write(iulog,"(/,'>>> mo_apex_init: Error from apxmall: ist=',i4)") ist
!      call endrun('mo_apex_init: Error from apxmall')
!   end if
!
!   maglon0 = -alon*dtr ! (radians) geograghic latitude where the geomagnetic latitude is zero
!                       ! where longitude ranges from -180E to 180E
!
!   call apex_dypol( colatp, elonp, rdum )       ! get geomagnetic dipole north pole 
!
!   if (masterproc) then
!      write(iulog, "('mo_apex_init: colatp,elonp ', 2f12.6)") colatp, elonp
!      write(iulog, "('mo_apex_init: Calculated apex magnetic coordinates for year AD ',f8.2)") geomag_year
!   endif
!
!   call epp_ionization_setmag(maglat)

end subroutine mo_apex_init

subroutine allocate_arrays
!!------------------------------------------------------------------------------
!! Allocate module output arrays for chunked physics grid.
!!------------------------------------------------------------------------------
!
!!------------------------------------------------------------------------------
!! local variables
!!------------------------------------------------------------------------------
!  integer :: istat  ! status of allocate statements
!
!  if (.not.allocated(alatm)) then
!    allocate(alatm(pcols,begchunk:endchunk),stat=istat)
!    if (istat /= 0) then
!      write(iulog,"('>>> allocate_arrays: allocate of alatm failed: istat=',i5)") istat
!      call endrun
!    end if
!  end if
!
!  if (.not.allocated(alonm)) then
!    allocate(alonm(pcols,begchunk:endchunk),stat=istat)
!    if (istat /= 0) then
!      write(iulog,"('>>> allocate_arrays: allocate of alonm failed: istat=',i5)") istat
!      call endrun
!    end if
!  end if
!
!  if (.not.allocated(bnorth)) then
!    allocate(bnorth(pcols,begchunk:endchunk),stat=istat)
!    if (istat /= 0) then
!      write(iulog,"('>>> allocate_arrays: allocate of bnorth failed: istat=',i5)") istat
!      call endrun
!    end if
!  end if
!
!  if (.not.allocated(beast)) then
!    allocate(beast(pcols,begchunk:endchunk),stat=istat)
!    if (istat /= 0) then
!      write(iulog,"('>>> allocate_arrays: allocate of beast failed: istat=',i5)") istat
!      call endrun
!    end if
!  end if
!
!  if (.not.allocated(bdown)) then
!    allocate(bdown(pcols,begchunk:endchunk),stat=istat)
!    if (istat /= 0) then
!      write(iulog,"('>>> allocate_arrays: allocate of bdown failed: istat=',i5)") istat
!      call endrun
!    end if
!  end if
!
!  if (.not.allocated(bmag)) then
!    allocate(bmag(pcols,begchunk:endchunk),stat=istat)
!    if (istat /= 0) then
!      write(iulog,"('>>> allocate_arrays: allocate of bmag failed: istat=',i5)") istat
!      call endrun
!    end if
!  end if
!  if (.not.allocated(d1vec)) then
!    allocate(d1vec(3,pcols,begchunk:endchunk),stat=istat)
!    if (istat /= 0) then
!      write(iulog,"('>>> allocate_arrays: allocate of d1vec failed: istat=',i5)") istat
!      call endrun
!    endif
!  endif
!
!  if (.not.allocated(d2vec)) then
!    allocate(d2vec(3,pcols,begchunk:endchunk),stat=istat)
!    if (istat /= 0) then
!      write(iulog,"('>>> allocate_arrays: allocate of d2vec failed: istat=',i5)") istat
!      call endrun
!    endif
!  endif
!
end subroutine allocate_arrays

end module mo_apex
