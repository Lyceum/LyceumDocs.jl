isliterate(file) = (@assert isfile(file); endswith(file, ".jl"))
ismarkdown(file) = (@assert isfile(file); endswith(file, ".md"))

# For process_literate and process_markdown, full path to srcfile is joinpath(root, rel_srcfile)
function process_literate(root, rel_srcfile, srcdir, markdowndir, scriptdir, notebookdir)
    abs_srcfile = joinpath(root, rel_srcfile)
    rel_srcdir = dirname(rel_srcfile)

    @assert isdir(root)
    @assert isliterate(abs_srcfile)

    # Copy over source file and use that file instead for correct EditURL
    abs_srcfile = cp(abs_srcfile, joinpath(srcdir, basename(abs_srcfile)))

    markdown_dstdir = joinpath(markdowndir, rel_srcdir)
    mkpath(markdown_dstdir)
    Literate.markdown(abs_srcfile, markdown_dstdir; documenter = true)

    script_dstdir = joinpath(scriptdir, rel_srcdir)
    mkpath(script_dstdir)
    Literate.script(abs_srcfile, script_dstdir)

    notebook_dstdir = joinpath(notebookdir, rel_srcdir)
    mkpath(notebook_dstdir)
    Literate.notebook(abs_srcfile, notebook_dstdir)
end

function process_markdown(root, rel_srcfile, markdowndir)
    abs_srcfile = joinpath(root, rel_srcfile)
    abs_dstfile = joinpath(markdowndir, rel_srcfile)
    mkpath(dirname(abs_dstfile))
    @info "Copying Markdown file $abs_srcfile to $abs_dstfile"
    cp(abs_srcfile, abs_dstfile)
end

# Full path is joinpath(root, dir)
function process_dir(root, dir, markdowndir, scriptdir, notebookdir)
    seen = Set{Int}()
    abs_dir = normpath(joinpath(root, dir))
    for file_or_dir in readdir(abs_dir)
        abs_path = normpath(joinpath(abs_dir, file_or_dir))
        idtitle = parse_filename(abs_path)
        if isnothing(idtitle)
            @warn "Skipping $abs_path: does not match $NAME_REGEX"
            continue
        else
            id, title = idtitle
            if id in seen
                @warn "Skipping $abs_path duplicate page or section id: $id"
                continue
            else
                push!(seen, id)
                rel_path = normpath(joinpath(dir, file_or_dir))
                if isdir(abs_path)
                    process_dir(root, rel_path, markdowndir, scriptdir, notebookdir)
                elseif isliterate(abs_path)
                    process_literate(root, rel_path, markdowndir, scriptdir, notebookdir)
                elseif ismarkdown(abs_path)
                    process_markdown(root, rel_path, markdowndir)
                else
                    @warn "Skipping $abs_path: file does not end with .md or .jl"
                end
            end
        end
    end
end

function parse_filename(filename)
    m = match(NAME_REGEX, basename(filename))
    if isnothing(m)
        return nothing
    else
        id = parse(Int, m[1])
        title = replace(splitext(m[2])[1], '_'=>' ')
        return id, title
    end
end

function build_pages(root, dir)
    pages = Vector{Tuple{Int, String, Union{String, Vector}}}() # (id, title, page_or_section)
    abs_dir = normpath(joinpath(root, dir))
    for file_or_dir in readdir(abs_dir)
        abs_path = normpath(joinpath(abs_dir, file_or_dir))
        idtitle = parse_filename(file_or_dir)
        if isnothing(idtitle)
            @info "Skipping index entry $idtitle: does not match $NAME_REGEX"
            continue
        else
            id, title = idtitle
        end

        if isfile(abs_path)
            if ismarkdown(abs_path)
                # Only add markdown files to index
                page_or_section = relpath(abs_path, root)
            else
                continue
            end
        elseif isdir(abs_path)
            page_or_section = build_pages(root, joinpath(dir, file_or_dir))
        else
            error("$abs_path does not exist")
        end
        push!(pages, (id, title, page_or_section))
    end
    sort!(pages, by=first)
    pages = map(pages) do (_, title, page_or_section)
        title => page_or_section
    end
    return pages
end

function indented_println(xs...; indent = 0)
    for _ = 1:(Base.indent_width*indent)
        print(' ')
    end
    println(xs...)
end

function print_pages(index, indent=0)
    for (title, page_or_section) in index
        if page_or_section isa String
            indented_println(title, " => ", page_or_section, indent=indent)
        else
            indented_println(title, indent=indent)
            print_pages(page_or_section, indent + 1)
        end
    end
end

function lowercaseify!(srcdir)
    @assert isdir(srcdir)
    mktempdir() do tmpdir
        for (root, _, files) in walkdir(srcdir), file in files
            abs_srcpath = joinpath(root, file)
            rel_path = relpath(abs_srcpath, srcdir)
            abs_outpath = joinpath(tmpdir, lowercase(rel_path))
            mkpath(dirname(abs_outpath))
            cp(abs_srcpath, abs_outpath)
        end
        rm(srcdir, force=true, recursive=true)
        cp(tmpdir, srcdir)
    end
end
