c> @defgroup bc_noslip No-slip Dirichlet boundary condition
c> @{
!-----------------------------------------------------------------------
c> No slip and no penetration condition
      subroutine abl_userbc(ix,iy,iz,iside,eg)
      implicit none

      include 'SIZE'
      ! include 'GEOM'  ! ym1
      include 'NEKUSE'  ! ux, uy, uz, temp, x, y
      ! include 'SOLN'  ! vx, vz
      ! include 'PARALLEL'  ! gllel
      ! include 'SGS'  ! du_dy
      ! include 'SGS_BC'  ! u_star_bc, u_star_max
      ! include 'WMLES'  ! kappa, wmles_bc_z_index

      integer ix, iy, iz, iside, eg
      real idx, y0, ie, y1_2, u1_2, w1_2, uh, u_star

      ux =  0.0
      uy =  0.0
      uz =  0.0

c>    @todo Why does u_star -> NaN?
      !! Only for statistics: compute u_star assuming log-law

      ! idx = wmles_bc_z_index
      ! y0 = wmles_bc_z0
      ! ie = gllel(eg)
      ! y1_2 = (ym1(ix, idx+1, iz, ie) + ym1(ix, idx, iz, ie))/2
      ! ! u_star = kappa * y1_2 * du_dy(ix, iy, iz, ie)

      ! u1_2 = (vx(ix, idx+1, iz, ie) + vx(ix, idx, iz, ie))/2
      ! w1_2 = (vz(ix, idx+1, iz, ie) + vz(ix, idx, iz, ie))/2

      ! uh = sqrt(u1_2**2 + w1_2**2)
      ! u_star = (uh * kappa) / log(y1_2 / y0)

      !! Save u_star for spatial_means

      ! u_star_bc(ix, iy, iz, ie) = u_star
      ! u_star_max = max(u_star, u_star_max)

      return
      end
!-----------------------------------------------------------------------
c> Compute the K term in penalty forcing
c> @param y_coord mesh coordinate where the coefficient is evaluated
c> @param z0 roughness length
c> @note Be careful in specifying the penalty region, should be away
c> from the wall
      real function abl_pen_k(y_coord, z0)
      implicit none

      real y_coord
      real z0
      real y_nonzero

      y_nonzero = max(y_coord, 1e-14)  ! Avoid log(0)
      abl_pen_k = y_coord * log(y_nonzero / z0)

      return
      end function
c> @}
