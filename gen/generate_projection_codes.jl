const FILENAMES = ("epsg",
                   "esri")

parse_comment(line::String) = match(r"^# *(.+)", line)
parse_projection(line::String) = match(r"<(\d+)>\s+(.*?)\s+<>", line)

println("# Contents of this file is generated on $(now()). Do not edit by hand!")
println("# \$ julia generate_projection_codes.jl > projection_codes.jl\n")

for filename in FILENAMES
    if !isfile(filename)
        url = "https://raw.githubusercontent.com/OSGeo/proj.4/master/nad/$filename"
        download(url, filename)
    end
    proj_file = open(filename)
    lines = readlines(proj_file)
    close(proj_file)

    println("$filename = Dict(")
    for i=1:length(lines)
        m = parse_projection(lines[i])
        if is(m, nothing)
            continue
        else
            proj_code, proj_string = m.captures
            comment = parse_comment(lines[i-1])[1]
            @printf("  %s => (\"%s\", \"%s\"),\n", proj_code, proj_string, comment)
        end
    end
    println(")\n")
end
