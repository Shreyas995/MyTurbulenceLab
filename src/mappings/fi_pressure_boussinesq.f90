#include "dns_const.h"

!########################################################################
!#
!# Calculate the pressure field from a divergence free velocity field and a body force.
!#
!########################################################################
subroutine FI_PRESSURE_BOUSSINESQ(q, s, p, tmp1, tmp2, tmp)
    use TLAB_CONSTANTS, only: wp, wi, BCS_NN
    use TLAB_VARS, only: g
    use TLAB_VARS, only: imax, jmax, kmax, isize_field
    use TLAB_VARS, only: imode_eqns, imode_ibm, imode_elliptic
    use TLAB_VARS, only: bbackground, pbackground, rbackground, epbackground
    use TLAB_VARS, only: PressureFilter, stagger_on
    use TLAB_VARS, only: buoyancy, coriolis
    use TLAB_ARRAYS, only: wrk1d
    use TLAB_POINTERS_3D, only: p_wrk2d
    use THERMO_ANELASTIC
    use IBM_VARS, only: ibm_burgers
    use OPR_PARTIAL
    use OPR_BURGERS
    use OPR_ELLIPTIC
    use FI_SOURCES
    use OPR_FILTERS
    use THERMO_ANELASTIC

    implicit none

    real(wp), intent(in)    :: q(isize_field, 3)
    real(wp), intent(in)    :: s(isize_field, *)
    real(wp), intent(out)   :: p(isize_field)
    real(wp), intent(inout) :: tmp1(isize_field), tmp2(isize_field)
    real(wp), intent(inout) :: tmp(isize_field, 6)
    
    target      :: q, tmp, s
    ! -----------------------------------------------------------------------
    real(wp)    :: dummy
    real(wp)    :: dummy3d(isize_field, 1) ! only needed for pressure decomposition
    integer(wi) :: bcs(2, 2)
    integer(wi) :: iq
    integer(wi) :: siz, srt, end
    integer(wi) :: i, id_case
! -----------------------------------------------------------------------
#ifdef USE_BLAS
    integer ilen
#endif
! -----------------------------------------------------------------------

! Pointers to existing allocated space
    real(wp), dimension(:),       pointer :: u, v, w
    real(wp), dimension(:),       pointer :: tmp3, tmp4, tmp5, tmp6, tmp7, tmp8
    real(wp), dimension(:, :, :), pointer :: p_bcs

! #######################################################################
    bcs     = 0 ! Boundary conditions for derivative operator set to biased, non-zero
    p       = 0.0_wp
    tmp     = 0.0_wp
    dummy3d = 0.0_wp

! Define pointers
    u => q(:, 1)
    v => q(:, 2)
    w => q(:, 3)

! Chose case manually here
    id_case = 0 

! Definition of the cases
    ! Case 0: Pressure with accumulation of all terms
    ! Case 1: Advection diffusion together
    ! Case 2: Only Advection
    ! Case 3: Only Diffusion
    ! Case 4: Coriolis fores
    ! Case 5: Buoyancy force

! #######################################################################
! Sources
    call FI_SOURCES_FLOW(q, s, tmp, tmp1)

    tmp3 => tmp(:, 1)
    tmp4 => tmp(:, 2)
    tmp5 => tmp(:, 3)
    tmp6 => tmp(:, 4)
    tmp7 => tmp(:, 5)
    tmp8 => tmp(:, 6)

! If IBM, then use modified fields for derivatives
    if (imode_ibm == 1) ibm_burgers = .true.

    if (id_case == 1 .or. id_case == 0) then

        !  Advection and diffusion terms
        if (id_case == 1) then
            tmp3 = 0.0_wp
            tmp4 = 0.0_wp
            tmp5 = 0.0_wp
        end if
        
        call OPR_BURGERS_X(OPR_B_SELF, 0, imax, jmax, kmax, bcs, g(1), u, u, p, tmp1) ! store u transposed in tmp1
        tmp3 = tmp3 + p
        call OPR_BURGERS_X(OPR_B_U_IN, 0, imax, jmax, kmax, bcs, g(1), v, u, p, tmp2, tmp1) ! tmp1 contains u transposed
        tmp4 = tmp4 + p
        call OPR_BURGERS_X(OPR_B_U_IN, 0, imax, jmax, kmax, bcs, g(1), w, u, p, tmp2, tmp1) ! tmp1 contains u transposed
        tmp5 = tmp5 + p

        call OPR_BURGERS_Y(OPR_B_SELF, 0, imax, jmax, kmax, bcs, g(2), v, v, p, tmp1) ! store v transposed in tmp1
        tmp4 = tmp4 + p
        call OPR_BURGERS_Y(OPR_B_U_IN, 0, imax, jmax, kmax, bcs, g(2), u, v, p, tmp2, tmp1) ! tmp1 contains v transposed
        tmp3 = tmp3 + p
        call OPR_BURGERS_Y(OPR_B_U_IN, 0, imax, jmax, kmax, bcs, g(2), w, v, p, tmp2, tmp1) ! tmp1 contains v transposed
        tmp5 = tmp5 + p

        call OPR_BURGERS_Z(OPR_B_SELF, 0, imax, jmax, kmax, bcs, g(3), w, w, p, tmp1) ! store w transposed in tmp1
        tmp5 = tmp5 + p
        call OPR_BURGERS_Z(OPR_B_U_IN, 0, imax, jmax, kmax, bcs, g(3), v, w, p, tmp2, tmp1) ! tmp1 contains w transposed
        tmp4 = tmp4 + p
        call OPR_BURGERS_Z(OPR_B_U_IN, 0, imax, jmax, kmax, bcs, g(3), u, w, p, tmp2, tmp1) ! tmp1 contains w transposed
        tmp3 = tmp3 + p

    end if

    if (id_case == 2 .or. id_case == 3) then
        if (id_case == 2 .or. id_case == 3) then
            tmp3 = 0.0_wp
            tmp4 = 0.0_wp
            tmp5 = 0.0_wp
        end if

        ! Separating Diffusion
        ! NSE X-Comp
        call OPR_BURGERS_X(OPR_B_SELF, 0, imax, jmax, kmax, bcs, g(1), u, dummy3d, p, tmp1)
        tmp6 = tmp6 + p   ! Diffusion d2u/dx2
        call OPR_BURGERS_X(OPR_B_U_IN, 0, imax, jmax, kmax, bcs, g(1), v, dummy3d, p, tmp2, tmp1)
        tmp7 = tmp7 + p
        call OPR_BURGERS_X(OPR_B_U_IN, 0, imax, jmax, kmax, bcs, g(1), w, dummy3d, p, tmp2, tmp1)
        tmp8 = tmp8 + p

        ! NSE Y-Comp
        call OPR_BURGERS_Y(OPR_B_SELF, 0, imax, jmax, kmax, bcs, g(2), v, dummy3d, p, tmp1)
        tmp7 = tmp7 + p ! Diffusion d2u/dx2 + d2u/dy2
        call OPR_BURGERS_Y(OPR_B_U_IN, 0, imax, jmax, kmax, bcs, g(2), u, dummy3d, p, tmp2, tmp1)
        tmp6 = tmp6 + p
        call OPR_BURGERS_Y(OPR_B_U_IN, 0, imax, jmax, kmax, bcs, g(2), w, dummy3d, p, tmp2, tmp1)
        tmp8 = tmp8 + p

        ! NSE Z-Comp
        call OPR_BURGERS_Z(OPR_B_SELF, 0, imax, jmax, kmax, bcs, g(3), w, dummy3d, p, tmp1)
        tmp8 = tmp8 + p  ! Diffusion d2u/dx2 + d2u/dy2 + d2u/dz2
        call OPR_BURGERS_Z(OPR_B_U_IN, 0, imax, jmax, kmax, bcs, g(3), v, dummy3d, p, tmp2, tmp1)
        tmp7 = tmp7 + p
        call OPR_BURGERS_Z(OPR_B_U_IN, 0, imax, jmax, kmax, bcs, g(3), u, dummy3d, p, tmp2, tmp1)
        tmp6 = tmp6 + p

    end if

    if (id_case == 2) then
        tmp3 = tmp3 - tmp6
        tmp4 = tmp4 - tmp7
        tmp5 = tmp5 - tmp8

    else if (id_case == 3) then
        tmp3 = tmp6
        tmp4 = tmp7
        tmp5 = tmp8

    end if

    ! Coriolis forcing term
    if (id_case == 4) then
        call FI_CORIOLIS(coriolis,imax, jmax, kmax, q, tmp)
        tmp3 => tmp(:, 1)
        tmp4 => tmp(:, 2)
        tmp5 => tmp(:, 3)
    end if

    if (id_case == 5) then
        do iq = 1, 3
            if (buoyancy%type == EQNS_EXPLICIT) then
                call THERMO_ANELASTIC_BUOYANCY(imax, jmax, kmax, s, epbackground, pbackground, rbackground, tmp1)
            else
                if (buoyancy%active(iq)) then
                    if (iq == 2) then
                        call FI_BUOYANCY(buoyancy, imax, jmax, kmax, s, tmp1, bbackground)
                    else
                        wrk1d(:, 1) = 0.0_wp
                        call FI_BUOYANCY(buoyancy, imax, jmax, kmax, s, tmp1, wrk1d)
                    end if

                    call DNS_OMP_PARTITION(isize_field, srt, end, siz)
                    dummy = buoyancy%vector(iq)
#ifdef USE_BLAS
                    ilen = isize_field
                    call DAXPY(ilen, dummy, tmp1(srt), 1, tmp(srt, iq), 1)
#else
                    do i = srt, end
                        tmp(i, iq) = tmp(i, iq) + dummy*tmp1(i)
                    end do
#endif
                end if
            end if
        end do

        tmp3 => tmp(:, 1)
        tmp4 => tmp(:, 2)
        tmp5 => tmp(:, 3)

    end if


! If IBM, set flag back to false
    if (imode_ibm == 1) ibm_burgers = .false.

! Set p-field back to zero
    p = 0.0_wp

! Apply IBM BCs
    if (imode_ibm == 1) then
        call IBM_BCS_FIELD(tmp3)
        call IBM_BCS_FIELD(tmp4)
        call IBM_BCS_FIELD(tmp5)
    end if

! Calculate forcing term Ox
    if (imode_eqns == DNS_EQNS_ANELASTIC) then
        call THERMO_ANELASTIC_WEIGHT_INPLACE(imax, jmax, kmax, rbackground, tmp3)
    end if
    if (stagger_on) then
        call OPR_PARTIAL_X(OPR_P1_INT_VP, imax, jmax, kmax, bcs, g(1), tmp3, tmp2)
        call OPR_PARTIAL_Z(OPR_P0_INT_VP, imax, jmax, kmax, bcs, g(3), tmp2, tmp1)
    else
        call OPR_PARTIAL_X(OPR_P1, imax, jmax, kmax, bcs, g(1), tmp3, tmp1)
    end if
    p = p + tmp1

! Calculate forcing term Oy
    if (imode_eqns == DNS_EQNS_ANELASTIC) then
        call THERMO_ANELASTIC_WEIGHT_INPLACE(imax, jmax, kmax, rbackground, tmp4)
    end if
    if (stagger_on) then
        call OPR_PARTIAL_X(OPR_P0_INT_VP, imax, jmax, kmax, bcs, g(1), tmp4, tmp2)
        call OPR_PARTIAL_Y(OPR_P1, imax, jmax, kmax, bcs, g(2), tmp2, tmp3)
        call OPR_PARTIAL_Z(OPR_P0_INT_VP, imax, jmax, kmax, bcs, g(3), tmp3, tmp1)
    else
        call OPR_PARTIAL_Y(OPR_P1, imax, jmax, kmax, bcs, g(2), tmp4, tmp1)
    end if
    p = p + tmp1

! Calculate forcing term Oz
    if (imode_eqns == DNS_EQNS_ANELASTIC) then
        call THERMO_ANELASTIC_WEIGHT_INPLACE(imax, jmax, kmax, rbackground, tmp5)
    end if
    if (stagger_on) then
        call OPR_PARTIAL_X(OPR_P0_INT_VP, imax, jmax, kmax, bcs, g(1), tmp5, tmp2)
        call OPR_PARTIAL_Z(OPR_P1_INT_VP, imax, jmax, kmax, bcs, g(3), tmp2, tmp1)
    else
        call OPR_PARTIAL_Z(OPR_P1, imax, jmax, kmax, bcs, g(3), tmp5, tmp1)
    end if
    p = p + tmp1

! #######################################################################
! Solve Poisson equation
! #######################################################################
! Neumman BCs in d/dy(p) s.t. v=0 (no-penetration)
    if (stagger_on) then ! todo: only need to stagger upper/lower boundary plane, not full h2-array
        call OPR_PARTIAL_X(OPR_P0_INT_VP, imax, jmax, kmax, bcs, g(1), tmp4, tmp5)
        call OPR_PARTIAL_Z(OPR_P0_INT_VP, imax, jmax, kmax, bcs, g(3), tmp5, tmp4)
        if (imode_ibm == 1) call IBM_BCS_FIELD_STAGGER(tmp4)
    end if
    p_bcs(1:imax, 1:jmax, 1:kmax) => tmp4(1:imax*jmax*kmax)
    p_wrk2d(:, :, 1) = p_bcs(:, 1, :)
    p_wrk2d(:, :, 2) = p_bcs(:, jmax, :)

! Pressure field in p
    select case (imode_elliptic)
    case (FDM_COM6_JACOBIAN)
        call OPR_POISSON_FXZ(imax, jmax, kmax, g, BCS_NN, p, tmp1, tmp2, p_wrk2d(:, :, 1), p_wrk2d(:, :, 2))

    case (FDM_COM4_DIRECT, FDM_COM6_DIRECT)
        call OPR_POISSON_FXZ_D(imax, jmax, kmax, g, BCS_NN, p, tmp1, tmp2, p_wrk2d(:, :, 1), p_wrk2d(:, :, 2))
    end select

    ! filter pressure p
    if (any(PressureFilter(:)%type /= DNS_FILTER_NONE)) then
        call OPR_FILTER(imax, jmax, kmax, PressureFilter, p, tmp(:,4))
    end if

! Stagger pressure field p back on velocity grid
    if (stagger_on) then
        call OPR_PARTIAL_Z(OPR_P0_INT_PV, imax, jmax, kmax, bcs, g(3), p, tmp1)
        call OPR_PARTIAL_X(OPR_P0_INT_PV, imax, jmax, kmax, bcs, g(1), tmp1, p)
    end if

    nullify (u, v, w, tmp3, tmp4, tmp5, p_bcs)

    return
end subroutine FI_PRESSURE_BOUSSINESQ
