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
      integer i, j, k, ie, istart, iend, ntot

      real sij_avg(lx1*ly1*lz1,lelv,ldim,ldim)
     &, sij_global(lx1*ly1*lz1,lelv,ldim,ldim)
     &,   snrm_avg(lx1*ly1*lz1)
      common /shear_imp/ sij_avg, sij_global, snrm_avg

      ntot = nx1*ny1*nz1
c------need to be by element ->
      call comp_gije(
     &   sij_global(:,e,:,:), vx(1,1,1,e), vy(1,1,1,e), vz(1,1,1,e), e)
      ! Set gradient to match boundary condition
      if (wmles_sgs_bc) call gij_from_bc(sij_global(:,e,:,:), e)
      call comp_sije(sij_global(:,e,:,:))

      call mag_tensor_e(snrm(1,e), sij_global(:,e,:,:))
      call cmult(snrm(1,e), 2.0, ntot)
c---------------------------

c------now do for every GLL point
      if (e.eq.nelv) then
        y0 = wmles_bc_z0
        C0 = wmles_sgs_c0
        do j=1,ldim
           do k=j,ldim
              call planar_avg_horiz(
     &           sij_avg(:,:,j,k), sij_global(:,:,j,k))

              call dsavg(sij_avg(:,:,j,k))   ! average across element boundaries

              if (j .ne. k) call copy(
     &           sij_avg(:,:,k,j), sij_avg(:,:,j,k),
     &           lx1*ly1*lz1*lelv)
           end do
        end do

        do ie=1,nelv
          if (wmles_sgs_delta_max) delta_sq = dg2_max(ie)

          istart = ntot * (ie-1) + 1
          iend = ntot * ie

          !> Compute norm of S_ij averaged
          call mag_tensor_e(snrm_avg, sij_avg(:,ie,:,:))
          call cmult(snrm_avg, 2.0, ntot)

          do i=istart,iend
            if (.not. wmles_sgs_delta_max) delta_sq = dg2(i,1,1,1)

            ediff(i,1,1,1) = (
     $        param(2) + (
     $          (C0**2) *
     $          delta_sq *
     $          max(snrm(i,1) - snrm_avg(1 + i - istart), 0.)
     $        )
     $      )
          enddo
        enddo
      endif
c----------

      return
      end
