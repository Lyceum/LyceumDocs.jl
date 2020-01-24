function preprocess(s::String, doc::Document; config::Dict = Dict())
    # order matters for the following string transformations!

    abs_src = joinpath(doc.root, doc.rel_path)
    rel_base = first(splitext(doc.rel_path))
    repo_root = get(config, "repo_root_path", REPO_DIR)
    repo_root_url = get(config, "repo_root_url", "<unknown>")
    filename = Literate.filename(abs_src)
    relrepo_path = relpath(abs_src, repo_root)

    s = replace(s, "@__FILE_URL__" => "@__REPO_ROOT_URL__/$(relrepo_path)")
    s = replace(s, "@__FILE__" => relrepo_path)
    exfile = joinpath(REPO_DIR, PATHS.examples_tarfile)
    rel_exfile = relpath(exfile, abs_src)
    #error(rel_exfile)
    #s = replace(s, "@__EXAMPLES__" => PATHS.examples_tarfile)
    s = replace(s, "@__EXAMPLES__" => rel_exfile)
    s = replace(
        s,
        "@__EXAMPLES_README__" => read(joinpath(EXAMPLE_DIR, "README.md"), String),
    )

    if doc.kind === :documenter
        s = parse_documenter(s).body
        s = add_documenter_title(s, doc.config[:title])
        # Since we are doing an out-of-source build
        # we need to add correct EditURL for Documenter
        s = add_documenter_editurl(s)
            s = add_literate_examples_header(s, repo_root, abs_src)
    elseif doc.kind === :literate
        s = parse_literate(s).body
        s = add_literate_title(s, doc.config[:title])
            s = add_literate_examples_header(s, repo_root, abs_src)
        if :script in doc.config[:builds] || :notebook in doc.config[:builds]
            # If we are building executable scripts/notebooks, add admonition at top of file
            # linking to examples
            s = add_literate_examples_header(s, repo_root, abs_src)
        end
    else
        error("Unknown document kind: $(doc.kind)")
    end

    s
end

function add_documenter_editurl(content::String)
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

function add_literate_examples_header(content::String, repo_root, abs_src)
    #examplehowto = joinpath(SRC_DIR, "examples/example_howto.md")
    #@assert isfile(examplehowto)
    #path = relpath(examplehowto, abs_src)
    # TODO
    examplehowto = "https://docs.lyceum.ml/dev/examples/example_howto/"
    """
    #md # !!! note "Running examples locally"
    #md #     This example and more are also available as Julia scripts and Jupyter notebooks.
    #md #
    #md #     See [the how-to page]($(examplehowto)) for more information.
    #md #
    """ * content
end

function add_literate_title(content::String, title::String)
    """
    #md # # $title

    """ * content
end
function add_documenter_title(content::String, title::String)
    """
    # $title

    """ * content
end
