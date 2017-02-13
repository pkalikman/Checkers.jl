using Documenter, Checkers

makedocs(modules  = [Checkers],
         doctest  = false)

deploydocs(deps   = Deps.pip("mkdocs", "mkdocs-material" ,"python-markdown-math", "pygments"),
           repo   = "github.com/pkalikman/Checkers.jl.git",
           target = "build",
           julia  = "0.5",
           osname = "linux")
