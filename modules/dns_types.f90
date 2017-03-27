#include "types.h"

MODULE DNS_TYPES
  IMPLICIT NONE
  SAVE

  TINTEGER, PARAMETER :: MAX_PARS = 10

  TYPE background_d
     SEQUENCE
     TINTEGER type
     TREAL reference, mean, delta, ymean, thick, diam
     TREAL, DIMENSION(MAX_PARS) :: parameters !, jet
  END TYPE background_d

  TYPE term_structure
     SEQUENCE
     TINTEGER type
     TINTEGER, DIMENSION(MAX_PARS) :: scalar     ! fields defining this term
     LOGICAL,  DIMENSION(MAX_PARS) :: active     ! fields affected by this term
     TREAL,    DIMENSION(MAX_PARS) :: parameters
     TREAL,    DIMENSION(MAX_PARS) :: auxiliar
     TREAL,    DIMENSION(3)        :: vector
  END TYPE term_structure

  TYPE grid_structure
     SEQUENCE
     CHARACTER*8 name
     TINTEGER size, inb_grid, mode_fdm
     LOGICAL uniform, periodic
     TREAL scale
     TREAL, DIMENSION(:),   POINTER :: nodes
     TREAL, DIMENSION(:,:), POINTER :: jac   ! pointer to Jacobians
     TREAL, DIMENSION(:,:), POINTER :: lu1   ! pointer to LU decomposition for 1. derivative
     TREAL, DIMENSION(:,:), POINTER :: lu2   ! pointer to LU decomposition for 2. derivative
     TREAL, DIMENSION(:,:), POINTER :: lu2d  ! pointer to LU decomposition for 2. derivative inc. diffusion
     TREAL, DIMENSION(:,:), POINTER :: mwn   ! pointer to modified wavenumbers
  END TYPE grid_structure

  TYPE pointers_structure
     SEQUENCE
     TREAL, DIMENSION(:), POINTER :: field
  END TYPE pointers_structure

#ifdef USE_MPI
#include "mpif.h"
#endif

  TYPE subarray_structure
     SEQUENCE
     LOGICAL active
     INTEGER communicator
     INTEGER subarray
#ifdef USE_MPI
     INTEGER(KIND=MPI_OFFSET_KIND) offset
#else
     INTEGER offset
#endif
  END type subarray_structure

  TYPE filter_structure
     SEQUENCE
     TINTEGER type, size, inb_filter, delta
     TREAL alpha
     TINTEGER bcs_min, bcs_max
     LOGICAL uniform, periodic
     TINTEGER mpitype
     TREAL, DIMENSION(:,:), POINTER :: coeffs ! pointer to coefficients
  END TYPE filter_structure
  
END MODULE DNS_TYPES
