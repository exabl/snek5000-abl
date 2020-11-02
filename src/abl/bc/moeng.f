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
      real u1_2, w1_2, y1_2, y0, uh, ustar, alpha
      real eps, Tf

      include 'SIZE'
      include 'NEKUSE'  ! trx, try, trz, temp
      include 'PARALLEL'  ! gllel
      include 'SOLN'  ! vx, vz
      include 'GEOM'  ! ym1
      include 'TSTEP'  ! istep
      include 'SGS'  ! dg2_max
      include 'WMLES'  ! KAPPA, wmles_bc_z_index, wmles_bc_z0, wmles_bc_temp_filt, u_wm, w_wm


c      if (cbc(iside,gllel(eg),ifield).eq.'v01')

      ! Use value from par file for index to sample velocities at and roughness parameter
      idx = wmles_bc_z_index
      y0 = wmles_bc_z0
c--------Calculate Moeng's model parameters
      ie=gllel(eg)

      u1_2=(vx(ix, idx+1, iz, ie) + vx(ix, idx, iz, ie))/2
      w1_2=(vz(ix, idx+1, iz, ie) + vz(ix, idx, iz, ie))/2

      if (wmles_bc_temp_filt) then
        if (istep .le . 5) then
          eps = 1.
        else
          Tf = 5. * sqrt(dg2_max(ie)) / u1_2
          eps = dt / Tf
        endif

#ifdef DEBUG
        print*, "userbc: temporal filtering eps=", eps
#endif

        u1_2 = (1.-eps)*u_wm(ix, iz, ie) + eps*u1_2
        w1_2 = (1.-eps)*w_wm(ix, iz, ie) + eps*w1_2

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
      temp = 0.0

      return
      end
-----------------------------------------------------------------------
