c-----------------------------------------------------------------------
c> Compute eddy viscosity using dynamic smagorinsky model
c> @callgraph @callergraph
      subroutine eddy_visc(e)
      implicit none

      include 'SIZE'
      include 'SOLN'  ! vx, vy, vz
      include 'INPUT'  ! param
      include 'SGS'  ! ediff, sij, snrm
      include 'DYN'  ! lxyz, mij, lij, num, den
      include 'WMLES'  ! wmles_sgs_delta_max

      integer e
      real beta1, beta2, Cs, delta_sq


      real ur (lxyz) , us (lxyz) , ut (lxyz)
     $   , vr (lxyz) , vs (lxyz) , vt (lxyz)
     $   , wr (lxyz) , ws (lxyz) , wt (lxyz)
      real w1(lx1*lelv), w2(lx1*lelv)
      common /xzmp0/ ur, us, ut
      common /xzmp1/ w1, w2

      !! NOTE CAREFUL USE OF EQUIVALENCE HERE !!
      equivalence (vr,lij(1,1)),(vs,lij(1,2)),(vt,lij(1,3))
     $          , (wr,lij(1,4)),(ws,lij(1,5)),(wt,lij(1,6))


      integer nt, i, ie, istart, iend, j, ntot
      save    nt
      data    nt / -9 /

      ntot = nx1*ny1*nz1

      if (nt.lt.0) call
     $   set_ds_filt(fh,fht,nt,diag,nx1)! dyn. Smagorinsky filter

      call comp_gije(sij,vx(1,1,1,e),vy(1,1,1,e),vz(1,1,1,e),e)
      ! Set gradient to match boundary condition
      if (wmles_sgs_bc) call gij_from_bc(sij, e)
      ! Compute symmetric part of the strain tensor
      call comp_sije(sij)

      call mag_tensor_e(snrm(1,e),sij)
      call cmult(snrm(1,e),2.0,ntot)

      ! Cross and Leonard stress
      call comp_mij(ur,us,nt,e)
      call comp_lij(vx,vy,vz,ur,us,ut,e)

#ifdef DEBUG
      ! For statistics
      do j=1,6
        do i=1,ntot
           mij_global(j,i,e) = mij(i,j)
           lij_global(j,i,e) = lij(i,j)
        end do
      end do
#endif

c     Compute numerator (ur) & denominator (us) for Lilly contraction

      do i=1,ntot
         ur(i) = mij(i,1)*lij(i,1)+mij(i,2)*lij(i,2)+mij(i,3)*lij(i,3)
     $      + 2*(mij(i,4)*lij(i,4)+mij(i,5)*lij(i,5)+mij(i,6)*lij(i,6))
         us(i) = mij(i,1)*mij(i,1)+mij(i,2)*mij(i,2)+mij(i,3)*mij(i,3)
     $      + 2*(mij(i,4)*mij(i,4)+mij(i,5)*mij(i,5)+mij(i,6)*mij(i,6))
      enddo

c     smoothing numerator and denominator in time
      call copy (vr,ur,nx1*nx1*nx1)
      call copy (vs,us,nx1*nx1*nx1)

      beta1 = 0.0                   ! Temporal averaging coefficients
      ! NOTE: disabled temporal filtering here
      ! if (istep.gt.1) beta1 = 0.9   ! Retain 90 percent of past
      beta2 = 1. - beta1

      do i=1,ntot
         num (i,e) = beta1*num(i,e) + beta2*vr(i)
         den (i,e) = beta1*den(i,e) + beta2*vs(i)
      enddo


      if (e.eq.nelv) then  ! planar avg and define nu_tau

         call dsavg(num)   ! average across element boundaries
         call dsavg(den)

         call planar_avg_horiz(num, num)
         call planar_avg_horiz(den, den)

         do ie=1,nelv
           if (wmles_sgs_delta_max) delta_sq = dg2_max(ie)

           istart = ntot * (ie-1) + 1
           iend = ntot * ie

           do i=istart,iend
             if (.not. wmles_sgs_delta_max) delta_sq = dg2(i,1,1,1)

             Cs = 0.
             if (den(i,1).gt.0) Cs = 0.5*num(i,1)/den(i,1)
             Cs = max(Cs, 0.)   ! AS ALTERNATIVE, could clip ediff

             ediff(i,1,1,1) = (
     $         param(2) + Cs * delta_sq * snrm(i,1)
     $       )
           enddo
         enddo
      endif

c     if (e.eq.nelv) call outpost(num,den,snrm,den,ediff,'dif')
c     if (e.eq.nelv) call exitt

      return
      end
c-----------------------------------------------------------------------
c> Compute \f$\mathcal{L}\f$ for dynamic Smagorinsky model:
c> \f[
c>      L_{ij} := {\bar{u}_i} {\bar{u}_j} - \overline{u_i u_j}
c> \f]
c> @callgraph @callergraph
      subroutine comp_lij(u,v,w,fu,fv,fw,e)
      implicit none

      include 'SIZE'
      include 'DYN'  ! lij, fh, fht
c
      integer e
c
      real u(lxyz, lelv)
      real v(lxyz, lelv)
      real w(lxyz, lelv)
      real fu(lxyz), fv(lxyz), fw(lxyz)

      integer i, n

      call tens3d1(fu,u(1,e),fh,fht,nx1,nx1)  ! fh x fh x fh x u
      call tens3d1(fv,v(1,e),fh,fht,nx1,nx1)
      call tens3d1(fw,w(1,e),fh,fht,nx1,nx1)

      n = nx1*ny1*nz1
      do i=1,n
         lij(i,1) = fu(i)*fu(i)
         lij(i,2) = fv(i)*fv(i)
         lij(i,3) = fw(i)*fw(i)
         lij(i,4) = fu(i)*fv(i)
         lij(i,5) = fv(i)*fw(i)
         lij(i,6) = fw(i)*fu(i)
      enddo

      call col3   (fu,u(1,e),u(1,e),n)    !  _______
      call tens3d1(fv,fu,fh,fht,nx1,nx1)  !  u_1 u_1
      call sub2   (lij(1,1),fv,n)

      call col3   (fu,v(1,e),v(1,e),n)    !  _______
      call tens3d1(fv,fu,fh,fht,nx1,nx1)  !  u_2 u_2
      call sub2   (lij(1,2),fv,n)

      call col3   (fu,w(1,e),w(1,e),n)    !  _______
      call tens3d1(fv,fu,fh,fht,nx1,nx1)  !  u_3 u_3
      call sub2   (lij(1,3),fv,n)

      call col3   (fu,u(1,e),v(1,e),n)    !  _______
      call tens3d1(fv,fu,fh,fht,nx1,nx1)  !  u_1 u_2
      call sub2   (lij(1,4),fv,n)

      call col3   (fu,v(1,e),w(1,e),n)    !  _______
      call tens3d1(fv,fu,fh,fht,nx1,nx1)   !  u_2 u_3
      call sub2   (lij(1,5),fv,n)

      call col3   (fu,w(1,e),u(1,e),n)    !  _______
      call tens3d1(fv,fu,fh,fht,nx1,nx1)  !  u_3 u_1
      call sub2   (lij(1,6),fv,n)

      return
      end
c-----------------------------------------------------------------------
c> Compute \f$\mathcal{M}\f$ for dynamic Smagorinsky model:
c> \f[
c>     M_{ij}  :=  a^2  \bar{S} \bar{S}_{ij} -\overline{S S_{ij}}
c> \f]
c> @callgraph @callergraph
      subroutine comp_mij(fs,fi,nt,e)
      implicit none

      include 'SIZE'
      include 'SGS'  ! sij, dg2
      include 'DYN'  ! mij, fh, fht
      include 'WMLES'  ! wmles_sgs_delta_max
c
      integer nt, e
      real fs(lxyz), fi(lxyz)

      integer a2, i, j, k, n, sym
      real magS(lxyz), delta_sq

      integer sym_map(3,3)
      sym_map = reshape((/1, 4, 6, 4, 2, 5, 6, 5, 3/), shape=(/3,3/))

      ! Map 3x3-symmetric-tensor to be stored in a 6-element array
      ! 1 4 6
      ! 4 2 5
      ! 6 5 3

      n = nx1*ny1*nz1

      call mag_tensor_e(magS,sij)
      call cmult(magS,2.0,n)

c     Filter S
      call tens3d1(fs,magS,fh,fht,nx1,nx1)  ! fh x fh x fh x |S|

c     a2 is the test- to grid-filter ratio, squared

      a2 = nx1-1       ! nx1-1 is number of spaces in grid
      a2 = a2 /(nt-1)  ! nt-1 is number of spaces in filtered grid

      if (wmles_sgs_delta_max) delta_sq = dg2_max(e)

      do k=1,3
        do j=1,k
         sym = sym_map(j, k)

         call col3(fi, magS, sij(:,j,k), n)  ! TODO: fix imap and for our 3D sij
         call tens3d1(mij(1,sym), fi, fh, fht, nx1, nx1)  ! fh x fh x fh x (|S| S_ij)
         call tens3d1(fi, sij(:,j,k), fh, fht, nx1, nx1)  ! fh x fh x fh x S_ij
         do i=1,n
            if (.not. wmles_sgs_delta_max) delta_sq = dg2(i*e,1,1,1)

            mij(i, sym) = (a2**2 * fs(i)*fi(i) - mij(i, sym))*delta_sq
         enddo
        enddo
        enddo

      return
      end
c-----------------------------------------------------------------------
      subroutine stat_compute_extras(alpha, beta)
      implicit none

      include 'SIZE'
      include 'STATD'
      include 'SGS'  ! snrm
      include 'DYN'  ! lij, mij

      ! local variables
      integer j
      integer npos              ! position in STAT_RUAVG
      real alpha, beta          ! time averaging parameters
      integer lnvar             ! count number of variables

      ! saved number of variables, by stat_compute
      lnvar = stat_nvar

!=======================================================================
      ! Computation of extra statistics
!-----------------------------------------------------------------------
      ! <num>t
      lnvar = lnvar + 1
      npos = lnvar
      call stat_compute_1Dav1(num(1,1),npos,alpha,beta)
!-----------------------------------------------------------------------
      ! <den>t
      lnvar = lnvar + 1
      npos = lnvar
      call stat_compute_1Dav1(den(1,1),npos,alpha,beta)
!-----------------------------------------------------------------------
#ifdef DEBUG
      ! <L_ij>t
      do j=1,6
        lnvar = lnvar + 1
        npos = lnvar
        call stat_compute_1Dav1(lij_global(j,1,1),npos,alpha,beta)
      end do
!-----------------------------------------------------------------------
      ! <M_ij>t
      do j=1,6
        lnvar = lnvar + 1
        npos = lnvar
        call stat_compute_1Dav1(mij_global(j,1,1),npos,alpha,beta)
      end do
#endif
!=======================================================================
      ! End of extra statistics compute

      ! save number of variables
      stat_nvar = lnvar

      return
      end subroutine
c-----------------------------------------------------------------------
