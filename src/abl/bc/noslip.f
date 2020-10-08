!-----------------------------------------------------------------------
c> No slip and no penetration condition
      subroutine abl_userbc(ix,iy,iz,iside,eg)
      implicit none

      include 'SIZE'
      include 'NEKUSE'  ! ux, uy, uz, temp, x, y

      integer ix, iy, iz, iside, eg

      ux =  0.0
      uy =  0.0
      uz =  0.0

      return
      end
!-----------------------------------------------------------------------
