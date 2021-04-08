c> Compute eddy viscosity using Prandtl's mixing length model
c> Ref: https://webspace.clarkson.edu/projects/fluidflow/public_html/courses/me639/downloads/32_Prandtl.pdf
c> @callgraph @callergraph
      subroutine eddy_visc(e)
      implicit none

      include 'SIZE'
      include 'GEOM'  ! ym1
      include 'INPUT' ! param, uparam
      include 'SGS'  ! ediff, du_dy
      include 'WMLES'  ! kappa

      integer e

      ! local variables
      integer ix, iy, iz
      real kappa0, y, y_wall, y_delta, l_mix, YLEN
      parameter(kappa0 = 0.09)

      YLEN = uparam(6)
      y_delta = kappa0 * YLEN / (2.0 * kappa)

      do iz=1, nz1
        do iy=1, ny1
          do ix=1, nx1
            y = ym1(ix, iy, iz, e)
            y_wall = min(y, YLEN - y)  ! shortest distance from bottom / top wall
            if (y_wall < y_delta) then
               l_mix = kappa * y_wall
            else
               l_mix = kappa0 * y_delta  ! constant mixing length
            endif
            ! print *, du_dy(ix, iy, iz, e)
            ediff(ix, iy, iz, e) = param(2) + (
     &        l_mix ** 2 *
     &        abs(du_dy(ix, iy, iz, e))
     &      )
          end do
        end do
      end do
      end subroutine
