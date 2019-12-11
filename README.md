# Lyceum

![](https://github.com/Lyceum/LyceumDocs.jl/workflows/CI/badge.svg)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://lyceum.github.io/LyceumDocs.jl/dev/)

LyceumDocs.jl is part of the Lyceum eco-system and [contains the documentation](https://lyceum.github.io/LyceumDocs.jl/dev/) for several of the packages it is comprised of, alongside tutorials. To contribute, see below.


## Contributing

## Literate and Documenter

The documentation contained in LyceumDocs.jl is written with one of two packages:

1. [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) formatted Markdown, used primarily for auto-generated docstrings or docs which don't feature a lot of source code examples.
2. [Literate.jl](https://github.com/fredrikekre/Literate.jl) formatted `.jl` scripts, designed for [Literate programming](https://en.wikipedia.org/wiki/Literate_programming) and used when docs are comprised largely of Julia source code, like tutorials. Literate allows you to generate Markdown, regular `.jl` scripts, and IPython notebooks from a single source file.

Each has their pros and cons, and the syntax is similar enough that switching between them is fairly seamless. See each package's documentation to get a better idea of what their respective pros and cons are, as well as how to use them.

## Adding documentation

Once you've chosen which syntax you'll use, go ahead and create the respective `.md` (for Documenter) or `.jl` (for Literate) file under `docs/src`. Files within sub-folders denote sub-pages of the parent folder. For example, the following would result in one top-level, `index.md`, along with a single group containing a single sub-page, `foo/bar.jl`:

```
index.md
foo/bar.jl
```

How a document file is processed and built is controlled by the following parameters:

* `active::Bool`: This document is skipped iff `active` is true. Defaults to `true`.
* `builds::Tuple`: Controls what build products should be genereated from this source file. The default is all build products, e.g. `(:markdown, :notebook, :script)`. Note that `:notebook` and `:script` are ignored for Documenter/`.md` source.
* `hide::Bool`: Whether this page should be displayed in the side bar or not. Defaults to `true`.
* `title::String`: The title for this document. A Markdown H1 header containing this title is automatically added. Required.
* `short_title::Union{String, Symbol}`: The title displayed in the sidebar. If set to `:use_title`, then the title defined above is used. Defaults to `:use_title`.
* `weight::Int`: Controls the order in which pages are displayed in the sidebar. Required.

For Literate/`.jl` files, this is controlled by a header at the top of the file that looks like:
```
#cfg title = "Running a simple controller"
#cfg weight = 10
```

And for Documenter/`.md` files:
````
```@cfg
title = "Home"
weight = 1
```
````

Each sub-folder should also contain a `config.jl` with `title` and `weight` defined as well, which controls the title and order that the group of sub-pages appears in, as well as any defaults for sub-pages contained within:
```
title = "Home"
weight = 1
active = false # defaults all sub-pages in this folder to have active=false
```

## Building the docs

Once you've created your source file, run `julia --project` in the root of this folder and run:

```julia
julia> using LyceumDocs
julia> LyceumDocs.make(clean=true)
```

Which will delete any existing build products and generate the documentation in a new folder: `build`. You can examine the page locally by opening `build/index.html` in your browser. Note that links are often broken when built locally. You can also find the generated scripts and notebooks under `build/static/{notebook, script}`.
