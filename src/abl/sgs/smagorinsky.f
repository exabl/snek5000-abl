c-----------------------------------------------------------------------
c> Compute D^2, the grid spacing used in the DS sgs model.
c> @callgraph
      subroutine set_grid_spacing

      implicit none
      include 'SIZE'  ! nx1, ny1, nz1, nelev,
      include 'GEOM'  ! xm1, ym1, zm1
      include 'SGS'  ! dg2

      integer e, eg,ex,ey,ez
      integer n, i, j, k, im, ip, jm, jp, km, kp
      real di, dj, dk, ndim_inv

      ndim_inv = 1./ndim

      n = nx1*ny1*nz1*nelv
      call rone(dg2,n)
c     return               ! Comment this line for a non-trivial Delta defn
      do e=1,nelv

         do k=1,nz1
           km = max(1  ,k-1)
           kp = min(nz1,k+1)

           do j=1,ny1
             jm = max(1  ,j-1)
             jp = min(ny1,j+1)

             do i=1,nx1
               im = max(1  ,i-1)
               ip = min(nx1,i+1)

               di = (xm1(ip,j,k,e)-xm1(im,j,k,e))**2
     $            + (ym1(ip,j,k,e)-ym1(im,j,k,e))**2
     $            + (zm1(ip,j,k,e)-zm1(im,j,k,e))**2

               dj = (xm1(i,jp,k,e)-xm1(i,jm,k,e))**2
     $            + (ym1(i,jp,k,e)-ym1(i,jm,k,e))**2
     $            + (zm1(i,jp,k,e)-zm1(i,jm,k,e))**2

               dk = (xm1(i,j,kp,e)-xm1(i,j,km,e))**2
     $            + (ym1(i,j,kp,e)-ym1(i,j,km,e))**2
     $            + (zm1(i,j,kp,e)-zm1(i,j,km,e))**2
c               write(6,*) ip,im,jp,jm
               di = di/(ip-im)
               dj = dj/(jp-jm)
               dk = dk/(kp-km)
               dg2(i,j,k,e) = (di*dj*dk)**ndim_inv

             enddo
           enddo
         enddo
      enddo

      call dsavg(dg2)  ! average neighboring elements

      do e=1,nelv
        dg2_max(e) = maxval(dg2(:,:,:,e))
      enddo

#ifdef DEBUG
      if (nid.eq.0) print *, "set_grid_spacing :dg2_max =", dg2_max
      print *, "set_grid_spacing: rank =", nid,
     &     ",local max =", maxval(dg2),
     &     ",local min =", minval(dg2)
      if (nid.eq.0) then
        print *, "set_grid_spacing; lx1, ly1, lz1, lelv: ",
     &      lx1,ly1,lz1,lelv
        open(unit=5, file="set_grid_spacing.dat", form="unformatted")
        write(5) xm1
        write(5) ym1
        write(5) zm1
        write(5) dg2
        write(5) dg2_max
        close(5)
      endif
#endif

      return
      end
c-----------------------------------------------------------------------
c> Compute eddy viscosity using constant smagorinsky model
c> @callgraph
      subroutine eddy_visc(e)

      implicit none

      include 'SIZE'
      include 'GEOM'  ! ym1
      include 'INPUT'  ! param
      include 'SOLN'  ! vx
      include 'SGS'  ! ediff, sij, snrm, Cs
      include 'WMLES'  ! kappa, wmles_sgs_npow, y0

      integer e
      real C0, Csa, Csb, npow, delta_sq, y0
      integer i, ie, ntot

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
        npow = wmles_sgs_npow
        Csa = 1.0 / (C0 ** npow)

        do ie=1,nelv
          if (wmles_sgs_delta_max) delta_sq = dg2_max(ie)
          ntot = nx1*ny1*nz1*ie

          do i=1*ie,ntot
            if (.not. wmles_sgs_delta_max) delta_sq = dg2(i,1,1,1)

            Csb = (
     $        sqrt(delta_sq) / (kappa * (ym1(i,1,1,1) + y0))
     $      ) ** npow
            Cs(i,1) = (Csa + Csb) ** (-1/npow)

            ediff(i,1,1,1) = (
     $        param(2) + (Cs(i,1)**2) * delta_sq * snrm(i,1)
     $      )
          enddo
        enddo
      endif
c----------

      return
      end
