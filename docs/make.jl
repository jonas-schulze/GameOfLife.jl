using Documenter
using GameOfLife

makedocs(
    sitename = "GameOfLife.jl",
    format = Documenter.HTML(),
    modules = [GameOfLife],
    pages = [
        "Introduction" => "index.md",
        "API" => "api.md",
    ],
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
