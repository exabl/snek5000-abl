c-----------------------------------------------------------------------
c> Compute eddy viscosity using constant smagorinsky model
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
      real C0, Csa, Csb, Cs, npow, delta_sq, y0
      integer i, ie, ntot, istart, iend

      ntot = nx1*ny1*nz1
c------need to be by element ->
      call comp_gije(sij, vx(1,1,1,e), vy(1,1,1,e), vz(1,1,1,e), e)
      ! Set gradient to match boundary condition
      if (wmles_sgs_bc) call gij_from_bc(sij, e)

      call comp_sije(sij)

      call mag_tensor_e(snrm(1,e), sij)
      call cmult(snrm(1,e), 2.0, ntot)
c---------------------------

c------now do for every GLL point
      if (e.eq.nelv) then
        y0 = wmles_bc_z0
        C0 = wmles_sgs_c0
        npow = wmles_sgs_npow
        Csa = 1.0 / (C0 ** npow)

        do ie=1,nelv
          if (wmles_sgs_delta_max) delta_sq = dg2_max(ie)

          istart = ntot * (ie-1) + 1
          iend = ntot * ie

          do i=istart,iend
            if (.not. wmles_sgs_delta_max) delta_sq = dg2(i,1,1,1)

            Csb = (
     $        sqrt(delta_sq) / (kappa * (ym1(i,1,1,1) + y0))
     $      ) ** npow
            Cs = (Csa + Csb) ** (-1/npow)

            ediff(i,1,1,1) = (
     $        param(2) + (Cs**2) * delta_sq * snrm(i,1)
     $      )
          enddo
        enddo
      endif
c----------

      return
      end
