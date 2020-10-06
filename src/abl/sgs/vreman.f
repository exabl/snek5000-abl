c-----------------------------------------------------------------------
c> Compute eddy viscosity using Vreman model
c>  Here is the key difference:
c>  - no wall damping is required
c>  - algebraic, no dynamic procedure
c>
c> Refer: Vreman, A. W., Physics of Fluids (2004): https://doi.org/10.1063/1.1785131.
c> @callgraph @callergraph
      subroutine eddy_visc(e)
      implicit none

      include 'SIZE'
      include 'INPUT'  ! param
      include 'SOLN'  ! vx
      include 'SGS'  ! ediff, sij, snrm, dg2, dg2_max
      include 'WMLES'  ! wmles_sgs_C0, wmles_sgs_delta_max

      integer e
      real C_vreman, delta_sq, alpha_sq
      integer i, j, k, ntot

      real alpha(ldim, ldim), beta(ldim, ldim)
      common /vreman/ alpha, beta

      ntot = nx1*ny1*nz1

c------need to be by element ->
      call comp_gije(sij, vx(1,1,1,e), vy(1,1,1,e), vz(1,1,1,e), e)

      C_vreman = 2.5 * wmles_sgs_c0**2

      if (wmles_sgs_delta_max) delta_sq = dg2_max(e)

      do i=1, ntot
        if (.not. wmles_sgs_delta_max) delta_sq = dg2(i,1,1,e)

        !> \f$ \alpha_{ij} \f$ (gradient tensor)
        !! @fixme Use Fortran slicing syntax
        ! alpha(:, :) = sij(i, :, :)
        ! alpha(1:ldim, 1:ldim) = sij(i, 1:ldim, 1:ldim)
        do k=1,ldim
          do j=1,ldim
            alpha(j, k) = sij(i, j, k)
          end do
        end do

        !> \f$ \beta_{ij} = \Delta^2 * \alpha_{mi} \alpha{mj} \f$
        !> Using BLAS subroutine dgemm
        !> See: https://www.netlib.org/lapack/explore-html/d1/d54/group__double__blas__level3_gaeda3cbd99c8fb834a60a6412878226e1.html

        !    call dgemm(
        ! &       'T', 'N',  ! first matrix should be transposed, second is normal
        ! &       ldim, ldim, ldim, delta_sq,
        ! &       alpha, ldim,  ! first matrix (A)
        ! &       alpha, ldim,  ! second matrix (B)
        ! &       0., beta, ldim  ! result matrix (C)
        ! &  )

        !> Alternatively:
        beta = delta_sq * matmul(transpose(alpha), alpha)

        !> Note \f$ B_\beta \f$ is being stored in snrm here
        snrm(i, e) = (
     &      beta(1,1) * beta(2,2)
     &    - beta(1,2)**2  ! check 
     &    + beta(1,1) * beta(3,3)
     &    - beta(1,3)**2  ! check
     &    + beta(2,2) * beta(3,3)
     &    - beta(2,3)**2  ! check
     &  )

        !> alpha_sq = \f$ \alpha_{ij} \alpha_{ij} \f$
        !    alpha_sq = 0.
        !    do j=1, ldim
        !        alpha_sq = alpha_sq + (
        ! &          dot_product(alpha(:, j), alpha(:, j))
        ! &      )
        !    end do

        !> Alternatively
        !> alpha_sq = \f$ trace(\alpha^T \alpha) \f$
        alpha_sq = (beta(1,1) + beta(2,2) + beta(3,3)) / delta_sq

c---------------------------
        ! Finally compute viscosity
        if (alpha_sq .eq. 0.) then
            ediff(i,1,1,e) = param(2)
        else
            ediff(i,1,1,e) = (
     &        param(2) + (
     &          C_vreman * sqrt(max(snrm(i, e), 0.) / alpha_sq)
     &        )
     &      )
        end if
      end do

c------now do for every GLL point
      ! if (e.eq.nelv) then
          ! do i=1,ntot*nelv
          ! end do
      ! end if
c----------

      return
      end
