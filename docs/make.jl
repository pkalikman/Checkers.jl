using Documenter, Checkers

makedocs(modules=[Checkers],doctest=true)

deploydocs(deps   = Deps.pip("mkdocs","python-markdown-math"),
           repo   = "github.com/pkalikman/Checkers.jl.git",
           julia  = "0.5.0",
           osname = "osx")
