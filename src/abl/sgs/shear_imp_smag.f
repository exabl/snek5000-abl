c-----------------------------------------------------------------------
c> Compute eddy viscosity using shear improved smagorinsky model
c>  Here is the key difference:
c>  - no wall damping is required
c>  - planar average of \f$|S_{ij}|\f$ is subtracted from \f$|S_{ij}|\f$
c>
c> Refer: Lévêque et al. Journal of Fluid Mechanics (2007): https://doi.org/10.1017/S0022112006003429.
c> @callgraph @callergraph
      subroutine eddy_visc(e)
      implicit none

      include 'SIZE'
      include 'GEOM'  ! ym1
      include 'INPUT'  ! param
      include 'SOLN'  ! vx
      include 'SGS'  ! ediff, sij, snrm, Cs, dg2, dg2_max
      include 'WMLES'  ! kappa, wmles_sgs_npow, y0

      integer e
      real C0, delta_sq, y0
      integer i, ie, istart, iend, ntot

      real snrm_planar_avg(lx1*ly1*lz1,lelv)
      common /smag_avg/ snrm_planar_avg

      ntot = nx1*ny1*nz1
c------need to be by element ->
      call comp_gije(sij, vx(1,1,1,e), vy(1,1,1,e), vz(1,1,1,e), e)

      call comp_sije(sij)

      call mag_tensor_e(snrm(1,e), sij)
      call cmult(snrm(1,e), 2.0, ntot)
c---------------------------

c------now do for every GLL point
      if (e.eq.nelv) then
        y0 = wmles_bc_z0
        C0 = wmles_sgs_c0
        call planar_avg_horiz(snrm_planar_avg, snrm)

        do ie=1,nelv
          if (wmles_sgs_delta_max) delta_sq = dg2_max(ie)

          istart = ntot * (ie-1) + 1
          iend = ntot * ie

          do i=istart,iend
            if (.not. wmles_sgs_delta_max) delta_sq = dg2(i,1,1,1)

            ediff(i,1,1,1) = (
     $        param(2) + (
     $          (C0**2) *
     $          delta_sq *
     $          max(snrm(i,1) - snrm_planar_avg(i,1), 0.)
     $        )
     $      )
          enddo
        enddo
      endif
c----------

      return
      end
