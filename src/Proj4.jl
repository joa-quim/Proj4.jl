#__precompile__(true)

module Proj4

using Geodesy


# Find proj.4 C library
const _projdeps = joinpath(dirname(@__FILE__),"..","deps","deps.jl")
if isfile(_projdeps)
    include(_projdeps)
else
    error("Proj4 is not properly installed. Please run Pkg.build(\"Proj4\")")
end


export ProjCRS,
       is_latlong, is_geocent, spheroid_params

       #transform, transform!,  # proj_functions.jl
       #is_latlong, is_geocent, compare_datums, spheroid_params,
       #xy2lonlat, xy2lonlat!, lonlat2xy, lonlat2xy!

#include("projection_codes.jl") # ESRI and EPSG projection strings
include("proj_capi.jl") # low-level C-facing functions (corresponding to src/proj_api.h)
include("proj_types.jl")

function _version()
    m = match(r"(\d+).(\d+).(\d+),.+", pj_get_release())
    VersionNumber(parse(Int, m[1]), parse(Int, m[2]), parse(Int, m[3]))
end

"Parsed version number for the underlying version of libproj"
const version = _version()

@assert version >= v"4.9.0" "proj.4 C library version of at least 4.9.0 is required"


#export geod_direct, geod_inverse, geod_destination, geod_distance
#include("proj_geodesic.jl") # low-level C-facing functions (corresponding to src/geodesic.h)

#include("proj_functions.jl") # user-facing proj functions

end # module
