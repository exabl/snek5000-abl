!=======================================================================
!> @brief Update penalty
!! @ingroup penalty_mini
      subroutine pen_update()
      implicit none

      include 'SIZE'
      include 'TSTEP'  ! istep
      include 'PENALTY'

      ! local variables
      real ltim

      ! functions
      real dnekclock
!-----------------------------------------------------------------------
      if (.not. pen_enabled) then
          ! Do nothing!
          return
      endif

      ! timing
      ltim = dnekclock()

      ! update random phases (time independent and time dependent)
      ! call pen_rphs_get

      ! update forcing terms
      call pen_fterms_get(.false.)

      ! timing
      ltim = dnekclock() - ltim
      call mntr_tmr_add(pen_tmr_id,1,ltim)

#ifdef DEBUG
      print *,  "pen_regions = ", pen_regions
      print *,  "pen_k_len (min/max) = ", minval(pen_k_len),
     &   maxval(pen_k_len)
      print *,  "pen_floglaw (min/max) = ", minval(pen_floglaw),
     &   maxval(pen_floglaw)
      print *,  "pen_fstab (min/max) = ", minval(pen_fstab),
     &   maxval(pen_fstab)
      print *,  "pen_fmask (min/max) = ", minval(pen_fmask),
     &   maxval(pen_fmask)
#endif
      return
      end subroutine
!=======================================================================
!> @brief Compute penalty forcing
!! @ingroup penalty_mini
!! @param[inout] ffx,ffy,ffz     forcing; x,y,z component
!! @param[in]    ix,iy,iz        GLL point index
!! @param[in]    ieg             global element number
!! @todo add ffy component and rotation
!! @callgraph @callergraph
      subroutine pen_forcing(ix,iy,iz,ieg)
      implicit none

      include 'SIZE'
      include 'PARALLEL'
      include 'MASS'    ! binvm1
      include 'NEKUSE'  ! ffx, ffz, ux, uz
      include 'SGS'     ! du_dy
      include 'PENALTY'

      ! argument list
      ! real ffx, ffy, ffz
      integer ix,iy,iz,ieg

      ! local variables
      integer ipos,iel,il
      real k_len
      real ffn
!-----------------------------------------------------------------------
      iel=GLLEL(ieg)

      ffn = 0.

      if (pen_enabled) then

         do il=1, pen_regions_max
           ! ipos = pen_map(ix,iy,iz,iel,il)
           ffn = ffn + (
     &          binvm1(ix, iy, iz, iel)  !  P^{-1}
     &          * pen_tiamp  !* pen_famp(ipos,il) *    ! sigma
     &          * (pen_floglaw(ix,iy,iz,iel,il)
     &             - pen_fstab(ix,iy,iz,iel,il))
     &     )
         enddo
      endif

#ifdef DEBUG
      ! print *, "Penalty ffn = ", ffn
#endif
      ffx = ffx + ffn

      return
      end subroutine
!=======================================================================
!> @brief Get 1D projection, array mapping and forcing smoothing
!! @ingroup penalty_mini
!! @details This routine is just a simple version supporting only lines
!!   paralles to z axis. In future it can be generalised.
!!   The subroutine initializes pen_prj, pen_map and pen_npoint
!! @see Schlatter and Örlü, “Turbulent Boundary Layers at Moderate Reynolds Numbers.”
!!   pg. 12
!! @remark This routine uses global scratch space \a CTMP0 and \a CTMP1
      subroutine pen_fmask_get()
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'GEOM'
      include 'PENALTY'

      ! local variables
      integer nxy, nxyz, ntot !< @var number of points in xy face of an element, whole element and whole mesh
      integer itmp, jtmp, ktmp, eltmp
      integer il, jl
      real xr, yr, zr !< @var coordinates
      real x_cen, y_cen, z_cen !< @var centers of the region
      real x_len, y_len, z_len  !@ var half extents of the region
      real rtmp !< @var temporary variable: distance**2 from starting position (pen_spos)

!-----------------------------------------------------------------------
      nxy = NX1*NY1
      nxyz = nxy*NZ1
      ntot = nxyz*NELV

      call rzero(pen_fmask, ntot*pen_regions)

      ! for each region
      do il=1,pen_regions
      ! Get coordinates and sort them

         ! define masks / extraction functions where penalty should be
         ! imposed
         x_len = (pen_epos(1,il) - pen_spos(1,il)) * 0.5
         y_len = (pen_epos(2,il) - pen_spos(2,il)) * 0.5
         x_cen = (pen_epos(1,il) + pen_spos(1,il)) * 0.5
         y_cen = (pen_epos(2,il) + pen_spos(2,il)) * 0.5
         if (IF3D) then
            z_len = (pen_epos(3,il) - pen_spos(3,il)) * 0.5
            z_cen = (pen_epos(3,il) + pen_spos(3,il)) * 0.5
         endif

         do jl=1,ntot
            itmp = jl-1
            eltmp = itmp/nxyz + 1
            itmp = itmp - nxyz*(eltmp-1)
            ktmp = itmp/nxy + 1
            itmp = itmp - nxy*(ktmp-1)
            jtmp = itmp/nx1 + 1
            itmp = itmp - nx1*(jtmp-1) + 1

            ! calculate distances, normalized
            ! NOTE: xr and zr are commented for now
            ! xr = (xm1(itmp,jtmp,ktmp,eltmp) - x_cen) / x_len
            yr = (ym1(itmp,jtmp,ktmp,eltmp) - y_cen) / y_len

            ! if (IF3D) then
            !    zr = (zm1(itmp,jtmp,ktmp,eltmp) - z_cen) / z_len
            ! endif

            ! For isolated 3D masks
            !         rtmp = xr**2 + yr**2 + zr**2
            !         rtmp = (
            !  &          (xr*pen_ismth(1,il))**2
            !  &        + (yr*pen_ismth(2,il))**2
            !  &        + (zr*pen_ismth(3,il))**2 )

            ! Distance along y
            rtmp = abs(yr * pen_ismth(2, il))

            ! Delta function masking. NOTE: not smooth
            if (rtmp > 1.0) then
               pen_fmask(itmp,jtmp,ktmp,eltmp,il) = 0.0
            else
               pen_fmask(itmp,jtmp,ktmp,eltmp,il) = 1.0
            endif
         enddo
      enddo

      return
      end subroutine
!=======================================================================
!> @brief Generate forcing terms: pen_k_len and pen_fstab
!! @details This used to also initializes the pen_famp array. This was to allow for
!!    spatio-temporally varying forcing, which has been removed in this version.
!! @ingroup penalty_mini
!! @param[in] ifreset    reset flag to reinitialize geometry term pen_k_len
!! @callgraph @callergraph
      subroutine pen_fterms_get(ifreset)
      implicit none

      include 'SIZE'
      ! include 'INPUT'
      include 'GEOM'  ! ym1
      ! include 'TSTEP'
      include 'PENALTY'
      include 'SOLN'   ! vx
      include 'SGS'    ! du_dy
      include 'WMLES'  ! wmles_bc_z0

      ! argument list
      logical ifreset

      ! function defined in boundary condition module
      real abl_pen_k
      external abl_pen_k

      ! local variables
      integer il, jl, kl, ll
      integer istart

      real loglaw_err(lx1,ly1,lz1,lelv)
      common /ctmp0/ loglaw_err

!-----------------------------------------------------------------------
      ! reset all
      if (ifreset) then

         ! compute K array
         print *, "Computing penalty K array"
         do ll=1, nelv
            do kl=1, nz1
               do jl=1, ny1
                  do il=1, nx1
                     pen_k_len(il, jl, kl, ll) = (
     &                  abl_pen_k(ym1(il, jl, kl, ll), wmles_bc_z0)
     &               )
                  enddo
               enddo
            enddo
        enddo
        !    pen_k_len(:nx1,:ny1,:nz1,:nelv) = (
        ! &       ym1(:nx1,:ny1,:nz1,:nelv) * log(
        ! &          ym1(:nx1,:ny1,:nz1,:nelv) / wmles_bc_z0
        ! &       )
        ! &   )
      ! else
         ! reset only time dependent part if needed

         ! space dependent amplitude: disabled

      endif
      ! time dependent amplitude: disabled

!-----------------------------------------------------------------------

      ! Compute the forcing terms
      loglaw_err = (vx - pen_k_len * du_dy)

      do il=1,pen_regions

         ! compute log law term: pen_floglaw
         pen_floglaw(:nx1,:ny1,:nz1,:nelv,il) = (
     &      pen_fmask(:nx1,:ny1,:nz1,:nelv,il)
     &      * loglaw_err(:nx1,:ny1,:nz1,:nelv))

         ! compute numerical stability term: pen_fstab
         call cart_diff_y(
     &      pen_fstab(:nx1,:ny1,:nz1,:nelv,il),
     &      (pen_k_len(:nx1,:ny1,:nz1,:nelv)
     &       * pen_floglaw(:nx1,:ny1,:nz1,:nelv,il)),
     &      .false.)

      enddo

#ifdef DEBUG
      ! for testing
      call outpost(
     &   pen_k_len,  ! x: VERIFIED!
     &   pen_fmask(:,:,:,:,1),  ! y: VERIFIED!
     &   pen_fmask(:,:,:,:,2),  ! z: VERIFIED?
     &   pen_floglaw(:,:,:,:,1),  ! pr
     &   pen_fstab(:,:,:,:,1),  ! temp
     &   'pen')
#endif

      return
      end subroutine
!=======================================================================
