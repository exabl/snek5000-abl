c> Estimate the zero of f(x) using Newton's method.
c> @license CC-BY https://faculty.washington.edu/rjl/classes/am583s2013/notes/
      subroutine newton_solve(f, fp, x0, x, iters, z0, z1, Ri_b)

      ! Input:
      !   f:  the function to find a root of
      !   fp: function returning the derivative f'
      !   x0: the initial guess
      !   z0, z1, Ri_b: extra arguments for functions f and fp
      ! Returns:
      !   the estimate x satisfying f(x)=0 (assumes Newton converged!)
      !   the number of iterations iters

      implicit none
      integer maxiter
      parameter (maxiter=1000)
      real tol
      parameter (tol=1e-8)

      real f, fp, x0
      external f, fp
      real x
      integer iters
      real z0, z1, Ri_b

      ! Declare any local variables:
      real deltax, fx, fxprime
      integer k


      ! initial guess
      x = x0

#ifdef DEBUG
        print 11, x
   11     format('Initial guess: x = ', e22.15)
#endif

      ! Newton iteration to find a zero of f(x)

      do k=1,maxiter

        ! evaluate function and its derivative:
        fx = f(x, z0, z1, Ri_b)
        fxprime = max(fp(x, z0, z1, Ri_b), 1e-12)
#ifdef DEBUG
        ! print *, "iter=", k, "f=", fx, "f'=", fxprime
#endif
        if (abs(fx) < tol) then
            exit  ! jump out of do loop
        endif

        ! compute Newton increment x:
        deltax = fx/fxprime

        ! update x:
        x = x - deltax

      enddo
#ifdef DEBUG
            print 12, k,x
   12         format('After', i3, ' iterations, x = ', e22.15)
#endif

      if (k > maxiter) then
        ! might not have converged
        fx = f(x, z0, z1, Ri_b)
        if (abs(fx) > tol) then
            print *, '*** Warning: Newton Raphson has not yet converged'
        endif
      endif

      ! number of iterations taken:
      iters = k-1


      end subroutine
