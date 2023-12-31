#include "dns_const.h"

program SATURATION

    use TLAB_CONSTANTS, only: wp, wi
    use TLAB_VARS
    use TLAB_PROCS
    use THERMO_VARS

    implicit none

    real(wp) t_min, t_max, t_del, t, psat, qsat, dummy, t_loc, p, dpsat!, dpsat2
    integer(wi) iopt

! ###################################################################
    call TLAB_START

    imixture = MIXT_TYPE_AIRWATER
    nondimensional = .false.
    call THERMO_INITIALIZE()

    write (*, *) '1 - Saturation pressure as a function of T'
    write (*, *) '2 - Saturation specific humidity as a function of T-p'
    read (*, *) iopt

    write (*, *) 'Minimum T (cetigrade) ?'
    read (*, *) t_min
    write (*, *) 'Maximum T (centigrade) ?'
    read (*, *) t_max
    write (*, *) 'Increment T ?'
    read (*, *) t_del

    if (iopt == 2) then
        write (*, *) 'Pressure (bar) ?'
        read (*, *) p
    end if

! ###################################################################
    open (21, file='vapor.dat')
    if (iopt == 1) then
        write (21, *) '# T (C), T (K), psat (bar), L-ps (J/kg), L-cp (J/kg)'
    else if (iopt == 2) then
        write (21, *) '# T (C), T (K), qsat (g/kg)'
    end if

    t = t_min
    do while (t <= t_max)

        t_loc = (t + 273.15)/TREF
        call THERMO_POLYNOMIAL_PSAT(1, t_loc, psat)
        call THERMO_POLYNOMIAL_DPSAT(1, t_loc, dpsat)
        dummy = 1.0_wp/(p/psat - 1.0_wp)*rd_ov_rv
        qsat = dummy/(1.0_wp + dummy)
        if (iopt == 1) then
            ! dpsat2 = 0.0_wp
            ! DO ipsat = NPSAT,2,-1
            !    dpsat2 = dpsat2 *t_loc + THERMO_PSAT(ipsat)*M_REAL(ipsat-1)
            ! ENDDO
            ! PRINT*,dpsat-dpsat2
            write (21, 1000) t, t_loc*TREF, psat, dpsat*t_loc**2/psat*Rv*(RREF*TREF), &
                -(Cvl*t_loc +Lvl)*(RREF*TREF)/GRATIO
        else if (iopt == 2) then
            write (21, 2000) t, t_loc, qsat*1.0e3_wp
        end if

        t = t + t_del
    end do

    close (21)

    stop

1000 format(5(1x, G_FORMAT_R))
2000 format(3(1x, G_FORMAT_R))

end program SATURATION
