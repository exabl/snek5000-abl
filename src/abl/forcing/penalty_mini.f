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
      if (
     &      (.not. pen_enabled) .or.
     &      (istep > 0 .and. pen_tdamp < 1.e-14)  ! no need to recompute forcing arrays
     &) then
          ! Do nothing!
          return
      endif



      ! timing
      ltim = dnekclock()

      ! update random phases (time independent and time dependent)
      ! call pen_rphs_get

      ! update forcing
      call pen_frcs_get(.false.)

      ! timing
      ltim = dnekclock() - ltim
      call mntr_tmr_add(pen_tmr_id,1,ltim)

#ifdef DEBUG
      print *,  "pen_regions = ", pen_regions
      print *,  "pen_npoint = ", pen_npoint
      print *,  "pen_k_len (min/max) = ", minval(pen_k_len),
     &   maxval(pen_k_len)
      print *,  "pen_frcs (min/max) = ", minval(pen_frcs),
     &   maxval(pen_frcs)
      print *,  "pen_famp (min/max) = ", minval(pen_famp),
     &   maxval(pen_famp)
      print *,  "pen_fsmth (min/max) = ", minval(pen_fsmth),
     &   maxval(pen_fsmth)
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

      k_len = pen_k_len(ix,iy,iz,iel)
      ffn = 0

      if (pen_enabled) then
         do il=1, pen_regions_max
           ipos = pen_map(ix,iy,iz,iel,il)
           ffn = ffn + (
     &          binvm1(ix, iy, iz, iel)  !  P^{-1}
     &          * pen_famp(ipos,il) * pen_fsmth(ix,iy,iz,iel,il)  ! sigma * E_{i,j}
     &          * (ux - k_len * du_dy(ix,iy,iz,iel)))

         enddo
      endif

#ifdef DEBUG
      ! print *, "Penalty ffn = ", ffn
#endif
      ffx = ffx + ffn

      return
      end subroutine
!=======================================================================
!> @brief Reset penalty
!! @ingroup penalty_mini
      subroutine pen_reset()
      implicit none

      include 'SIZE'
      include 'PENALTY'

      ! local variables
      real ltim

      ! functions
      real dnekclock
!-----------------------------------------------------------------------
      ! timing
      ltim = dnekclock()

      ! get 1D projection and array mapping
      call pen_1dprj

      ! update forcing
      call pen_frcs_get(.true.)

      ! timing
      ltim = dnekclock() - ltim
      call mntr_tmr_add(pen_tmr_id,1,ltim)

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
      subroutine pen_1dprj()
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'GEOM'
      include 'PENALTY'

      ! local variables
      integer nxy, nxyz, ntot !< @var number of points in xy face of an element, whole element and whole mesh
      integer itmp, jtmp, ktmp, eltmp
      integer il, jl
      real xl, yl, zl, xr, yr, zr !< @var left and right extents of the region
      real rota, epsl
      real rtmp !< @var temporary variable: distance**2 from starting position (pen_spos)
      parameter (epsl = 1.0e-10)

      real lcoord(LX1*LY1*LZ1*LELT)  ! @var NOTE: distance along
      common /CTMP0/ lcoord
      integer lmap(LX1*LY1*LZ1*LELT)
      common /CTMP1/ lmap
!-----------------------------------------------------------------------
      nxy = NX1*NY1
      nxyz = nxy*NZ1
      ntot = nxyz*NELV

      ! for each region
      do il=1,pen_regions
      ! Get coordinates and sort them
         call copy(lcoord,ym1,ntot)
         call sort(lcoord,lmap,ntot)

         ! find unique entrances and provide mapping
         pen_npoint(il) = 1
         pen_prj(pen_npoint(il),il) = lcoord(1)
         itmp = lmap(1)-1
         eltmp = itmp/nxyz + 1
         itmp = itmp - nxyz*(eltmp-1)
         ktmp = itmp/nxy + 1
         itmp = itmp - nxy*(ktmp-1)
         jtmp = itmp/nx1 + 1
         itmp = itmp - nx1*(jtmp-1) + 1
         pen_map(itmp,jtmp,ktmp,eltmp,il) = pen_npoint(il)
         do jl=2,ntot
            if(
     &          (lcoord(jl) - pen_prj(pen_npoint(il),il)) .gt.
     &           max(epsl, abs(epsl * lcoord(jl)))
     &       ) then
               pen_npoint(il) = pen_npoint(il) + 1
               pen_prj(pen_npoint(il),il) = lcoord(jl)
            endif

            itmp = lmap(jl)-1
            eltmp = itmp/nxyz + 1
            itmp = itmp - nxyz*(eltmp-1)
            ktmp = itmp/nxy + 1
            itmp = itmp - nxy*(ktmp-1)
            jtmp = itmp/nx1 + 1
            itmp = itmp - nx1*(jtmp-1) + 1
            pen_map(itmp,jtmp,ktmp,eltmp,il) = pen_npoint(il)
         enddo

         ! rescale 1D array
         do jl=1,pen_npoint(il)
            pen_prj(jl,il) = (pen_prj(jl,il) - pen_spos(ldim,il))
     $           *pen_ilngt(il)
         enddo

         ! get smoothing profile
         ! rota = pen_rota(il)

         do jl=1,ntot
            itmp = jl-1
            eltmp = itmp/nxyz + 1
            itmp = itmp - nxyz*(eltmp-1)
            ktmp = itmp/nxy + 1
            itmp = itmp - nxy*(ktmp-1)
            jtmp = itmp/nx1 + 1
            itmp = itmp - nx1*(jtmp-1) + 1

            ! calculate distances
            xl = xm1(itmp,jtmp,ktmp,eltmp)-pen_spos(1,il)
            yl = ym1(itmp,jtmp,ktmp,eltmp)-pen_spos(2,il)

            if (IF3D) then
                zl = zm1(itmp,jtmp,ktmp,eltmp)-pen_spos(3,il)
            endif

            ! no rotation
            xr = xl
            yr = yl
            zr = zl

            ! For isolated 3D masks
            !         rtmp = xr**2 + yr**2 + zr**2
            !         rtmp = (
            !  &          (xr*pen_ismth(1,il))**2
            !  &        + (yr*pen_ismth(2,il))**2
            !  &        + (zr*pen_ismth(3,il))**2 )

            ! Distance along y
            rtmp = abs(yr * pen_ismth(2, il))

            ! Delta function masking. NOTE: not smooth
            if (rtmp.lt.1.0) then
               pen_fsmth(itmp,jtmp,ktmp,eltmp,il) = 1.0
            else
               pen_fsmth(itmp,jtmp,ktmp,eltmp,il) = 0.0
            endif
         enddo
      enddo

      return
      end subroutine
!=======================================================================
!> @brief Generate forcing along 1D line
!! @details Initializes the pen_famp array. The facility to use
!!    temporal history has been removed in this version.
!! @ingroup penalty_mini
!! @param[in] ifreset    reset flag
!! @callgraph @callergraph
      subroutine pen_frcs_get(ifreset)
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'GEOM'  ! ym1
      include 'TSTEP'
      include 'PENALTY'
      include 'WMLES'  ! wmles_bc_z0

      ! argument list
      logical ifreset

#ifdef PENALTY_PR_RST
      ! variables necessary to reset pressure projection for P_n-P_n-2
      integer nprv(2)
      common /orthbi/ nprv

      ! variables necessary to reset velocity projection for P_n-P_n-2
      include 'VPROJ'
#endif
      ! local variables
      integer il, jl, kl, ll
      integer istart
      real y

#ifdef DEBUG
      character*3 str1, str2
      integer iunit, ierr
      ! call number
      integer icalldl
      save icalldl
      data icalldl /0/
#endif
!-----------------------------------------------------------------------
      ! reset all
      if (ifreset) then
        ! something to do with Fourier modes, instead we compute
        ! penalties for log-law
         do il= 1, pen_regions
            do jl = istart, pen_nset_max
               call cfill(pen_frcs(1,jl,il),1.0,pen_npoint(il))
            enddo
         enddo
         ! rescale time independent part
         if (pen_tiamp.ne.0.0) then
            do il= 1, pen_regions
               call cmult(pen_frcs(1,1,il),pen_tiamp,pen_npoint(il))
            enddo
         endif

         ! compute K array
         print *, "Computing penalty K array"
        !      do ll=1, nelv
        !         do kl=1, nz1
        !            do jl=1, ny1
        !               do il=1, nx1
        !                  y = ym1(il, jl, kl, ll)
        !                  pen_k_len(il, jl, kl, ll) = (
        !  &                  y * log(y / wmles_bc_z0))
        !               enddo
        !            enddo
        !         enddo
        !     enddo
        pen_k_len(:nx1,:ny1,:nz1,:nelv) = (
     &       ym1(:nx1,:ny1,:nz1,:nelv) * log(
     &          ym1(:nx1,:ny1,:nz1,:nelv) / wmles_bc_z0
     &       )
     &   )
      ! else
         ! reset only time dependent part if needed
      endif

      ! get penalty for current time step
      if (pen_tiamp.ne.0.0) then
         ! copy pen_tiamp stored in pen_frcs (see above) -> pen_famp
         do il= 1, pen_regions
           call copy(pen_famp(1,il),pen_frcs(1,1,il),pen_npoint(il))
         enddo
      else
         ! fill zeros -> pen_famp
         do il= 1, pen_regions
            call rzero(pen_famp(1,il),pen_npoint(il))
         enddo
      endif
      ! interpolation in time: disabled

#ifdef DEBUG
      ! for testing
      ! to output refinement
      icalldl = icalldl+1
      call io_file_freeid(iunit, ierr)
      write(str1,'(i3.3)') NID
      write(str2,'(i3.3)') icalldl
      open(unit=iunit,file='trp_fcr.txt'//str1//'i'//str2)

      do il=1,pen_npoint(1)
         write(iunit,*) il,pen_prj(il,1),pen_famp(il,1),
     $        pen_frcs(il,:,1)
      enddo

      close(iunit)
#endif

      return
      end subroutine
!=======================================================================
