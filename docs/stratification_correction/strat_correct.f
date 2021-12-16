      real*8 function psi_m_stable(xi)
      implicit none
      real*8 xi

      psi_m_stable = -5.d0 * xi
      end function


      real*8 function psi_m_unstable(xi)
      implicit none
      real*8 xi, xi4, pi_half

      pi_half = 2. * atan(1.)
      xi4 = (1.0 - 16 * xi) ** 0.25

      psi_m_unstable = (
     &  log(0.125 * (xi4 + 1) ** 2 * (xi4 ** 2 + 1))
     &  - 2 * atan(xi4)
     &  + pi_half
     &)
      end function
 

      real*8 function psi_h_unstable(xi)
      implicit none
      real*8 xi, xi2

      xi2 = (1.0 - 16 * xi) ** 0.5
      psi_h_unstable = log(0.25 * (xi2 + 1) ** 2)
      end function


      real*8 function eval_func_at(z0, z1, L, func)
      implicit none
      real*8 z0, z1, L
      real*8 func

      eval_func_at = log(z1 / z0) - func(z1 / L) + func(z0 / L)
      end function


      real*8 function PsiM_stable_at(z0, z1, L)
      implicit none
      real*8 z0, z1, L
      real*8 psi_m_stable, eval_func_at
      external psi_m_stable

      PsiM_stable_at = eval_func_at(z0, z1, L, psi_m_stable)
      end function


      real*8 function PsiH_stable_at(z0, z1, L)
      implicit none
      real*8 z0, z1, L
      real*8 PsiM_stable_at

      ! NOTE: same function
      PsiH_stable_at = PsiM_stable_at(z0, z1, L)
      end function


      real*8 function PsiM_unstable_at(z0, z1, L)
      implicit none
      real*8 z0, z1, L
      real*8 psi_m_unstable, eval_func_at
      external psi_m_unstable

      PsiM_unstable_at = eval_func_at(z0, z1, L, psi_m_unstable)
      end function


      real*8 function PsiH_unstable_at(z0, z1, L)
      implicit none
      real*8 z0, z1, L
      real*8 psi_h_unstable, eval_func_at
      external psi_h_unstable

      PsiH_unstable_at = eval_func_at(z0, z1, L, psi_h_unstable)
      end function

      real*8 function richardson(L, z0, z1)
      implicit none
      real*8 L, z0, z1
      real*8 PsiM_at, PsiH_at
      real*8 PsiM_stable_at, PsiM_unstable_at
      real*8 PsiH_stable_at, PsiH_unstable_at

      if (L >= 0) then
          PsiM_at = PsiM_stable_at(z0, z1, L)
          PsiH_at = PsiH_stable_at(z0, z1, L)
      else
          PsiM_at = PsiM_unstable_at(z0, z1, L)
          PsiH_at = PsiH_unstable_at(z0, z1, L)
      endif

      ! For Dirichlet conditions
      richardson = (z1 / L) * (PsiH_at / PsiM_at ** 2)
      end function


      real*8 function f_richardson(L, z0, z1, Ri_b)
      implicit none
      real*8 L, z0, z1, Ri_b
      real*8 richardson

      ! Function to find root of by Newton-Raphson
      f_richardson = Ri_b - richardson(L, z0, z1)
      end function


      real*8 function df_richardson_dL(L, z0, z1, Ri_b)
      implicit none
      real*8 L, z0, z1, Ri_b
      real*8 f_richardson
      real*8 dL, f_plus, f_minus

      ! Numerical first derivative by Central difference
      dL = 1e-4 * L
      f_plus = f_richardson(L + dL, z0, z1, Ri_b)
      f_minus = f_richardson(L - dL, z0, z1, Ri_b)
      df_richardson_dL = (f_plus - f_minus) / (2 * dL)
      end function
