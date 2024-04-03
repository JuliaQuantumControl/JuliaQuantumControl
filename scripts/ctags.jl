include(joinpath(@__DIR__, "installorg.jl"))  # define ORG_PACKAGES

function sort_tags_file(tags)
    lines = readlines("tags")
    sorted_unique_lines = sort!(unique(lines))
    open("tags", "w") do file
        for line in sorted_unique_lines
            if startswith(line, "!_TAG_FILE_SORTED\t0\t")
                line = replace(line, "\t0\t" => "\t1\t")
            end
            println(file, line)
        end
    end
end


function check_ctags_version(tags)
    progname = ""
    open("tags", "r") do file
        for line in eachline(file)
            if !startswith(line, "!_TAG_")
                break
            end
            if startswith(line, "!_TAG_PROGRAM_NAME")
                progname = split(line, "\t")[2]
                if progname != "Universal Ctags"
                    @warn "The 'tags' file was created with $(repr(progname)). You should use the Universal Ctags program"
                end
            end
            if startswith(line, "!_TAG_PROGRAM_VERSION")
                version_string = split(line, "\t")[2]
                m = match(r"\d+\.\d+(\.\d+)?", version_string)
                if m === nothing
                    @warn "Cannot determined version of `ctags` from $(repr(version_string)). You should use the Universal Ctags program in version >= 6.0"
                else
                    version = m.match
                    if VersionNumber(version) < v"6.0.0"
                        @warn "The version of `ctags` is $version. You should use the Universal Ctags program in version >= 6.0"
                    end
                end
            end
        end
    end
    if isempty(progname)
        @warn "Cannot determine program that created 'tags' file. You should use the Universal Ctags program"
    end
end


function create_tags()
    org_root = dirname(@__DIR__)
    folders = [joinpath(org_root, "$package.jl") for package in ORG_PACKAGES]
    src_folders = [joinpath(folder, "src") for folder in folders]
    append!(src_folders, [joinpath(folder, "ext") for folder in folders])
    filter!(isdir, src_folders)
    run(Cmd(["ctags", "--sort=no", "-R", src_folders...]))
    check_ctags_version("tags")
    # Letting `ctags` sort the file was found to be unreliable
    # ("ctags: cannot sort tag file : No such file or directory")
    # Hence, we simply sort the file in Julia
    sort_tags_file("tags")
end
