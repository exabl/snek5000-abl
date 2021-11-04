c-----------------------------------------------------------------------
c> Stress boundary condition as formulated by Moeng (1984)
c> Also has optional temporal filtering c.f: Yang et al. Physical Review
c>      Fluids 2, no. 10 (2017): 104601.
c>      https://doi.org/10.1103/PhysRevFluids.2.104601.
c>
c> @note Boundary condition evaluated at higher nodes, may need to be corrected for Ekmann turning
c> @note This subroutine MAY NOT be called by every process
      subroutine abl_userbc(ix,iy,iz,iside,eg) ! set up boundary conditions
      implicit none


      integer ix, iy, iz, iside, eg, ie, idx
      real u1_2, w1_2, y1_2, y0, uh, u_star, alpha
      real eps, Tf
      real t1_2, t_surf
      real thermal_flux
      parameter(t_surf=0.0)

      include 'SIZE'
      include 'NEKUSE'  ! trx, try, trz, temp
      include 'PARALLEL'  ! gllel
      include 'SOLN'  ! vx, vz, t
      include 'GEOM'  ! ym1
      include 'TSTEP'  ! istep
      include 'SGS'  ! dg2_max
      include 'SGS_BC'  ! u_star_bc, alpha_bc, u_star_max
      include 'WMLES'  ! KAPPA, wmles_bc_z_index, wmles_bc_z0, wmles_bc_temp_filt, u_wm, w_wm


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

        !TODO: t_wm: temporal filtering for temperature

        ! Save it for next time step
        u_wm(ix, iz, ie) = u1_2
        w_wm(ix, iz, ie) = w1_2
      endif

      y1_2=(ym1(ix, idx+1, iz, ie) + ym1(ix, idx, iz, ie))/2

      uh = sqrt(u1_2**2 + w1_2**2)
      u_star = (uh * kappa) / log(y1_2 / y0)
      alpha = atan2(w1_2, u1_2)

c--------Calculate Stresses
      trx = -(u_star ** 2) * cos(alpha)
      try = 0.0
      trz = -(u_star ** 2) * sin(alpha)

c--------Calculate Thermal boundary condition
      ! temp = 0.0
      ! TODO: Allow y0 != z_os (thermal surface roughness length)
      ! NOTE: Only meant for bottom boundary!!
      flux = thermal_flux(u_star, kappa, t_surf, t1_2, y1_2, y0)


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
c> Complute thermal flux
c> @see Eq. 14 in Gadde et al. (2020) doi:10.1007/s10546-020-00570-5
c> @todo Correction for stratification
      real function thermal_flux(u_star,kappa,T_surf,T,delta_z,z_os)
      implicit none

      real u_star
      real kappa
      real T_surf, T
      real delta_z, z_os

      thermal_flux = u_star * kappa * (T_surf - T) / (
     &  log(0.5 * delta_z / z_os)
     &)
      return
      end function
c----------------------------------------------------------------------
c> Compute the K term in penalty forcing
      real function abl_pen_k(y_coord, z0)
      implicit none

      real y_coord    !< @var mesh coordinate where the coefficient is evaluated
      real z0         !< @var roughness length
      real y_nonzero  !< @var avoid zero

      y_nonzero = max(y_coord, 1e-14)  ! Avoid log(0)
      abl_pen_k = y_coord * log(y_nonzero / z0)

      return
      end function
