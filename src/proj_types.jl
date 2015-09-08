## Types

# Projection context.  TODO: Will this be exposed?
#type Context
#    rep::Ptr{Void} # Pointer to internal projCtx struct
#end

@doc """
Cartographic projection type
""" ->
type Projection
    #ctx::Context   # Projection context object
    rep::Ptr{Void} # Pointer to internal projPJ struct

    description::String # Description of the projection

    # [geod]: a structure containing the parameters of the spheroid
    # some of the fields in [geod] are mildly duplicative of the information
    # available in [rep], which can be exposed only through _get_spheroid_defn
    geod::_geodesic
end

function Projection(proj_ptr::Ptr{Void}, description::String="")
    proj = Projection(proj_ptr, description, null_geodesic())
    finalizer(proj, freeProjection)
    proj
end

@doc """
Construct a projection from a string in proj.4 "plus format", where each part
of the projection is prefixed with a '+' character.

The projection string `proj_string` is defined in the proj.4 format,
with each part of the projection specification prefixed with '+' character.
For example:

    `wgs84 = Projection("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")`
""" ->
function Projection(proj_string::ASCIIString=""; init::String="", description::String="")
    if !isempty(init)
        pjstr, desc = find_srid(init)
        description = !isempty(description) ? description : desc
        proj_string = pjstr * " " * proj_string
    end
    Projection(_init_plus(proj_string), description)
end

#@doc """
#Construct projection from an srid string.
#
#The string should be in the format AUTHORITY:ID, where AUTHORITY is one of EPSG or 
#""" ->
#function Projection(; srid::String="")
#    Projection(find_srid(srid)...)
#end

function freeProjection(proj::Projection)
    _free(proj.rep)
    proj.rep = C_NULL
end

# Pretty printing
Base.print(io::IO, proj::Projection) = print(io, strip(_get_def(proj.rep)))

function Base.show(io::IO, proj::Projection)
    if !isempty(proj.description)
        print(io, "# $(proj.description)\n")
    end
    print(io, "Projection(\"$proj\")")
end
