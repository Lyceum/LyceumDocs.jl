```@cfg
title = "Policies"
weight = 10
```

```@meta
CurrentModule = LyceumDocs.LyceumAI
```

## DiagGaussianPolicy

```@docs
DiagGaussianPolicy
DiagGaussianPolicy(::Any, ::AbstractVector)
sample!(::AbstractRNG, ::AbsVec, ::DiagGaussianPolicy, ::AbsVec)
getaction!(::AbsVec, ::DiagGaussianPolicy, ::AbsVec)
loglikelihood
```