module LyceumDocs

using Lyceum, Pkg, Documenter, Literate, DevTools, Markdown, YAML
using LyceumBase

const AbsStr = AbstractString
const TupleN{T,N} = NTuple{N,T}

const REPO_DIR = normpath(joinpath(@__DIR__, ".."))
const DOCS_DIR = joinpath(REPO_DIR, "docs")

const SRC_DIR = joinpath(DOCS_DIR, "src")
const STAGING_DIR = joinpath(REPO_DIR, "staging")
const BUILD_DIR = joinpath(REPO_DIR, "build")

const ASSETS_DIR = joinpath(DOCS_DIR, "assets")
const EXAMPLE_DIR = joinpath(DOCS_DIR, "assets/LyceumExamples")

const PATHS = begin
    src = "src"
    static = "static"
    (
        src = src,
        static = static,
        script = joinpath(static, "scripts"),
        notebook = joinpath(static, "notebooks"),
        examples_tarfile = joinpath(static, "examples.tar.gz"),
    )
end


include("document.jl")
include("utils.jl")
include("processors.jl")
include("examples.jl")
include("package_definition.jl")


function make(; clean::Bool = false, skipliterate::Bool = false, config = Dict())
    if isdir(STAGING_DIR) && clean
        @info "Cleaning staging dir ($(STAGING_DIR))"
        println()
        rm(STAGING_DIR, recursive = true, force = true)
    elseif isdir(STAGING_DIR)
        error("$STAGING_DIR exists but clean was false")
    end

    # TODO bundle_examples() fails unless these exist, which only happens if there is
    # at least one example
    mkpath(joinpath(STAGING_DIR, PATHS.script))
    mkpath(joinpath(STAGING_DIR, PATHS.notebook))

    @info "Building Source Tree"
    rootgroup = group(SRC_DIR, skipliterate = skipliterate)
    isempty(rootgroup.children) && error("No source files found in $(SRC_DIR)")

    @info "Processing Files"
    println()
    # disable execution of Jupyter cells for Literate files
    config = Dict("execute" => false)
    process(rootgroup, config = config)

    pages = build_pages(rootgroup)
    isempty(pages) && error("No generated source files found in $(STAGING_DIR)")
    @info "Pages Index:"
    println()
    print_pages(pages)

    @info "Bundling examples"
    println()
    r, status, _, str = Literate.Documenter.withoutput() do
        bundle_examples()
    end
    status || throw(r)

    cp(joinpath(DOCS_DIR, "assets"), joinpath(STAGING_DIR, "assets"))

    @info "Generating Docs"
    println()
    makedocs(;
        # modules = [Lyceum, Lyceum.LYCEUM_PACKAGES...], # TODO
        modules = [LyceumBase, LyceumAI],
        format = Documenter.HTML(
            canonical = "https://docs.lyceum.ml/dev/",
            prettyurls = !islocalbuild(),
        ),
        pages = pages,
        sitename = "Lyceum",
        authors = "Colin Summers",
        strict = false, #!islocalbuild(),  # TODO

        # source/build are specified relative to root
        root = DOCS_DIR,
        build = relpath(BUILD_DIR, DOCS_DIR),
        source = relpath(STAGING_DIR, DOCS_DIR),
    )

    if !islocalbuild()
        @info "Deploying docs"
        deploydocs(
            repo = "github.com/Lyceum/LyceumDocs.jl.git",
            push_preview = true,
            root = DOCS_DIR,
            target = relpath(BUILD_DIR, DOCS_DIR),
        )
    else
        @info "Not deploying docs (local build detected)"
    end
end

end
