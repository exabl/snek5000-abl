c-----------------------------------------------------------------------
c> Compute \f$\Delta^2\f$, the grid spacing used in a SGS model.
c> @callgraph @callergraph
      subroutine set_grid_spacing
      implicit none

      include 'SIZE'  ! nx1, ny1, nz1, nelev,
      include 'GEOM'  ! xm1, ym1, zm1
      include 'SGS'  ! dg2

      integer e
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
c> Setup test filter
c> @callgraph @callergraph
      subroutine set_ds_filt(fh,fht,nt,diag,nx)
      implicit none

      INCLUDE 'SIZE'

      integer nt, nx
      real fh(nx*nx),fht(nx*nx),diag(nx)

c Construct transfer function
      call rone(diag,nx)

c      diag(nx-0) = 0.01
c      diag(nx-1) = 0.10
c      diag(nx-2) = 0.50
c      diag(nx-3) = 0.90
c      diag(nx-4) = 0.99
c      nt = nx - 2

      diag(nx-0) = 0.05
      diag(nx-1) = 0.50
      diag(nx-2) = 0.95
      nt = nx - 1

      call build_1d_filt(fh,fht,diag,nx,nid)

      return
      end
c-----------------------------------------------------------------------
c> @callgraph @callergraph
      subroutine planar_average_r(ua,u,w1,w2)
      implicit none

c
c     Compute s-t planar average of quantity u()
c
      include 'SIZE'
      include 'GEOM'
      include 'PARALLEL'
      include 'WZ'
      include 'ZPER'
c
      real ua(nx1,lelx),u(nx1,ny1,nx1,nelv),w1(nx1,lelx),w2(nx1,lelx)
      integer e, eg, ex, ey, ez, i, j, k, nx
      real zz, aa
c
      nx = nx1*nelx
      call rzero(ua,nx)
      call rzero(w1,nx)
c
      do e=1,nelt
c
         eg = lglel(e)
         call get_exyz(ex,ey,ez,eg,nelx,nely,nelz)
c
         do i=1,nx1
         do k=1,nz1
         do j=1,ny1
            zz = (1.-zgm1(i,1))/2.  ! = 1 for i=1, = 0 for k=nx1
            aa = zz*area(j,k,4,e) + (1-zz)*area(j,k,2,e)  ! wgtd jacobian
            w1(i,ex) = w1(i,ex) + aa
            ua(i,ex) = ua(i,ex) + aa*u(i,j,k,e)
         enddo
         enddo
         enddo
      enddo
c
      call gop(ua,w2,'+  ',nx)
      call gop(w1,w2,'+  ',nx)
c
      do i=1,nx
         ua(i,1) = ua(i,1) / w1(i,1)   ! Normalize
      enddo
c
      return
      end
c-----------------------------------------------------------------------
c> @callgraph @callergraph
      subroutine planar_average_s(ua,u,w1,w2)
      implicit none

c
c     Compute r-t planar average of quantity u()
c
      include 'SIZE'
      include 'GEOM'
      include 'PARALLEL'
      include 'WZ'
      include 'ZPER'
c
      real ua(ny1,nely),u(nx1,ny1,nx1,nelv),w1(ny1,nely),w2(ny1,nely)
      integer e, eg, ex, ey, ez, i, j, k, ny
      real zz, aa
c
      ny = ny1*nely
      call rzero(ua,ny)
      call rzero(w1,ny)
c
      do e=1,nelt
         eg = lglel(e)
         call get_exyz(ex,ey,ez,eg,nelx,nely,nelz)
c
         do k=1,nz1
         do j=1,ny1
         do i=1,nx1
            zz = (1.-zgm1(j,2))/2.  ! = 1 for i=1, = 0 for k=nx1
            aa = zz*area(i,k,1,e) + (1-zz)*area(i,k,3,e)  ! wgtd jacobian
            w1(j,ey) = w1(j,ey) + aa
            ua(j,ey) = ua(j,ey) + aa*u(i,j,k,e)
         enddo
         enddo
         enddo
      enddo
c
      call gop(ua,w2,'+  ',ny)
      call gop(w1,w2,'+  ',ny)
c
      do i=1,ny
         ua(i,1) = ua(i,1) / w1(i,1)   ! Normalize
      enddo

      return
      end
c-----------------------------------------------------------------------
c> @callgraph @callergraph
      subroutine planar_fill_s(u,ua)
      implicit none

c
c     Fill array u with planar values from ua().
c     For tensor-product array of spectral elements
c
      include 'SIZE'
      include 'GEOM'
      include 'PARALLEL'
      include 'WZ'
      include 'ZPER'


      real u(nx1,ny1,nz1,nelv),ua(ly1,lely)

      integer e, eg, ex, ey, ez, melxyz, i, j, k

      melxyz = nelx*nely*nelz
      if (melxyz.ne.nelgt) then
         write(6,*) nid,' Error in planar_fill_s'
     $                 ,nelgt,melxyz,nelx,nely,nelz
         call exitt
      endif

      do e=1,nelt
         eg = lglel(e)
         call get_exyz(ex,ey,ez,eg,nelx,nely,nelz)

         do j=1,ny1
         do k=1,nz1
         do i=1,nx1
            u(i,j,k,e) = ua(j,ey)
         enddo
         enddo
         enddo

      enddo

      return
      end
c-----------------------------------------------------------------------
c> @callgraph @callergraph
      subroutine wall_normal_average_s(u,ny,nel,v,w)
      implicit none

      integer nel, ny
      real u(ny,nel),w(1),v(1)

      ! Local variables
      integer e, i, k, n, ipass, npass
      real alpha

      k=0
      do e=1,nel    ! get rid of duplicated (ny,e),(1,e+1) points
      do i=1,ny-1
         k=k+1
         w(k) = u(i,e)
      enddo
      enddo
      k=k+1
      w(k) = u(ny,nel)
      n=k

      npass = 2     ! Smooth
      alpha = 0.2

      do ipass=1,npass
         do k=2,n-1
            v(k) = (1.-alpha)*w(k) + 0.5*alpha*(w(k-1)+w(k+1))
         enddo

         do k=1,n
            w(k) = v(k)
         enddo
      enddo

      k=0
      do e=1,nel    ! restore duplicated (ny,e),(1,e+1) points
         do i=1,ny-1
            k=k+1
            u(i,e) = w(k)
         enddo
      enddo
      k=k+1
      u(ny,nel)=w(k)

      do e=1,nel-1    ! restore duplicated (ny,e),(1,e+1) points
         u(ny,e) = u(1,e+1)
      enddo
      return
      end
c-----------------------------------------------------------------------
