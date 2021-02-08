!> @file init.f
!! @ingroup fp
!! @brief Flow and physics (FLOWPHYS) module
!! @details Register and initialize parameters which control flow physics
!! @{
!=======================================================================
!> Register FLOWPHYS module
!! @note This routine should be called in frame_usr_register
      subroutine fp_register()
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'FRAMELP'
      include 'FLOWPHYS'

      ! local variables
      integer lpmid
!-----------------------------------------------------------------------
      ! check if the current module was already registered
      call mntr_mod_is_name_reg(lpmid, fp_sec_name)
      if (lpmid.gt.0) then
         call mntr_warn(
     $      lpmid,
     $     'module ['//trim(fp_sec_name)//'] already registered')
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
      call mntr_mod_reg(fp_id, lpmid, fp_sec_name,
     $      'Flow Physics parameters')

      ! register and set active section
      call rprm_sec_reg(
     $    fp_sec_id,fp_id,'_'//adjustl(fp_sec_name),
     $    'Runtime parameter section for FLOWPHYS module')
      call rprm_sec_set_act(.true.,fp_sec_id)

      ! register parameters
      ! subroutine rprm_rp_reg(rpid, mid, pname, pdscr, ptype, ipval, rpval, lpval, cpval)
      call rprm_rp_reg(
     $    fp_par_id(1), fp_sec_id,
     $    'CORIOON', 'Turn coriolis forcing on', rpar_log,
     $    1, 0.0, .true., ' '
     $)
      call rprm_rp_reg(
     $    fp_par_id(2), fp_sec_id,
     $    'CORIOFREQ', 'Coriolis frequency', rpar_real,
     $    1, 1.4e-4, .false., ' '
     $)
      call rprm_rp_reg(
     $    fp_par_id(3), fp_sec_id,
     $    'UGEO', 'Geostrophic velocity', rpar_real,
     $    1, 5.0, .false., ' '
     $)

      ! set initialisation flag
      fp_ifinit=.false.

      end subroutine
!=======================================================================
!> Initiliase FLOWPHYS Module
!! @note This routine should be called in frame_usr_init
      subroutine fp_init()
      implicit none

      include 'SIZE'
      include 'FRAMELP'
      include 'FLOWPHYS'

      ! local variables for reading parameters with appropriate types
      integer itmp
      real rtmp
      logical ltmp
      character*20 ctmp
!-----------------------------------------------------------------------
      ! check if the module was already initialised
      if (fp_ifinit) then
         call mntr_warn(fp_id,
     $        'module ['//trim(fp_sec_name)//'] already initiaised.')
         return
      endif

      ! get runtime parameters
      call rprm_rp_get(itmp, rtmp, ltmp, ctmp,
     $    fp_par_id(1), rpar_log)
      fp_corio_on = ltmp

      call rprm_rp_get(itmp, rtmp, ltmp, ctmp,
     $    fp_par_id(2), rpar_real)
      fp_corio_freq = rtmp

      call rprm_rp_get(itmp, rtmp, ltmp, ctmp,
     $    fp_par_id(3), rpar_real)
      fp_u_geo = rtmp

      ! everything is initialised
      fp_ifinit=.true.
      end subroutine
!=======================================================================
!> Check if module was initialised
!! @return fp_is_initialised
      logical function fp_is_initialised()
      implicit none

      include 'SIZE'
      include 'FLOWPHYS'
      fp_is_initialised = fp_ifinit

      return
      end function
!=======================================================================
!! @}
