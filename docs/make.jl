using CatmanBinReader
using Documenter

DocMeta.setdocmeta!(CatmanBinReader, :DocTestSetup, :(using CatmanBinReader); recursive=true)

makedocs(;
    modules=[CatmanBinReader],
    authors="Paulo José Saiz Jabardo",
    repo="https://github.com/pjsjipt/CatmanBinReader.jl/blob/{commit}{path}#{line}",
    sitename="CatmanBinReader.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
