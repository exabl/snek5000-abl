import matplotlib.pyplot as plt
import numpy as np


def math_stepf(x):
    xdmin = 0.001
    xdmax = 0.999

    if x <= xdmin:
        result = 0.0
    elif x <= xdmax:
        result = 1.0 / (1.0 + np.exp(1.0 / (x - 1.0) + 1.0 / x))
    else:
        result = 1.0

    return result
    #  return 1.0 / (1.0 + np.exp(1.0 / (x - 1.0) + 1.0 / x))


n = 4 * 8
spng_fun = np.zeros(n)
bmin = 0
bmax = 1
lcoord = np.linspace(bmin, bmax, n, endpoint=True)

# Parameters
spng_str = 1.0
spng_wl = 0.0
spng_dl = 0.0
spng_wr = 0.4
spng_dr = spng_wr * 0.5


# sponge end (drop at xxmin; left)
xxmin = bmin + spng_wl
# beginning of constant part (left)
xxmin_c = xxmin - spng_dl
# sponge beginning (rise at xxmax; right)
xxmax = bmax - spng_wr
# beginning of constant part (right)
xxmax_c = xxmax + spng_dr


# Loop over arrays 😅
for i, rtmp in enumerate(lcoord):
    if rtmp == bmin:  # FIXME: hack at<=t boundary
        rtmp = 0.0
    elif rtmp <= xxmin_c:  # constant; xmin
        rtmp = spng_str
    elif rtmp < xxmin:  # fall; xmin
        arg = (xxmin - rtmp) / (spng_wl - spng_dl)
        rtmp = spng_str * math_stepf(arg)
    elif rtmp <= xxmax:  # zero
        rtmp = 0.0
    elif rtmp < xxmax_c:  # rise
        arg = (rtmp - xxmax) / (spng_wr - spng_dr)
        rtmp = spng_str * math_stepf(arg)
    else:  # constant
        rtmp = spng_str

    spng_fun[i] = max(spng_fun[i], rtmp)


plt.plot(lcoord, spng_fun)
plt.title("Sponge function")
plt.xlabel("z (vertical direction)")
plt.show()
