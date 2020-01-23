```@cfg
title = "Model-Predictive Path Integral Control"
short_title = "MPPI"
weight = 20
active = false
```

Implements Model-Predictive Path Integral Control, a stochastic sampling based model
predictive control method. For further information
(https://www.cc.gatech.edu/~bboots3/files/InformationTheoreticMPC.pdf

```@docs
MPPI
getaction!(::AbstractVector, ::Any, ::MPPI)
```