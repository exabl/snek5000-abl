Roadmap
=======

Done so far
-----------

- Neutral, open and closed channel flow, DNS and LES, with and without Coriolis force

- Implemented constant Smagorinsky, Vreman, shear improved Smagorinsky

- Specifying thermal BC - constant and dynamic fluxes at the bottom (Moeng-like)

- Sponge on top

- Stratification correction terms in the boundary condition

To do
-----

- Varying thermal roughness height of the Moeng-like thermal flux BC at the bottom to trigger some motions.
  *Don't do it*. :math:`z_{os} = z_0 / 10`

    + In reality either we iterate between Obhukhov length and the fluxes get
      an agreement. Issue when there is large SGS scale then one can have the
      same flux (:math:`w'\theta'`) for two different  :math:`z / L`.
    + Or use one-to-one relation between flux and gradient Richardson number.
      If this is the Businger-Dyer relation, it is only valid for unstable
      regime.

- Bug fixes on penalty

- Outflow BC

- Implement horizontal spectra postprocessing

     + Simulate with decaying grid turbulence and compare spectra (Rozema et al., 2015)

- First LES + stratification using Vreman SGS model + Turbulent Prandtl number

     + Convectively neutral case
     + GABLS1 moderately stable stratification case

- Explore replacements for a sponge region with outflow boundary conditions.

- Explore other SGS models if needed. For example (Deardorff, 1980) model, Algebraic Minimum Dissipation (Rozema et al., 2015)

- LES of unstable, convective boundary layer

- LES of strong stratification:
  + GABLS4 case (Couvreux et al., 2020)

- Diurnal cycle setup

.. todolist::


