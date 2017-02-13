using Documenter, Checkers

makedocs(modules  = [Checkers],
         sitename = "Checkers.jl",
         pages    = Any[
               "Introduction" => "index.md",
               "Macros"       => Any[
                   "@test_forall"  => "macros/test-forall.md",
                   "@test_exists"  => "macros/test-exists.md",
                   "@test_formany" => "macros/test-formany.md"
                ],
                "About"       => Any[
                   "License"       => "LICENSE.md"
                ]
           ])

deploydocs(deps   = Deps.pip("mkdocs", "mkdocs-material" ,"python-markdown-math", "pygments"),
           repo   = "github.com/pkalikman/Checkers.jl.git",
           target = "build",
           julia  = "0.5",
           osname = "linux")
