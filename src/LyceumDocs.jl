module LyceumDocs

using Lyceum, Pkg, Documenter, Literate, DevTools, Markdown

const AbsStr = AbstractString
const TupleN{T, N} = NTuple{N, T}

const REPO_DIR = normpath(joinpath(@__DIR__, ".."))
const DOCS_DIR = joinpath(REPO_DIR, "docs")

const DOCSRC_DIR = joinpath(DOCS_DIR, "src")
const ASSETS_DIR = joinpath(DOCS_DIR, "assets")

const EXAMPLE_DIR = joinpath(DOCS_DIR, "assets/LyceumExamples")

const BUILD_DIR = joinpath(REPO_DIR, "build")
const BUILDS = (:documenter, :markdown, :script, :notebook)

const NAME_REGEX = r"^([0-9]+)-(.+)"
const SKIP_REGEX = r"^@.*"
const UNKNOWN_URL_REGEX = r"<unknown>/([^\"<>#{}:]+\.[^\"<>#{}:\(\)]+)"

const STAGING = begin
    dir = joinpath(REPO_DIR, "staging")
    src = joinpath(dir, "src")
    static = joinpath(src, "static")
    examples = joinpath(static, basename(EXAMPLE_DIR))
    (
        dir=dir,
        src = src,
        static = static,
        script = joinpath(static, "scripts"),
        notebook = joinpath(static, "notebooks"),
        examples_tarfile = joinpath(static, "examples.tar.gz")
    )
end


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

    println()
    @info "Processing files"
    process_dir(DOCSRC_DIR, ".", builds=builds, config=config)

    println()
    @info "Generating Page Index"
    isempty(readdir(STAGING.src)) && (@warn "No pages found"; return)
    @info "Pages found:"
    pages = build_pages(STAGING.src, ".")
    print_pages(pages)

    println()
    @info "Bundling examples"
    bundle_examples()

    println()
    @info "Generating Docs"
    makedocs(;
        #modules = [Lyceum, Lyceum.LYCEUM_PACKAGES...],
        format=Documenter.HTML(
            prettyurls=!islocalbuild()
        ),
        pages = pages,
        sitename = "Lyceum",
        authors = "Colin Summers",

        # source/build are specified relative to root
        root = STAGING.dir,
        strict = false,
        #repo = "https://github.com/tkf/Transducers.jl/blob/{commit}{path}#L{line}",
    )

    println()
    @info "Deploying docs"
    deploydocs(
        repo = "github.com/Lyceum/LyceumDocs.jl.git",
        push_preview=true,
        root = STAGING.dir,
    )
end

end
