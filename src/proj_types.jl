#=
immutable SRID
    auth::Symbol
    id::Int
end

SRID() = SRID(:UNDEF, -1)
=#


type ProjCRS
    ptr::Ptr{Void} # Pointer to internal projPJ struct

    function ProjCRS(proj_ptr::Ptr{Void})
        crs = new(proj_ptr)
        finalizer(crs, c->(pj_free(c.ptr); c.ptr = C_NULL))
        crs
    end
end


"""
    ProjCRS(proj_string)

Construct a Coordinate Reference System from a string given in proj.4
"plus format".

The proj.4 string format is a space separated list of key-value pairs and
options, each prefixed with a `+`.  For example:

    wgs84 = ProjCRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")

Here's a big ugly list of all the options used in the proj.4 strings
distributed with the C library.  Some information about these can be found at
https://trac.osgeo.org/proj/wiki/FAQ.

+a +alpha +axis +b +datum +ellps +gamma +geoidgrids +k +k_0
+lat_0 +lat_1 +lat_2 +lat_ts +lon_0 +lonc +nadgrids +no_defs +no_uoff
+pm +proj +R_A +rf +south +title +to_meter +towgs84 +units +vunits
+wktext +x_0 +y_0 +zone
"""
ProjCRS(proj_string::AbstractString) = ProjCRS(pj_init_plus(proj_string))


# Pretty printing
Base.print(io::IO, crs::ProjCRS) = print(io, strip(pj_get_def(crs.ptr)))
Base.show(io::IO, crs::ProjCRS) = print(io, "ProjCRS(\"$crs\")")


"""
    latlon_crs(crs::ProjCRS)

Return the latitude-longitude coordinate reference system on which `crs` is
based.  If the coordinate system passed in is latlong, a clone of the same will
be returned.
"""
latlong_crs(crs::ProjCRS) = ProjCRS(pj_latlong_from_proj(crs.ptr))


#-------------------------------------------------------------------------------
# Information about Coordinate Reference Systems

"""
Return true if the coordinate system is latitude-longitude.
"""
is_latlong(crs::ProjCRS) = _is_latlong(crs.ptr)


"""
Return true if the coordinate system is Cartesian geocentric.
"""
is_geocent(crs::ProjCRS) = pj_is_geocent(crs.ptr)


"""
Return true if the datums for the two projections are the same.

proj.4 identifies datums by the way they transform to a central CRS, which is a
combination of the +towgs84 option (for geocentric datum shift parameters) and
the +nadgrids option (for an arbitrary gridded transformation).

considers two datums to be the same if they have the same set of
transformation parameters 
"""
compare_datums(p1::ProjCRS, p2::ProjCRS) = pj_compare_datums(p1.ptr, p2.ptr)


"""
Return the definition of the ellipsoid as a tuple
"""
function ellipsoid(crs::ProjCRS)
    a, e2 = pj_get_spheroid_defn(crs.ptr)
    f = 1 - sqrt(1 - e2)
    b = a * (1 - f)
    Ellipsoid(a, b, f, e2, :UNKNOWN)
end

