function preprocess(doc::String, srcrel::String, buildrel::String)
    doc = replace(doc, "@__LYCEUM_REGISTRY_URL__" => "https://github.com/Lyceum/LyceumRegistry")
    return doc
end

function preprocess(pages)
    for page in pages
        if page isa Pair
            sidebar, page = page
        end

        if page isa AbstractVector
            preprocess(page)
        else
            @assert page isa AbstractString

            src = joinpath(SOURCE, page)
            isfile(src) || error("Not a file: $src")

            if endswith(page, ".jl")
                buildrel = joinpath(first(splitext(page)), ".md")
                error()
            elseif endswith(page, ".md")
                doc = preprocess(read(src, String), page, page)
                doc = add_documenter_editurl(doc, page)
                buildrel = joinpath(STAGING, page)
                mkpath(dirname(buildrel))
                open(buildrel, "w") do io
                    write(io, doc)
                end
            else
                error("Unknown filetype (should end in .md or .jl): $page")
            end
        end
    end
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
