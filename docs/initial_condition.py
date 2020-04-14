# coding: utf-8
import numpy as np
import matplotlib.pyplot as plt

ym1 = np.linspace(0, 1500, 24*10)


def random_number():
    r = np.random.random(ym1.size)
    return r


KAPPA = 0.41
y0 = 0.1
ux1 = 5 * (0.0445 / KAPPA) * np.log((ym1 + y0) / y0)
ux2 = 5 * ((ym1 / 1500.0) ** (1.0 / 7.0))

rand1 = random_number()
rand2 = random_number()
rand3 = random_number()

ux1 = ux1 + 0.001 * rand1
ux2 = ux2 + 0.001 * rand1
uy = 1e-3 * rand2
uz = 1e-3 * rand3
plt.plot(ym1, ux1, label="ux1")
plt.plot(ym1, ux2, label="ux2")
plt.legend()
plt.show()
