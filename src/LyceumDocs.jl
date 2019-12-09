module LyceumDocs

using Lyceum, Pkg, Documenter, Literate, DevTools, Markdown, YAML

const AbsStr = AbstractString
const TupleN{T, N} = NTuple{N, T}

const REPO_DIR = normpath(joinpath(@__DIR__, ".."))
const DOCS_DIR = joinpath(REPO_DIR, "docs")

const DOCSRC_DIR = joinpath(DOCS_DIR, "src")
const ASSETS_DIR = joinpath(DOCS_DIR, "assets")

const EXAMPLE_DIR = joinpath(DOCS_DIR, "assets/LyceumExamples")

const BUILD_DIR = joinpath(REPO_DIR, "build")
const BUILDS = (:markdown, :script, :notebook)


const UNKNOWN_URL_REGEX = r"<unknown>/([^\"<>#{}:]+\.[^\"<>#{}:\(\)]+)"

const STAGING = begin
    dir = joinpath(REPO_DIR, "staging")
    src = joinpath(dir, "src")
    static = joinpath(src, "static")
    (
        dir=dir,
        src = src,
        static = static,
        build = joinpath(dir, "build"),
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
    if isdir(STAGING.dir) && clean
        @info "Cleaning staging dir ($(STAGING.dir))"
        rm(STAGING.dir, recursive=true, force=true)
    elseif isdir(STAGING.dir)
        error("$STAGING.dir exists but clean was false")
    end

    config = Dict{String, Any}()
    if islocalbuild()
        dir = dirname(REPO_DIR)
        config["repo_root_url"] = dir
        config["nbviewer_root_url"] = dir
        config["binder_root_url"] = dir
        config["repo_root_path"] = dir
    end

    println()
    @info "Building Source Tree"
    rootgroup = group(DOCSRC_DIR)
    isempty(rootgroup.children) && error("No source files found in $(DOCSRC_DIR)")

    println()
    @info "Processing Files"
    process(rootgroup, config=config)

    println()
    pages = build_pages(rootgroup)
    isempty(pages) && error("No generated source files found in $(STAGING.src)")
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
        #modules = [Lyceum, Lyceum.LYCEUM_PACKAGES...],
        format=Documenter.HTML(prettyurls=!islocalbuild()),
        pages = pages,
        sitename = "Lyceum",
        authors = "Colin Summers",

        # source/build are specified relative to root
        root = STAGING.dir,
        build = relpath(STAGING.build, STAGING.dir),
        source = relpath(STAGING.src, STAGING.dir),
        strict = !islocalbuild(),
    )

    println()
    @info "Deploying docs"
    deploydocs(
        repo = "github.com/Lyceum/LyceumDocs.jl.git",
        push_preview=true,
        root = STAGING.dir,
        forcepush = true
    )
end

end
