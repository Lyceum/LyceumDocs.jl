abstract type Node end

struct Group <: Node
    root::String
    rel_path::String
    children::Vector{Node}
    config::Dict{Symbol, Any}
end

struct Document <: Node
    root::String
    rel_path::String
    kind::Symbol
    config::Dict{Symbol, Any}
end


const CONFIG_DEFAULTS = Dict(
    :active => true,
    :builds => BUILDS,
    :hide => false,
    :short_title => :use_title,
    :title => nothing,
    :weight => nothing
)

function inheritconfig!(dst, src)
    for k in (:active, :builds, :hide)
        dst[k] === nothing && (dst[k] = src[k])
    end
end

function check_config(config)
    config[:short_title] === :use_title && (config[:short_title] = config[:title])
    for (k, v) in pairs(config)
        v === nothing && error("Missing config parameter $k")
    end
end

function group(root)
    config = parsefile_config(joinpath(root, "config.jl"))
    check_config(config)

    grp = Group(root, ".", Node[], config)

    for child in readdir(root)
        if child == "config.jl"
            continue
        elseif isdir(joinpath(root, child))
            push!(grp.children, group(child, grp))
        else
            push!(grp.children, document(child, grp))
        end
    end
    grp
end


function group(rel_path, parent::Group)
    config = parsefile_config(joinpath(parent.root, rel_path, "config.jl"))
    inheritconfig!(config, parent.config)
    check_config(config)

    grp = Group(parent.root, rel_path, Node[], config)

    for child in readdir(joinpath(parent.root, rel_path))
        if child == "config.jl"
            continue
        else
            child = joinpath(rel_path, child)
            if isdir(joinpath(parent.root, child))
                push!(grp.children, group(child, grp))
            else
                push!(grp.children, document(child, grp))
            end
        end
    end
    grp
end

function document(rel_path, parent::Group)
    kind, config, body = parse_file(joinpath(parent.root, rel_path))
    inheritconfig!(config, parent.config)
    check_config(config)
    Document(parent.root, rel_path, kind, config)
end


function parse_file(path)
    try
        content = read(path, String)
        if isliterate(path, content)
            kind = :literate
            config, body = parse_literate(content)
        elseif isdocumenter(path, content)
            kind = :documenter
            config, body = parse_documenter(content)
        else
            error("Expected either a Documenter or Literate formatted file")
        end
        return kind, parse_config(config), body
    catch e
        error("""
             $(sprint(showerror, e))
             while processing $path
             """)
    end
end


function parse_documenter(content::String)
    md = Markdown.parse(content)
    body_blocks, content_blocks = Markdown.Code[], []
    for block in md.content
        if block isa Markdown.Code && block.language == "@cfg"
            push!(body_blocks, block)
        else
            push!(content_blocks, block)
        end
    end
    config = join(map(b->b.code, body_blocks), '\n') * '\n'
    body = string(Markdown.MD(content_blocks))
    (config=config, body=body)
end


function parse_literate(content::String)
    lines = collect(eachline(IOBuffer(content)))
    config, body = String[], String[]
    for line in lines
        line = rstrip(line)
        m = match(r"^#cfg\h*(?<content>.+)", line)
        if m === nothing
            push!(body, line)
        else
            push!(config, rstrip(m[:content]))
        end
    end

    if isempty(config)
        error("No #cfg lines found")
    else
        config = join(config, '\n') * '\n'
        body = join(body, '\n') * '\n'
        return (config=config, body=body)
    end
end

function parsefile_config(path)
    try
        return parse_config(read(path, String))
    catch e
        error("""
             $(sprint(showerror, e))
             while parsing $path
             """)
    end
end

function parse_config(config_block::String)
    mod = execute_block(config_block)
    config = Dict{Symbol, Any}()
    for k in keys(CONFIG_DEFAULTS)
        if isdefined(mod, k)
            config[k] = getfield(mod, k)
        else
            config[k] = CONFIG_DEFAULTS[k]
        end
    end
    config
end

ismarkdown(path, content) = endswith(path, ".md")
isliterate(path, content) = endswith(path, ".jl")
isdocumenter(path, content) = ismarkdown(path, content)