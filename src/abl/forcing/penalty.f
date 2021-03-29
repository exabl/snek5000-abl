!> @file penalty.f
!! @ingroup pen_line
!! @brief Tripping function for AMR version of nek5000
!! @note  This version uses developed framework parts. This is because
!!   I'm in a hurry and I want to save some time writing the code. So
!!   I reuse already tested code and focuse important parts. For the
!!   same reason for now only lines parallel to z axis are considered. 
!!   The penalty is based on a similar implementation in the SIMSON code
!!   (Chevalier et al. 2007, KTH Mechanics), and is described in detail 
!!   in the paper Schlatter & Örlü, JFM 2012, DOI 10.1017/jfm.2012.324.
!! @author Adam Peplinski
!! @date May 03, 2018
!=======================================================================
!> @brief Register penalty module
!! @ingroup pen_line
!! @note This routine should be called in frame_usr_register
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
      call mntr_mod_is_name_reg(lpmid,pen_name)
      if (lpmid.gt.0) then
         call mntr_warn(lpmid,
     $        'module ['//trim(pen_name)//'] already registered')
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
      call mntr_mod_reg(pen_id,lpmid,pen_name,
     $      'Tripping along the line')

      ! register timer
      call mntr_tmr_is_name_reg(lpmid,'FRM_TOT')
      call mntr_tmr_reg(pen_tmr_id,lpmid,pen_id,
     $     'PENALTY_TOT','Tripping total time',.false.)

      ! register and set active section
      call rprm_sec_reg(pen_sec_id,pen_id,'_'//adjustl(pen_name),
     $     'Runtime paramere section for penalty module')
      call rprm_sec_set_act(.true.,pen_sec_id)

      ! register parameters
      call rprm_rp_reg(pen_regions_id,pen_sec_id,'NLINE',
     $     'Number of penalty lines',rpar_int,0,0.0,.false.,' ')

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
!! @ingroup pen_line
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
     $        'module ['//trim(pen_name)//'] already initiaised.')
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
      call pen_rphs_get

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
!! @ingroup pen_line
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
!! @ingroup pen_line
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
      call pen_rphs_get

      ! update forcing
      call pen_frcs_get(.false.)

      ! timing
      ltim = dnekclock() - ltim
      call mntr_tmr_add(pen_tmr_id,1,ltim)

      return
      end subroutine      
!=======================================================================
!> @brief Compute penalty forcing
!! @ingroup pen_line
!! @param[inout] ffx,ffy,ffz     forcing; x,y,z component
!! @param[in]    ix,iy,iz        GLL point index
!! @param[in]    ieg             global element number
      subroutine pen_forcing(ffx,ffy,ffz,ix,iy,iz,ieg)
      implicit none

      include 'SIZE'
      include 'PARALLEL'
      include 'PENALTY'

      ! argument list
      real ffx, ffy, ffz
      integer ix,iy,iz,ieg

      ! local variables
      integer ipos,iel,il
      real ffn
!-----------------------------------------------------------------------
      iel=GLLEL(ieg)
      ffn = 0.0
      
      do il= 1, pen_regions
         ipos = pen_map(ix,iy,iz,iel,il)
         ffn = pen_famp(ipos,il)*pen_fsmth(ix,iy,iz,iel,il)
         
         ffx = ffx - ffn*sin(pen_rota(il))
         ffy = ffy + ffn*cos(pen_rota(il))
      enddo
      
      return
      end subroutine
!=======================================================================
!> @brief Reset penalty
!! @ingroup pen_line
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
!! @ingroup pen_line
!! @details This routine is just a simple version supporting only lines
!!   paralles to z axis. In future it can be generalised.
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
      real xl, yl, xr, yr !< @var left and right extents of the region
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
      
      ! for each line
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
            if((lcoord(jl)-pen_prj(pen_npoint(il),il)).gt.
     $           max(epsl,abs(epsl*lcoord(jl)))) then
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
         rota = pen_rota(il)
         
         do jl=1,ntot
            itmp = jl-1
            eltmp = itmp/nxyz + 1
            itmp = itmp - nxyz*(eltmp-1)
            ktmp = itmp/nxy + 1
            itmp = itmp - nxy*(ktmp-1)
            jtmp = itmp/nx1 + 1
            itmp = itmp - nx1*(jtmp-1) + 1

            ! rotation
            xl = xm1(itmp,jtmp,ktmp,eltmp)-pen_spos(1,il)
            yl = ym1(itmp,jtmp,ktmp,eltmp)-pen_spos(2,il)

            xr = xl*cos(rota)+yl*sin(rota)
            yr = -xl*sin(rota)+yl*cos(rota)
            
            ! distance**2 from starting position (pen_spos)
            rtmp = (xr*pen_ismth(1,il))**2 + (yr*pen_ismth(2,il))**2
            ! Gauss
            !pen_fsmth(itmp,jtmp,ktmp,eltmp,il) = exp(-4.0*rtmp)
            ! limited support
            if (rtmp.lt.1.0) then
               pen_fsmth(itmp,jtmp,ktmp,eltmp,il) =
     $              exp(-rtmp)*(1-rtmp)**2
            else
               pen_fsmth(itmp,jtmp,ktmp,eltmp,il) = 0.0
            endif

         enddo
      enddo

      return
      end subroutine      
!=======================================================================
!> @brief Generate set of random phases
!! @ingroup pen_line
      subroutine pen_rphs_get
      implicit none

      include 'SIZE'
      include 'TSTEP'
      include 'PARALLEL'
      include 'PENALTY'
      
      ! local variables
      integer il, jl, kl
      integer itmp
      real pen_ran2

#ifdef DEBUG
      character*3 str1, str2
      integer iunit, ierr
      ! call number
      integer icalldl
      save icalldl
      data icalldl /0/
#endif
!-----------------------------------------------------------------------
      ! time independent part
      if (pen_tiamp.gt.0.0.and..not.pen_ifinit) then
         do il = 1, pen_regions
            do jl=1, pen_nmode(il)
               pen_rphs(jl,1,il) = 2.0*pi*pen_ran2(il)
            enddo
         enddo
      endif

      ! time dependent part
      do il = 1, pen_regions
         itmp = int(time/pen_fdt(il))
         call bcast(itmp,ISIZE) ! just for safety
         do kl= pen_nfdt+1, itmp
            do jl= pen_nset_max,3,-1
               call copy(pen_rphs(1,jl,il),pen_rphs(1,jl-1,il),
     $              pen_nmode(il))
            enddo
            do jl=1, pen_nmode(il)
               pen_rphs(jl,2,il) = 2.0*pi*pen_ran2(il)
            enddo
         enddo
      enddo
      
      ! update time interval
      pen_nfdt_old = pen_nfdt
      pen_nfdt = itmp

#ifdef DEBUG
      ! for testing
      ! to output refinement
      icalldl = icalldl+1
      call io_file_freeid(iunit, ierr)
      write(str1,'(i3.3)') NID
      write(str2,'(i3.3)') icalldl
      open(unit=iunit,file='trp_rps.txt'//str1//'i'//str2)

      do il=1,pen_nmode(1)
         write(iunit,*) il,pen_rphs(il,1:4,1)
      enddo

      close(iunit)
#endif

      return
      end subroutine
!=======================================================================
!> @brief A simple portable random number generator
!! @ingroup pen_line
!! @details  Requires 32-bit integer arithmetic. Taken from Numerical
!!   Recipes, William Press et al. Gives correlation free random
!!   numbers but does not have a very large dynamic range, i.e only
!!   generates 714025 different numbers. Set seed negative for
!!   initialization
!! @param[in]   il      line number
!! @return      ran
      real function pen_ran2(il)
      implicit none

      include 'SIZE'
      include 'PENALTY'
      
      ! argument list
      integer il

      ! local variables
      integer iff(pen_regions_max), iy(pen_regions_max)
      integer ir(97,pen_regions_max)
      integer m,ia,ic,j
      real rm
      parameter (m=714025,ia=1366,ic=150889,rm=1./m)
      save iff,ir,iy
      data iff /pen_regions_max*0/
!-----------------------------------------------------------------------
      ! initialise
      if (pen_seed(il).lt.0.or.iff(il).eq.0) then
         iff(il)=1
         pen_seed(il)=mod(ic-pen_seed(il),m)
         do j=1,97
            pen_seed(il)=mod(ia*pen_seed(il)+ic,m)
            ir(j,il)=pen_seed(il)
         end do
         pen_seed(il)=mod(ia*pen_seed(il)+ic,m)
         iy(il)=pen_seed(il)
      end if
      
      ! generate random number
      j=1+(97*iy(il))/m
      iy(il)=ir(j,il)
      pen_ran2=iy(il)*rm
      pen_seed(il)=mod(ia*pen_seed(il)+ic,m)
      ir(j,il)=pen_seed(il)

      end function
!=======================================================================
!> @brief Generate forcing along 1D line
!! @ingroup pen_line
!! @param[in] ifreset    reset flag
      subroutine pen_frcs_get(ifreset)
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'TSTEP'
      include 'PENALTY'

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
         if (pen_tiamp.gt.0.0) then
            istart = 1
         else
            istart = 2
         endif
         do il= 1, pen_regions
            do jl = istart, pen_nset_max
               call rzero(pen_frcs(1,jl,il),pen_npoint(il))
               do kl= 1, pen_npoint(il)
                  theta0 = 2*pi*pen_prj(kl,il)
                  do ll= 1, pen_nmode(il)
                     theta = theta0*ll
                     pen_frcs(kl,jl,il) = pen_frcs(kl,jl,il) +
     $                    sin(theta+pen_rphs(ll,jl,il))
                  enddo
               enddo
            enddo
         enddo
         ! rescale time independent part
         if (pen_tiamp.gt.0.0) then
            do il= 1, pen_regions
               call cmult(pen_frcs(1,1,il),pen_tiamp,pen_npoint(il))
            enddo
         endif
      else
         ! reset only time dependent part if needed
         if (pen_nfdt.ne.pen_nfdt_old) then
#ifdef PENALTY_PR_RST
            ! reset projection space
            ! pressure
            if (int(PARAM(95)).gt.0) then
               PARAM(95) = ISTEP
               nprv(1) = 0      ! veloctiy field only
            endif
            ! velocity
            if (int(PARAM(94)).gt.0) then
               PARAM(94) = ISTEP!+2
               ivproj(2,1) = 0
               ivproj(2,2) = 0
               if (IF3D) ivproj(2,3) = 0
            endif
#endif
            do il= 1, pen_regions
               do jl= pen_nset_max,3,-1
                  call copy(pen_frcs(1,jl,il),pen_frcs(1,jl-1,il),
     $                 pen_npoint(il))
               enddo
               call rzero(pen_frcs(1,2,il),pen_npoint(il))
               do jl= 1, pen_npoint(il)
                  theta0 = 2*pi*pen_prj(jl,il)
                  do kl= 1, pen_nmode(il)
                     theta = theta0*kl
                     pen_frcs(jl,2,il) = pen_frcs(jl,2,il) +
     $                    sin(theta+pen_rphs(kl,2,il))
                  enddo
               enddo
            enddo
         endif
      endif
      
      ! get penalty for current time step
      if (pen_tiamp.gt.0.0) then
         do il= 1, pen_regions
           call copy(pen_famp(1,il),pen_frcs(1,1,il),pen_npoint(il))
         enddo
      else
         do il= 1, pen_regions
            call rzero(pen_famp(1,il),pen_npoint(il))
         enddo
      endif
      ! interpolation in time
      do il = 1, pen_regions
         theta0= time/pen_fdt(il)-real(pen_nfdt)
         if (theta0.gt.0.0) then
            theta0=theta0*theta0*(3.0-2.0*theta0)
            !theta0=theta0*theta0*theta0*(10.0+(6.0*theta0-15.0)*theta0)
            do jl= 1, pen_npoint(il)
               pen_famp(jl,il) = pen_famp(jl,il) +
     $              pen_tdamp*((1.0-theta0)*pen_frcs(jl,3,il) +
     $              theta0*pen_frcs(jl,2,il))
            enddo
         else
            theta0=theta0+1.0
            theta0=theta0*theta0*(3.0-2.0*theta0)
            !theta0=theta0*theta0*theta0*(10.0+(6.0*theta0-15.0)*theta0)
            do jl= 1, pen_npoint(il)
               pen_famp(jl,il) = pen_famp(jl,il) +
     $              pen_tdamp*((1.0-theta0)*pen_frcs(jl,4,il) +
     $              theta0*pen_frcs(jl,3,il))
            enddo
         endif
      enddo

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
     $        pen_frcs(il,1:4,1)
      enddo

      close(iunit)
#endif
      
      return
      end subroutine
!=======================================================================
