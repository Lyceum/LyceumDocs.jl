#cfg title = "Workflow Resources"
#cfg weight = 11
#cfg active = true
#cfg deps = ["humanoid.xml"]

# ## Overview

# The official Julia docs has (workflow-tips)[https://docs.julialang.org/en/v1/manual/workflow-tips/]
# that are important to review. Additional important details for newcomers to Julia
# are the (style guide)[https://docs.julialang.org/en/v1/manual/style-guide/] and the list of
# (noteworthy differences)[https://docs.julialang.org/en/v1/manual/noteworthy-differences/] from other languges.

# ## Lyceum Specifics

# Lyceum has been designed to facilitate development of control and reinforcement learning
# algorithms and to deploy results on robotic systems, and more. Workflow for these processes
# involve the management of interaction between an environment (the system model and reward function)
# and a desired algorithm. By using the REPL, controlling this interaction is as simple as editing
# a file of code, `include`ing it in the REPL, and running an associated function.
# For a simple example, lets assume there are two files, `myalgo.jl` and `myenv.jl` where a new algorithm and
# environment are instantiated, and `myalgo.jl` designates a function `testalgo()`

#```julia
#include("myalgo.jl") # reloads the file and any recent changes, ie parameters
#include("myenv.jl")  # reloads the environment
#testalgo()
#```

# One may refer to LyceumAI.jl/src/algorithms/MPPI.jl and environment file provided by LyceumMuJoCo.jl for examples.

# While straight forward, this process the caveat that redefining `struct`s is not allowed by Julia.
# As noted in the Julia workflow tips, one can also do `using Revise` before loading any code,
# which dynamically tracks when loaded modules' files are edited, dynamically recompiling the
# associated functions. As code grows in complexity, it is wise to organize ones code into modules.

