using TOML
folders = filter(x -> isdir(x) && endswith(x, ".jl"), readdir("."))
dependencies = Dict(
    chop(f, tail=3) => keys(TOML.parsefile(joinpath(f, "Project.toml"))["deps"]) for
    f in folders
)
print("dependencies = ")
display(dependencies)
println("")
ok = true
for project in keys(dependencies)
    for dep in dependencies[project]
        if project in get(dependencies, dep, [])
            println("ERROR: $project and $dep have a circular dependency")
            global ok = false
        end
    end
end
ok && println("OK")
