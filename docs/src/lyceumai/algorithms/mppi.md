# Model-Predictive Path Integral Control

Implements Model-Predictive Path Integral Control, a stochastic sampling based model
predictive control method. For further information, see the following papers:
- [Information Theoretic MPC for Model-Based Reinforcement Learning](https://homes.cs.washington.edu/~bboots/files/InformationTheoreticMPC.pdf)
- [Aggressive Driving with Model Predictive Path Integral Control](https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=7487277)

```@meta
CurrentModule = LyceumAI
```

```@docs
MPPI
getaction!(::AbstractVector, ::Any, ::MPPI)
reset!(::MPPI)
```
