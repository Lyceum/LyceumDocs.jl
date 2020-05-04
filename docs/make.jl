using Documenter
using Literate

using LyceumBase
using LyceumMuJoCo
using LyceumAI

const REPO_ROOT = joinpath(@__DIR__, "..")
const DOCS = @__DIR__
const EXAMPLES = joinpath(REPO_ROOT, "examples")
const SOURCE = joinpath(DOCS, "src")
const BUILD = joinpath(DOCS, "build")
const STAGING = joinpath(DOCS, "staging")

include("util.jl")

PAGES = [
   "Home" => "index.md",
   "Basics" => [
       "Environment Interface" => "basics/environmentinterface.md"
    ],
    "MuJoCo Environments" => [
        "Overview" => "mujocoenvironments/overview.md",
        "Environments" => "mujocoenvironments/environments.md",
        "Visualization" => "mujocoenvironments/visualization.md",
    ],
    "LyceumAI" => [
        "Overview" => "lyceumai/overview.md",
        "Algorithms" => [
            "Model Predictive Path Integral Control" => "lyceumai/algorithms/mppi.md",
            "Natural Policy Gradient" => "lyceumai/algorithms/naturalpolicygradient.md",
        ],
        "Models" => [
            "Policies" => "lyceumai/models/policies.md",
        ],
    ]
]

EXAMPLES = [
    "Creating a MuJoCo Environment" => "humanoid.jl"
]

function make(;
    clean::Bool = false,
    skipliterate::Bool = false,
    literate_config::AbstractDict = Dict(),
    fast::Bool = false,
)
    for dir in (BUILD, STAGING)
        if clean
            rm(dir, recursive = true, force = true)
        elseif isdir(dir)
            error("$dir exists. Set clean=true to remove it.")
        end
    end
    cp(SOURCE, STAGING)

    config = Dict()
    if fast
        config["codefence"] = "```julia" => "```"
    end

    preprocess(PAGES)

    makedocs(;
        modules = [
            LyceumBase,
            LyceumMuJoCo,
            LyceumAI,
        ],
        format = Documenter.HTML(
            canonical = "https://docs.lyceum.ml/stable/",
            prettyurls = !islocalbuild(),
            assets = ["assets/custom.css"],
        ),
        pages = PAGES, # TODO examples
        sitename = "Lyceum",
        authors = "Colin Summers",
        strict = false, #!islocalbuild(),  # TODO

        # source/build are specified relative to root
        root = DOCS,
        build = relpath(BUILD, DOCS),
        source = relpath(STAGING, DOCS),
    )

    if !islocalbuild()
        @info "Deploying docs"
        deploydocs(
            #repo = "github.com/Lyceum/LyceumDocs.jl.git",
            repo = "https://github.com/Lyceum/LyceumDocs.jl/blob/{commit}{path}#L{line}",
            push_preview = true,
            root = DOCS,
        )
    else
        @info "Not deploying docs (local build detected)"
    end
end
