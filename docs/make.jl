using Documenter, Checkers

makedocs(modules  = [Checkers],
         doctest  = true,
         clean    = false,
         sitename = "Checkers.jl",
         format   = Documenter.Formats.HTML,
         pages    = Any["Introduction" = >"index.md",
                        "Macros"=>Any["@test_forall"=>"test-forall.md"
                                      "@test_exists"=>"test-exists.md"
                                      "@test_formany"=>"test-formany.md"],
                        "About"=>Any["License"=>"LICENSE.md"]]
        )

deploydocs(deps   = Deps.pip("mkdocs","python-markdown-math"),
           repo   = "github.com/pkalikman/Checkers.jl.git",
           target = "build",
           julia  = "0.5.0")
