using Documenter, Checkers

makedocs(modules  = [Checkers],
         doctest  = false,
         clean    = true,
         #format   = :html,
         sitename = "Checkers.jl",
         authors  = "Philip Kalikman, Efim Abrikosov",
         html_prettyurls = !("local" in ARGS),
         #pages    = Any[
         #               "Home" => "index.md",
         #               "Macros" => Any["macros/test-forall.md",
         #                               "macros/test-formany.md",
         #                               "macros/test-exists.md"]
         #           ]
)

deploydocs(deps   = Deps.pip("mkdocs", "mkdocs-material" ,"python-markdown-math", "pygments"),
           repo   = "github.com/pkalikman/Checkers.jl.git",
           target = "site",
           julia  = "0.6",
           latest = "master",
           osname = "linux")
