Roadmap
=======

Done so far
-----------

- Neutral, open and closed channel flow, DNS and LES, with and without Coriolis force

- Implemented constant Smagorinsky, Vreman, shear improved Smagorinsky

- Specifying thermal BC - constant and dynamic fluxes at the bottom (Moeng-like)

- Sponge on top

To do
-----

- Varying thermal roughness height of the Moeng-like thermal flux BC at the bottom to trigger some motions.
  _Don't do it_. :math:`z_os = z_0 / 10`
    + In reality either we iterate between Obhukhov length and the fluxes get
      an agreement. Issue when there is large SGS scale then one can have the
      same flux (:math:`w'\theta'`) for two different  :math:`z / L`.
    + Or use one-to-one relation between flux and gradient Richardson number.
      If this is the Businger-Dyer relation, it is only valid for unstable
      regime.

- Bug fixes on penalty

- Outflow BC

.. todolist::


