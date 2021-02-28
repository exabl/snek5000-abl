c> Compute eddy viscosity using Prandtl's mixing length model
c> Ref: https://webspace.clarkson.edu/projects/fluidflow/public_html/courses/me639/downloads/32_Prandtl.pdf
c> @callgraph @callergraph
      subroutine eddy_visc(e)
      implicit none

      include 'SIZE'
      include 'GEOM'  ! ym1
      include 'INPUT' ! param
      include 'PENALTY'  ! du_dy
      include 'SGS'  ! ediff
      include 'WMLES'  ! kappa

      integer e

      integer ix, iy, iz

      do iz=1, nz1
        do iy=1, ny1
          do ix=1, nx1
            ediff(ix, iy, iz, e) = param(2) + (
     &        (kappa * ym1(ix, iy, iz, e)) ** 2 *
     &        abs(du_dy(ix, iy, iz, e))
     &      )
          end do
        end do
      end do
      
      !  ediff(:nx1,:ny1,:nz1,e) = param(2) + (
      ! &  (kappa * ym1(:nx1,:ny1,:nz1,e))**2 *
      ! &  abs(du_dy(:nx1,:ny1,:nz1,e))
      ! &)
      
      end subroutine
