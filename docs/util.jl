struct HiddenPage
    page
end

struct HiddenGroup
    root
    children
end

hide(page::Union{Pair,AbstractString}) = HiddenPage(page)
hide(root::Union{Pair,AbstractString}, children) = HiddenGroup(root, children)


process(pages::AbstractVector, lit_config::Dict) = map(p -> process(p, lit_config), pages)

function process(page::AbstractString, lit_config::Dict)
    inputfile = abspath(joinpath(SOURCE, page))
    isfile(inputfile) || error("Not a file: $inputfile")
    outputdir = dirname(abspath(joinpath(STAGING, page)))
    mkpath(outputdir)

    if endswith(inputfile, ".md")
        outputfile = joinpath(outputdir, filename(inputfile))
        doc = preprocess(read(inputfile, String), page)
        doc = add_documenter_editurl(doc, page)
        open(outputfile, "w") do io
            write(io, doc)
        end
        return page
    elseif endswith(inputfile, ".jl")
        Literate.markdown(inputfile, outputdir, config = lit_config)
        return first(splitext(page)) * ".md"
    else
        error("Unknown filetype (should end in .md or .jl): $inputfile")
    end
end

process(page::Pair, lit_config::Dict) = Pair(page.first, process(page.second, lit_config))

process(page::HiddenPage, lit_config::Dict) = Documenter.hide(process(page.page, lit_config))

function process(group::HiddenGroup, lit_config::Dict)
    root = process(group.root, lit_config)
    children = process(group.children, lit_config)
    return Documenter.hide(root, children)
end


function preprocess(doc::String, input_relpath::String)
    doc = replace(doc, "@__LYCEUM_REGISTRY_URL__" => "https://github.com/Lyceum/LyceumRegistry")
    return doc
end

function add_documenter_editurl(doc::String, srcrel::String)
    occursin("EditURL", doc) && error("$buildrel already contains an EditURL")
    """
    ```@meta
    EditURL = "$srcrel"
    ```
    """ * doc
end


islocalbuild() = get(ENV, "GITHUB_ACTIONS", nothing) != "true"
filename(str) = first(splitext(last(splitdir(str))))
