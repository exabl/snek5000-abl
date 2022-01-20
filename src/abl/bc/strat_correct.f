      real function psi_m_stable(xi)
      implicit none
      real xi

      psi_m_stable = -5.d0 * xi
      end function


      real function psi_m_unstable(xi)
      implicit none
      real xi, xi4, pi_half

      pi_half = 2. * atan(1.)
      xi4 = (1.0 - 16 * xi) ** 0.25

      psi_m_unstable = (
     &  log(0.125 * (xi4 + 1) ** 2 * (xi4 ** 2 + 1))
     &  - 2 * atan(xi4)
     &  + pi_half
     &)
      end function


      real function psi_h_unstable(xi)
      implicit none
      real xi, xi2

      xi2 = (1.0 - 16 * xi) ** 0.5
      psi_h_unstable = log(0.25 * (xi2 + 1) ** 2)
      end function


      real function eval_func_at(z0, z1, L, func)
      implicit none
      real z0, z1, L
      real func

      eval_func_at = log(z1 / z0) - func(z1 / L) + func(z0 / L)
      end function


      real function PsiM_stable_at(z0, z1, L)
      implicit none
      real z0, z1, L
      real psi_m_stable, eval_func_at
      external psi_m_stable

      PsiM_stable_at = eval_func_at(z0, z1, L, psi_m_stable)
      end function


      real function PsiH_stable_at(z0, z1, L)
      implicit none
      real z0, z1, L
      real PsiM_stable_at

      ! NOTE: same function
      PsiH_stable_at = PsiM_stable_at(z0, z1, L)
      end function


      real function PsiM_unstable_at(z0, z1, L)
      implicit none
      real z0, z1, L
      real psi_m_unstable, eval_func_at
      external psi_m_unstable

      PsiM_unstable_at = eval_func_at(z0, z1, L, psi_m_unstable)
      end function


      real function PsiH_unstable_at(z0, z1, L)
      implicit none
      real z0, z1, L
      real psi_h_unstable, eval_func_at
      external psi_h_unstable

      PsiH_unstable_at = eval_func_at(z0, z1, L, psi_h_unstable)
      end function


      real function richardson(L, z0, z1)
      implicit none
      real L, z0, z1
      real PsiM_at, PsiH_at

      call calc_Psi(PsiM_at, PsiH_at, z0, z1, L)

      ! For Dirichlet conditions
      richardson = (z1 / L) * (PsiH_at / PsiM_at ** 2)
      end function


      real function f_richardson(L, z0, z1, Ri_b)
      implicit none
      real L, z0, z1, Ri_b
      real richardson

      ! Function to find root of by Newton-Raphson
      f_richardson = Ri_b - richardson(L, z0, z1)
      end function


      real function df_richardson_dL(L, z0, z1, Ri_b)
      implicit none
      real L, z0, z1, Ri_b
      real f_richardson
      real dL, f_plus, f_minus

      ! Numerical first derivative by Central difference
      dL = 1e-4 * L
      f_plus = f_richardson(L + dL, z0, z1, Ri_b)
      f_minus = f_richardson(L - dL, z0, z1, Ri_b)
      df_richardson_dL = (f_plus - f_minus) / (2 * dL)
      end function


      subroutine calc_Psi(M, H, z0, z1, L)
      implicit none
      real M, H
      real z0, z1, L

      real PsiM_stable_at, PsiM_unstable_at
      real PsiH_stable_at, PsiH_unstable_at

      if (L >= 0) then
          M = PsiM_stable_at(z0, z1, L)
          H = PsiH_stable_at(z0, z1, L)
      else
          M = PsiM_unstable_at(z0, z1, L)
          H = PsiH_unstable_at(z0, z1, L)
      endif
      end subroutine

c> Calculate Obukhov Length
      subroutine calc_L_ob(L, L0, z0, z1, Ri_b)
      implicit none

      real L
      real L0, z0, z1, Ri_b
      integer iters

      real f_richardson, df_richardson_dL
      external f_richardson, df_richardson_dL

      call newton_solve(
     & f_richardson, df_richardson_dL, L0, L, iters, z0, z1, Ri_b)

      end subroutine
