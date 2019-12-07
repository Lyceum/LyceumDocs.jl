module LyceumExamples

import IJulia

function notebooks()
  IJulia.notebook(dir=joinpath(@__DIR__, "../notebooks"), detached=true)
end

end # module
