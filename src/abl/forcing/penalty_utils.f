c-----------------------------------------------------------------------
c> @brief Assuming the mesh is cartesian, compute exact y-derivative
c>        for an element, by operating
c>        \f[ \mathbf{u} D^T \f]
c> @ingroup penalty_mini
c> @callgraph
c> @param[out] us
c> @param[in] u,N,e,Dt
      subroutine local_cart_dy(us,u,N,e,Dt)
      implicit none
      real us(0:N,0:N,0:N)
      real u (0:N,0:N,0:N,1)
      real D (0:N,0:N),Dt(0:N,0:N)
      integer e, m1, N, k
c
      m1 = N+1
c
      do k=0,N
         call mxm(u(0,0,k,e),m1,Dt,m1,us(0,0,k),m1)
      enddo
c
      return
      end
c-----------------------------------------------------------------------
c> @brief Assuming the mesh is cartesian, compute pseudo(?) y-derivative
c>        along y-axis for an element, by operating
c>        \f[ Dt \mathbf{u} \f]
c> @ingroup penalty_mini
c> @callgraph
c> @param[out] us
c> @param[in] u,N,e,Dt
      subroutine local_cart_dy_pseudo(us,u,N,e,Dt)
      implicit none
      real us(0:N,0:N,0:N)
      real u (0:N,0:N,0:N,1)
      real D (0:N,0:N),Dt(0:N,0:N)
      integer e, m1, N, k
c
      m1 = N+1
c
      do k=0,N
         call mxm(Dt,m1,u(0,0,k,e),m1,us(0,0,k),m1)
      enddo
c
      return
      end
c-----------------------------------------------------------------------
      subroutine cart_diff_y(uy,u,ifexact)
c> @brief Compute exact / pseudo y-derivative in a Cartesian vel. mesh
c> @ingroup penalty_mini
c> @callgraph
c> @param[out] uy
c> @param[in] u
c> @param[in] ifexact  Compute exact or pseudo-derivative
      implicit none
      include 'SIZE'
      include 'DXYZ'
      include 'GEOM'
      include 'INPUT'
      include 'TSTEP'
c
      integer lxyz
      parameter (lxyz=lx1*ly1*lz1)
      real uy(lxyz,1),u(lxyz,1)
      logical ifexact

      real us(lxyz)
      common /ctmp1/ us

      integer e,i,nxyz,ntot,N

      nxyz = lx1*ly1*lz1
      ntot = nxyz*nelt

#ifdef DEBUG
      print *, "metric: r (min/max), ~0 = ", minval(rym1), maxval(rym1)
      print *, "metric: s (min/max)  !0 = ", minval(sym1), maxval(sym1)
      print *, "metric: t (min/max), ~0 = ", minval(tym1), maxval(tym1)
#endif
      N = lx1-1
      do e=1,nelt
         if (ifexact) then
            call local_cart_dy(us,u,N,e,dxtm1)
         else
            call local_cart_dy_pseudo(us,u,N,e,dxtm1)
         endif
         do i=1,lxyz
            uy(i,e) = jacmi(i,e)*us(i)*sym1(i,1,1,e)
         enddo
      enddo
c
      return
      end
