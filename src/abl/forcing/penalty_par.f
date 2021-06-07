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
     $      'Penalty forcing term')

      ! register timer
      call mntr_tmr_is_name_reg(lpmid,'FRM_TOT')
      call mntr_tmr_reg(pen_tmr_id,lpmid,pen_id,
     $     'PENALTY_TOT','Penalty timer',.false.)

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

      call rprm_rp_reg(pen_enabled_id,pen_sec_id,'ENABLED',
     $     'Enable penalty forcing term',rpar_log,0,0.0,.false.,' ')

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
      call rprm_rp_get(itmp,rtmp,ltmp,ctmp,pen_enabled_id,rpar_log)
      pen_enabled = ltmp

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

      ! get penalty forcing mask
      call pen_fmask_get

      ! initialise random generator seed and number of time intervals
      ! do il=1,pen_regions
      !    pen_seed(il) = -32*il
      ! enddo
      ! pen_nfdt = 1 - pen_nset_max
      ! pen_nfdt_old = pen_nfdt

      ! generate random phases (time independent and time dependent)
      ! call pen_rphs_get

      ! get penalty forcing terms
      if (pen_enabled) call pen_fterms_get(.true.)

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
