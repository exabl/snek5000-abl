!-----------------------------------------------------------------------
!> @defgroup penalty_mini Penalty "boundary conditions"
!!   A BC which appears as a/forcing": the mini version
!! @file penalty_mini.f
!! @ingroup penalty_mini
!! @brief Penalty for ABL user code of nek5000
!! @note This module is derived from the forcing module in KTH
!!   framework 
!=======================================================================
!> @brief Register penalty module
!! @ingroup penalty_mini
!! @note This routine should be called in frame_usr_register
!! @callgraph
      subroutine pen_register()
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'FRAMELP'
      include 'PENALTY'

      ! local variables
      integer lpmid, il
      real ltim
      character*2 str

      ! functions
      real dnekclock
!-----------------------------------------------------------------------
      ! timing
      ltim = dnekclock()

      ! check if the current module was already registered
      call mntr_mod_is_name_reg(lpmid,pen_sec_name)
      if (lpmid.gt.0) then
         call mntr_warn(lpmid,
     $        'module ['//trim(pen_sec_name)//'] already registered')
         return
      endif

      ! find parent module
      call mntr_mod_is_name_reg(lpmid,'FRAME')
      if (lpmid.le.0) then
         lpmid = 1
         call mntr_abort(lpmid,
     $        'parent module ['//'FRAME'//'] not registered')
      endif

      ! register module
      call mntr_mod_reg(pen_id,lpmid,pen_sec_name,
     $      'Tripping along the line')

      ! register timer
      call mntr_tmr_is_name_reg(lpmid,'FRM_TOT')
      call mntr_tmr_reg(pen_tmr_id,lpmid,pen_id,
     $     'PENALTY_TOT','Tripping total time',.false.)

      ! register and set active section
      call rprm_sec_reg(pen_sec_id,pen_id,'_'//adjustl(pen_sec_name),
     $     'Runtime paramere section for penalty module')
      call rprm_sec_set_act(.true.,pen_sec_id)

      ! register parameters
      call rprm_rp_reg(pen_regions_id,pen_sec_id,'NREGION',
     $     'Number of penalty regions',rpar_int,0,0.0,.false.,' ')

      call rprm_rp_reg(pen_tiamp_id,pen_sec_id,'TIAMP',
     $     'Time independent amplitude',rpar_real,0,0.0,.false.,' ')

      call rprm_rp_reg(pen_tdamp_id,pen_sec_id,'TDAMP',
     $     'Time dependent amplitude',rpar_real,0,0.0,.false.,' ')

      do il=1, pen_regions_max
         write(str,'(I2.2)') il

         call rprm_rp_reg(pen_spos_id(1,il),pen_sec_id,'SPOSX'//str,
     $     'Starting point X',rpar_real,0,0.0,.false.,' ')
         
         call rprm_rp_reg(pen_spos_id(2,il),pen_sec_id,'SPOSY'//str,
     $     'Starting point Y',rpar_real,0,0.0,.false.,' ')

         if (IF3D) then
            call rprm_rp_reg(pen_spos_id(ldim,il),pen_sec_id,
     $           'SPOSZ'//str,'Starting point Z',
     $           rpar_real,0,0.0,.false.,' ')
         endif
        
         call rprm_rp_reg(pen_epos_id(1,il),pen_sec_id,'EPOSX'//str,
     $     'Ending point X',rpar_real,0,0.0,.false.,' ')
         
         call rprm_rp_reg(pen_epos_id(2,il),pen_sec_id,'EPOSY'//str,
     $     'Ending point Y',rpar_real,0,0.0,.false.,' ')

         if (IF3D) then
            call rprm_rp_reg(pen_epos_id(ldim,il),pen_sec_id,
     $           'EPOSZ'//str,'Ending point Z',
     $           rpar_real,0,0.0,.false.,' ')
         endif

         call rprm_rp_reg(pen_smth_id(1,il),pen_sec_id,'SMTHX'//str,
     $     'Smoothing length X',rpar_real,0,0.0,.false.,' ')
         
         call rprm_rp_reg(pen_smth_id(2,il),pen_sec_id,'SMTHY'//str,
     $     'Smoothing length Y',rpar_real,0,0.0,.false.,' ')

         if (IF3D) then
            call rprm_rp_reg(pen_smth_id(ldim,il),pen_sec_id,
     $           'SMTHZ'//str,'Smoothing length Z',
     $           rpar_real,0,0.0,.false.,' ')
         endif
      
         call rprm_rp_reg(pen_rota_id(il),pen_sec_id,'ROTA'//str,
     $        'Rotation angle',rpar_real,0,0.0,.false.,' ')
         call rprm_rp_reg(pen_nmode_id(il),pen_sec_id,'NMODE'//str,
     $     'Number of Fourier modes',rpar_int,0,0.0,.false.,' ')
         call rprm_rp_reg(pen_fdt_id(il),pen_sec_id,'FDT'//str,
     $     'Time step for penalty',rpar_real,0,0.0,.false.,' ')
      enddo

      ! set initialisation flag
      pen_ifinit=.false.
      
      ! timing
      ltim = dnekclock() - ltim
      call mntr_tmr_add(pen_tmr_id,1,ltim)

      return
      end subroutine
!=======================================================================
!> @brief Initilise penalty module
!! @ingroup penalty_mini
!! @note This routine should be called in frame_usr_init
      subroutine pen_init()
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'GEOM'
      include 'FRAMELP'
      include 'PENALTY'

      ! local variables
      integer itmp
      real rtmp, ltim
      logical ltmp
      character*20 ctmp

      integer il, jl

      ! functions
      real dnekclock
!-----------------------------------------------------------------------
      ! check if the module was already initialised
      if (pen_ifinit) then
         call mntr_warn(pen_id,
     $        'module ['//trim(pen_sec_name)//'] already initiaised.')
         return
      endif
      
      ! timing
      ltim = dnekclock()

      ! get runtime parameters
      call rprm_rp_get(itmp,rtmp,ltmp,ctmp,pen_regions_id,rpar_int)
      pen_regions = itmp
      call rprm_rp_get(itmp,rtmp,ltmp,ctmp,pen_tiamp_id,rpar_real)
      pen_tiamp = rtmp
      call rprm_rp_get(itmp,rtmp,ltmp,ctmp,pen_tdamp_id,rpar_real)
      pen_tdamp = rtmp
      do il=1,pen_regions
         do jl=1,LDIM
            call rprm_rp_get(itmp,rtmp,ltmp,ctmp,pen_spos_id(jl,il),
     $           rpar_real)
            pen_spos(jl,il) = rtmp
            call rprm_rp_get(itmp,rtmp,ltmp,ctmp,pen_epos_id(jl,il),
     $           rpar_real)
            pen_epos(jl,il) = rtmp
            call rprm_rp_get(itmp,rtmp,ltmp,ctmp,pen_smth_id(jl,il),
     $           rpar_real)
            pen_smth(jl,il) = rtmp
         enddo
         call rprm_rp_get(itmp,rtmp,ltmp,ctmp,pen_rota_id(il),
     $        rpar_real)
         pen_rota(il) = rtmp
         call rprm_rp_get(itmp,rtmp,ltmp,ctmp,pen_nmode_id(il),
     $        rpar_int)
         pen_nmode(il) = itmp
         call rprm_rp_get(itmp,rtmp,ltmp,ctmp,pen_fdt_id(il),
     $        rpar_real)
         pen_fdt(il) = rtmp
      enddo

      ! get inverse line lengths and smoothing radius
      do il=1,pen_regions
         pen_ilngt(il) = 0.0
         do jl=1,LDIM
            pen_ilngt(il) = pen_ilngt(il) + (pen_epos(jl,il)-
     $           pen_spos(jl,il))**2
         enddo
         if (pen_ilngt(il).gt.0.0) then
            pen_ilngt(il) = 1.0/sqrt(pen_ilngt(il))
         else
            pen_ilngt(il) = 1.0
         endif
         do jl=1,LDIM
            if (pen_smth(jl,il).gt.0.0) then
               pen_ismth(jl,il) = 1.0/pen_smth(jl,il)
            else
               pen_ismth(jl,il) = 1.0
            endif
         enddo
      enddo

      ! get 1D projection and array mapping
      call pen_1dprj

      ! initialise random generator seed and number of time intervals
      do il=1,pen_regions
         pen_seed(il) = -32*il
      enddo
      pen_nfdt = 1 - pen_nset_max
      pen_nfdt_old = pen_nfdt
      
      ! generate random phases (time independent and time dependent)
      ! call pen_rphs_get

      ! get forcing
      call pen_frcs_get(.true.)
      
      ! everything is initialised
      pen_ifinit=.true.

      ! timing
      ltim = dnekclock() - ltim
      call mntr_tmr_add(pen_tmr_id,1,ltim)

      return
      end subroutine
!=======================================================================
!> @brief Check if module was initialised
!! @ingroup penalty_mini
!! @return pen_is_initialised
      logical function pen_is_initialised()
      implicit none

      include 'SIZE'
      include 'PENALTY'
!-----------------------------------------------------------------------
      pen_is_initialised = pen_ifinit

      return
      end function
!=======================================================================
!> @brief Update penalty
!! @ingroup penalty_mini
      subroutine pen_update()
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

      ! update random phases (time independent and time dependent)
      ! call pen_rphs_get

      ! update forcing
      call pen_frcs_get(.false.)

      ! timing
      ltim = dnekclock() - ltim
      call mntr_tmr_add(pen_tmr_id,1,ltim)

#ifdef DEBUG
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

      do il=1, pen_regions_max
        ipos = pen_map(ix,iy,iz,iel,il)
        ffn = ffn + (
     &       binvm1(ix, iy, iz, iel)  !  P^{-1}
     &       * pen_famp(ipos,il) * pen_fsmth(ix,iy,iz,iel,il)  ! sigma * E_{i,j}
     &       * (ux - k_len * du_dy(ix,iy,iz,iel)))

      enddo

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
      
      real lcoord(LX1*LY1*LZ1*LELT)
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
         call copy(lcoord,zm1,ntot)
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
      real theta0, theta

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
               call rzero(pen_frcs(1,jl,il),pen_npoint(il))
               do kl= 1, pen_npoint(il)
                  
               enddo
            enddo
         enddo
         ! rescale time independent part
         if (pen_tiamp.ne.0.0) then
            do il= 1, pen_regions
               call cmult(pen_frcs(1,1,il),pen_tiamp,pen_npoint(il))
            enddo
         endif

         ! compute K array
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
         ! copy pen_tiamp or pen_frcs -> pen_famp 
         do il= 1, pen_regions
           call copy(pen_famp(1,il),pen_frcs(1,1,il),pen_npoint(il))
         enddo
      else
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
