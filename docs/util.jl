function preprocess(doc::String, input_relpath::String)
    doc = replace(doc, "@__LYCEUM_REGISTRY_URL__" => "https://github.com/Lyceum/LyceumRegistry")
    return doc
end

function process(pages::AbstractVector, literate_config::Dict=Dict())
    staged = []
    for page in pages
        pagename, page = page isa Pair ? (page.first, page.second) : (nothing, page)

        if page isa AbstractVector # Nested subpage
            page = process(page)
        elseif page isa AbstractString
            inputfile = abspath(joinpath(SOURCE, page))
            isfile(inputfile) || error("Not a file: $inputfile")
            relinputfile = relpath(inputfile, SOURCE)
            outputdir = dirname(abspath(joinpath(STAGING, page)))
            mkpath(outputdir)

            if endswith(page, ".md")
                outputfile = joinpath(outputdir, filename(page))
                doc = preprocess(read(inputfile, String), relinputfile)
                doc = add_documenter_editurl(doc, page)
                open(outputfile, "w") do io
                    write(io, doc)
                end
            elseif endswith(page, ".jl")
                page = first(splitext(page)) * ".md"
                Literate.markdown(inputfile, outputdir, config = literate_config)
            else
                error("Unknown filetype (should end in .md or .jl): $page")
            end
        else
            error("Pages should be specified as a filepath, `Pair(pagename,filepath)`, or a vector of either.")
        end

        page = pagename === nothing ? page : Pair(pagename, page)
        push!(staged, page)
    end

    return staged
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
