#include "types.h"
#include "dns_const.h"
#include "dns_error.h"

!########################################################################
!# HISTORY
!#
!# 2021/09/14 - J.K. Kostelecky
!#              Created
!#
!########################################################################
!# DESCRIPTION
!#
!#  Channel flow routines
!#
!########################################################################
subroutine FI_CHANNEL_CPG_FORCING(u, v, h1, h2, wrk1d, wrk3d)

  use TLAB_VARS, only : jmax, isize_field
  use TLAB_VARS, only : fcpg

  implicit none

#include "integers.h"

  TREAL, dimension(isize_field), intent(inout) :: u     
  TREAL, dimension(isize_field), intent(inout) :: v     
  TREAL, dimension(isize_field), intent(inout) :: h1    
  TREAL, dimension(isize_field), intent(inout) :: h2      
  TREAL, dimension(jmax),        intent(inout) :: wrk1d
  TREAL, dimension(isize_field), intent(inout) :: wrk3d
! -----------------------------------------------------------------------

  TINTEGER                                     :: ij

! #######################################################################

  ! current ubulk (mean streamwise velocity) of the flow
  call FI_CHANNEL_UBULK(u, wrk1d, wrk3d) 

  ! add constant streamwise pressure gradient
  do ij = 1, isize_field
    h1(ij) = h1(ij) + fcpg
  end do

  ! rotate turbulent channel flow (reducing spinup time)
  call FI_CHANNEL_SPINUP(u, v, h1, h2)
  
  return
end subroutine FI_CHANNEL_CPG_FORCING
!########################################################################
subroutine FI_CHANNEL_SPINUP(u, v, h1, h2)

  use TLAB_VARS,      only : isize_field, itime
  use TLAB_VARS,      only : channel_rot, nitera_spinup, spinuptime
  use TLAB_PROCS,     only : TLAB_WRITE_ASCII
  use TLAB_CONSTANTS, only : wfile

  implicit none

#include "integers.h"

  TREAL, dimension(isize_field), intent(inout) :: u     
  TREAL, dimension(isize_field), intent(inout) :: v     
  TREAL, dimension(isize_field), intent(inout) :: h1    
  TREAL, dimension(isize_field), intent(inout) :: h2    
! -----------------------------------------------------------------------

  TINTEGER                                     :: ij, itime_sub
  character*32                                 :: str
  character*128                                :: line

! #######################################################################
  
  ! rotate
  if (itime <= spinuptime + nitera_spinup) then
    if (itime > itime_sub) then
      write(str,*) itime; line = 'Rotating turbulent channel flow at iteration step '//trim(adjustl(str))//'.'
      call TLAB_WRITE_ASCII(wfile,line)
      itime_sub = itime
    end if
    !
    do ij = 1, isize_field
      h1(ij) = h1(ij) - channel_rot * v(ij)
      h2(ij) = h2(ij) + channel_rot * u(ij)
    end do
  end if

  return
end subroutine FI_CHANNEL_SPINUP
!########################################################################
subroutine FI_CHANNEL_UBULK(u, wrk1d, wrk3d)

  use TLAB_VARS, only : imax,jmax,kmax, isize_field
  use TLAB_VARS, only : g, area
  use TLAB_VARS, only : ubulk

  implicit none

#include "integers.h"

  TREAL, dimension(isize_field), intent(inout) :: u
  TREAL, dimension(jmax),        intent(inout) :: wrk1d
  TREAL, dimension(isize_field), intent(inout) :: wrk3d

! -----------------------------------------------------------------------
  TREAL, dimension(jmax)                       :: uxz
  TREAL                                        :: SIMPSON_NU

! #######################################################################

  call AVG_IK_V(imax, jmax, kmax, jmax, u, g(1)%jac, g(3)%jac, uxz, wrk1d, area)

  ubulk = (C_1_R / g(2)%nodes(g(2)%size)) * SIMPSON_NU(jmax, uxz, g(2)%nodes)

  return
end subroutine FI_CHANNEL_UBULK
!########################################################################
subroutine FI_CHANNEL_INITIALIZE()

  use TLAB_VARS,      only : g, qbg, ubulk_parabolic
  use TLAB_VARS,      only : itime, spinuptime, channel_rot, nitera_spinup
  use TLAB_CONSTANTS, only : efile, wfile, lfile
  use TLAB_PROCS

  implicit none

#include "integers.h"

  character*32  :: str
  character*128 :: line
  character*10  :: clock(2)

! -----------------------------------------------------------------------
  ! initialize bulk velocity
  ! laminar streamwise bulk velocity, make sure that the initial parabolic 
  ! velocity profile is correct (u(y=0)=u(y=Ly)=0)

  if (qbg(1)%type == PROFILE_PARABOLIC) then
    ubulk_parabolic = (C_1_R / g(2)%nodes(g(2)%size)) * (C_4_R/C_3_R) * qbg(1)%delta 
  else 
    call TLAB_WRITE_ASCII(efile, 'Analytical ubulk cannot be computed. Check initial parabolic velocity profile.')
    call TLAB_STOP(DNS_ERROR_UNDEVELOP)
  end if

  ! initialize turbulent channel flow rotation
  if (nitera_spinup > i0) then
    CALL TLAB_WRITE_ASCII(wfile, '############################################################################')
    CALL DATE_AND_TIME(clock(1),clock(2))
    line = 'Initializing channel spinup rotation on '//TRIM(ADJUSTL(clock(1)(1:8)))//' at '//TRIM(ADJUSTL(clock(2)))
    CALL TLAB_WRITE_ASCII(wfile,line)
    call TLAB_WRITE_ASCII(wfile, 'Turbulent channel flow rotation is turned on to reduce lam.-turb. transition time.')
    write(str,*) channel_rot; line = 'Channel rotation is set to '//trim(adjustl(str))//'.'
    call TLAB_WRITE_ASCII(wfile, line)
    ! write rotation warning in dns.war for step 0.
    write(str,*) itime; line = 'Rotating turbulent channel flow at iteration step 0.'
    call TLAB_WRITE_ASCII(wfile,line) 
    spinuptime = itime
  end if

  return
end subroutine FI_CHANNEL_INITIALIZE