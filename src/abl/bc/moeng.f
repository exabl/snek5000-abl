c> @defgroup bc_moeng Moeng boundary condition
c> @{
c
c> @brief Stress boundary condition as formulated by Moeng (1984)
c> Also has optional temporal filtering c.f: Yang et al. Physical Review
c>      Fluids 2, no. 10 (2017): 104601.
c> @see https://journals.ametsoc.org/doi/abs/10.1175/1520-0469(1984)041%3C2052:ALESMF%3E2.0.CO%3B2
c> @see https://doi.org/10.1103/PhysRevFluids.2.104601.
c>
c> @note Boundary condition evaluated at higher nodes, may need to be corrected for Ekmann turning
c> @note This subroutine MAY NOT be called by every process
      subroutine abl_userbc(ix,iy,iz,iside,eg) ! set up boundary conditions
      implicit none


      integer ix, iy, iz, iside, eg, ie, idx
      real u1_2, w1_2, y1_2, y0, uh, u_star, alpha
      real eps, Tf, half_ymax
      real t1_2
      real Psi_M, Psi_H, L_ob_old, L_ob_new, Ri_b

      real thermal_flux
      real friction_vel

      include 'SIZE'
      include 'NEKUSE'  ! trx, try, trz, temp
      include 'PARALLEL'  ! gllel
      include 'SOLN'  ! vx, vz, t
      include 'GEOM'  ! ym1
      include 'TSTEP'  ! istep
      include 'SGS'  ! dg2_max
      include 'SGS_BC'  ! u_star_bc, alpha_bc, u_star_max
      include 'WMLES'  ! KAPPA, wmles_bc_z_index, wmles_bc_z0, wmles_bc_temp_filt, u_wm, w_wm, L_ob


c      if (cbc(iside,gllel(eg),ifield).eq.'v01')

      ! Use value from par file for index to sample velocities at and roughness parameter
      idx = wmles_bc_z_index
      y0 = wmles_bc_z0
c--------Calculate Moeng's model parameters
      ie=gllel(eg)

      u1_2=(vx(ix, idx+1, iz, ie) + vx(ix, idx, iz, ie))/2
      w1_2=(vz(ix, idx+1, iz, ie) + vz(ix, idx, iz, ie))/2
      t1_2=(t(ix, idx+1, iz, ie, 1) + t(ix, idx, iz, ie, 1))/2

      if (wmles_bc_temp_filt) then
        if (istep .le . 5) then
          eps = 1.
        else
          ! Tf = sqrt(dg2_max(ie)) / u1_2
          ! eps = 5. * dt / abs(Tf)
          eps = 0.1
        endif

#ifdef DEBUG
        if (nid .eq. 0) then
            print*, "userbc: temporal filtering eps=", eps
        endif
#endif

        u1_2 = (1.-eps)*u_wm(ix, iz, ie) + eps*u1_2
        w1_2 = (1.-eps)*w_wm(ix, iz, ie) + eps*w1_2

c>      @todo Assign and use t_wm: temporal filtering for temperature

        ! Save it for next time step
        u_wm(ix, iz, ie) = u1_2
        w_wm(ix, iz, ie) = w1_2
      endif

      y1_2=(ym1(ix, idx+1, iz, ie) + ym1(ix, idx, iz, ie))/2

      ! Horizontal velocity magnitude
      uh = sqrt(u1_2**2 + w1_2**2)

      ! Bulk Richardson number [See Eq. 12 in Maronga et al. (2019)]
      Ri_b = g_acc * y1_2 * (t1_2 - t_surf) / max(t1_2 * uh**2, 1e-12)

      ! Obukhov length
      L_ob_old = L_ob(ix, iz, ie)

      ! Initialize Obukhov length
      if (L_ob_old .lt. 0) then
         L_ob_old = Ri_b * y0 / 10
         print *, "Ri_b ", Ri_b, "z0=", wmles_bc_z0, "L_ob = ", L_ob_old
      endif
      call calc_L_ob(L_ob_new, L_ob_old, y0, y1_2, Ri_b)
      L_ob(ix, iz, ie) = L_ob_new

      call calc_Psi(Psi_M, Psi_H, y0, y1_2, L_ob_new)

      ! Friction velocity
      u_star = friction_vel(uh, kappa, y1_2, y0, Psi_M)
      ! Angle of the horizontal velocity vector
      alpha = atan2(w1_2, u1_2)

c--------Calculate Stresses
      trx = -(u_star ** 2) * cos(alpha)
      try = 0.0
      trz = -(u_star ** 2) * sin(alpha)

c--------Calculate Thermal boundary condition
      ! temp = t_surf

      ! Alternatively
      ! half_ymax = uparam(6) * 0.5
      ! temp = temp_strat(t_surf, y, half_ymax)

c>    @todo Allow `y0 != z_os` (thermal surface roughness length)
      ! NOTE: Only meant for bottom boundary!!
c>    @todo Applying cooling rate of 0.25 Kh^{-1} on top of reference t_surf
      flux = thermal_flux(u_star, kappa, t_surf, t1_2, y1_2, y0, Psi_H)

      ! Alternatively
      !flux = thermal_flux_fixed(x)


      if (wmles_sgs_bc) then
#ifdef DEBUG
        if (iy > nlev_bc) then
          call exitti("iy exceeded allocated shape: ", iy)
        endif
#endif
        ! Save and later use it in gij_from_bc
        alpha_bc(ix, iy, iz, ie) = alpha
      endif

      ! Save u_star anyway for spatial_means
      u_star_bc(ix, 1, iz, ie) = u_star

      u_star_max = max(u_star, u_star_max)

      return
      end
c----------------------------------------------------------------------
c> Compute friction velocity
      real function friction_vel(uh, kappa, delta_z, z0, Psi_M)
      implicit none

      real uh
      real kappa
      real delta_z, z0
      real Psi_M

      friction_vel = (uh * kappa) / (log(delta_z / z0) - Psi_M)
      return
      end function
c----------------------------------------------------------------------
c> Complute thermal flux
c> @see Eq. 14 in Gadde et al. (2020) doi:10.1007/s10546-020-00570-5
      real function thermal_flux(
     &    u_star, kappa, T_surf, T, delta_z, z_os, Psi_H)
      implicit none

      real u_star
      real kappa
      real T_surf, T
      real delta_z, z_os
      real Psi_H

      thermal_flux = u_star * kappa * (T_surf - T) / (
     &  log(delta_z / z_os) - Psi_H
     &)
      return
      end function
c----------------------------------------------------------------------
c> Set thermal flux which varies along x, but is constant in time
      real function thermal_flux_fixed(x)
      implicit none

      real x
      real a,fl

      parameter(a=3.0)
      parameter(fl=0.0002)

      thermal_flux_fixed = -fl
      if((x.ge.1.).and.(x.le.(1.+a)))then
        thermal_flux_fixed = fl*(15.-a)/a
      endif
      end function
c----------------------------------------------------------------------
c> Set temperature dirichlet boundary conditions at bottom and top
c> boundaries
      real function temp_strat(t_surf, y, half_ymax)
      implicit none
      real t_surf
      real y, half_ymax

      if(y .lt. half_ymax) then
        temp_strat = t_surf
      elseif(y .gt. half_ymax) then
        temp_strat = t_surf + 4
      endif
      end function
c----------------------------------------------------------------------
c> Compute the K term in penalty forcing
c> @param y_coord mesh coordinate where the coefficient is evaluated
c> @param z0 roughness length
      real function abl_pen_k(y_coord, z0)
      implicit none

      real y_coord
      real z0
      ! @var avoid zero
      real y_nonzero

      y_nonzero = max(y_coord, 1e-14)  ! Avoid log(0)
      abl_pen_k = y_coord * log(y_nonzero / z0)

      return
      end function
c> @}
