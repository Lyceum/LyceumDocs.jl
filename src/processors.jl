# For Jupyter notebooks, apply post-processing to each cell individually
function postprocess(notebook::Dict, args...; kwargs...)
    for cell in notebook["cells"], i in eachindex(cell["source"])
        cell["source"][i] = postprocess(cell["source"][i], args...; kwargs...)
    end
    notebook
end


function preprocess(s::String, doc::Document; config::Dict=Dict())
    s = add_title(s, doc.config[:title])

    if doc.kind === :documenter
        s = parse_documenter(s).body
        s = add_editurl(s)
    elseif doc.kind === :literate
        s = parse_literate(s).body
        if :script in doc.config[:builds] || :notebook in doc.config[:builds]
            s = add_examples_header(s)
        end
    else
        error("Unknown document kind: $(doc.kind)")
    end
    s
end

function postprocess(s::String, doc::Document; config::Dict=Dict())
    abs_src = joinpath(doc.root, doc.rel_path)
    rel_base = first(splitext(doc.rel_path))

    repo_root = get(config, "repo_root_path", REPO_DIR)
    repo_root_url =  get(config, "repo_root_url", "<unknown>")

    filename = Literate.filename(abs_src)
    relrepo_path = relpath(abs_src, repo_root)

    s = replace(s, "@__FILE_URL__" => "@__REPO_ROOT_URL__/$(relrepo_path)")
    s = replace(s, "@__FILE__" => relrepo_path)
    s = replace(s, "@__EXAMPLES__" => PATHS.examples_tarfile)
    s = replace(s, "@__EXAMPLES_README__" => read(joinpath(EXAMPLE_DIR, "README.md"), String))

    if doc.kind === :documenter
        # nothing
    elseif doc.kind === :literate
        notebook_path = joinpath(PATHS.notebook, rel_base * ".ipynb")
        s = replace(s, "@__NOTEBOOK__" => notebook_path)

        script_path = joinpath(PATHS.script, rel_base * ".jl")
        s = replace(s, "@__SCRIPT__" => script_path)
    else
        error("Unknown document kind: $(doc.kind)")
    end

    s
end



function add_editurl(content::String)
    if occursin("EditURL", content)
        print(content)
        error("$path already contains an EditURL")
    end
    """
    ```@meta
    EditURL = "@__FILE_URL__"
    ```
    """ * content
end

function add_examples_header(content::String)
    """
    #md # !!! note "Running examples locally"
    #md #     This example and more are also available as Julia scripts and Jupyter notebooks.
    #md #
    #md #     See [the how-to page](example_howto.md) for more information.
    #md #
    """ * content
end

function add_title(content::String, title::String)
    """
    #md # # $title

    """ * content
end