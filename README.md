[![Build Status](https://travis-ci.org/jhlq/LightLite.jl.svg?branch=master)](https://travis-ci.org/jhlq/LightLite.jl)

# LightLite.jl
Install by:
```
import Pkg
Pkg.add(Pkg.PackageSpec(url="https://github.com/jhlq/LightLite.jl", rev="master"))
using LightLite
```

To start either call example() or open a blank board with:
```
screen=newScreen();
```

Click on the grid to place emitters and other components selected with the "Place" combobox, then press Step to propagate the photons. To reemit first press Reset. CTRL-click on emitters to flip their output, equivalent to applying an X gate.

The order in which emitters are placed matters, if photons enter a cnot at the same step the one with the lowest index becomes control and the next target, additional photons are unaffected.

A qubit is like two connected compasses, the size of the first compass is the probability of the qubit being a 0 and the size of the second compass is the probability of 1. Moving the needle around controls a complex number: if the compass points east the imaginary part is zero and north means the real part is zero.

The two compasses can be represented by a vector in a sphere, for example a clock where the hands can point out. Two complex numbers are encoded with three parameters by only considering the difference between them: if the two compasses are spun at the same speed the hand of the clock wont move.

S=rz(pi/2), S†=rz(-pi/2), T=rz(pi/4), T†=rz(-pi/4).

Useful links:  
https://algassert.com/quirk  
https://www.st-andrews.ac.uk/physics/quvis/simulations_html5/sims/blochsphere/blochsphere.html
