module LyceumDocs

using Lyceum, Pkg, Documenter, Literate, DevTools, Markdown, YAML

const AbsStr = AbstractString
const TupleN{T, N} = NTuple{N, T}

const REPO_DIR = normpath(joinpath(@__DIR__, ".."))
const DOCS_DIR = joinpath(REPO_DIR, "docs")

const SRC_DIR = joinpath(DOCS_DIR, "src")
const STAGING_DIR = "staging"
const BUILD_DIR = "build"

const ASSETS_DIR = joinpath(DOCS_DIR, "assets")
const EXAMPLE_DIR = joinpath(DOCS_DIR, "assets/LyceumExamples")

const BUILDS = (:markdown, :script, :notebook)

const PATHS = begin
    src = "src"
    static = "static"
    (
        src = src,
        static = static,
        script = joinpath(static, "scripts"),
        notebook = joinpath(static, "notebooks"),
        examples_tarfile = joinpath(static, "examples.tar.gz")
    )
end


include("document.jl")
include("utils.jl")
include("processors.jl")
include("examples.jl")
include("package_definition.jl")


function make(; clean::Bool=false, builds::TupleN{Symbol} = BUILDS)
    if isdir(STAGING_DIR) && clean
        @info "Cleaning staging dir ($(STAGING_DIR))"
        rm(STAGING_DIR, recursive=true, force=true)
    elseif isdir(STAGING_DIR)
        error("$STAGING_DIR exists but clean was false")
    end

    config = Dict{String, Any}("execute" => false)

    println()
    @info "Building Source Tree"
    rootgroup = group(SRC_DIR)
    isempty(rootgroup.children) && error("No source files found in $(SRC_DIR)")

    println()
    @info "Processing Files"
    process(rootgroup, config=config)

    println()
    pages = build_pages(rootgroup)
    isempty(pages) && error("No generated source files found in $(STAGING_DIR)")
    @info "Pages Index:"
    print_pages(pages)

    println()
    @info "Bundling examples"
    r, status, _, str = Literate.Documenter.withoutput() do
        bundle_examples()
    end
    status || throw(r)

    println()
    @info "Generating Docs"
    makedocs(;
        #modules = [Lyceum, Lyceum.LYCEUM_PACKAGES...], # TODO
        format=Documenter.HTML(
            canonical="https://docs.lyceum.ml/dev/",
            prettyurls=!islocalbuild()
        ),
        pages = pages,
        sitename = "Lyceum",
        authors = "Colin Summers",
        strict = false, #!islocalbuild(),
        # source/build are specified relative to root
        root = DOCS_DIR,
        build = relpath(BUILD_DIR, DOCS_DIR),
        source = relpath(STAGING_DIR, DOCS_DIR),
    )
    println()
    @info "Deploying docs"
    deploydocs(
        repo = "github.com/Lyceum/LyceumDocs.jl.git",
        push_preview=true,
        root = DOCS_DIR,
        target = relpath(BUILD_DIR, DOCS_DIR),
    )
end

end
