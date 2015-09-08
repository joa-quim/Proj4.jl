# Dictionaries of ESRI and EPSG projection strings
include("projection_codes.jl")

function authority_srids(authority)
    if authority == "epsg"
        return epsg
    elseif authority == "esri"
        return esri
    else
        error("authority $authority not recognized in srid \"$srid_str\"")
    end
end


@doc """
Resolve SRID into a tuple (proj_string, description)

The input srid string should be in the format "authority:id" where id is an
integer.  The currently supported authorities are epsg, esri.
""" ->
function find_srid(srid_str::String)
    parts = split(srid_str, ':')
    length(parts) == 2 || error("srid string \"$srid_str\" not in the format AUTHORITY:ID")
    authority = lowercase(parts[1])
    srid = parse(Int, parts[2])
    projections = authority_srids(authority)
    haskey(projections, srid) || error("no srid $srid found for authority $authority")
    return projections[srid]
end

@doc """
Search for projections defined by a given authority
""" ->
function search(pattern::Regex, authority="epsg")
    matches = []
    projections = authority_srids(authority)
    for (srid, (pjstr, desc)) in projections
        if ismatch(pattern, desc)
            push!(matches, (srid, pjstr,desc))
        end
    end
    sort!(matches)
    for (srid, pjstr, desc) in matches
        @printf("%s:%-6d -- %-40s \"%s\"\n", authority, srid, desc, pjstr)
    end
    #matches # FIXME
end
