#-------------------------------------------------------------------------------
# Library setup and error handling

"Get a string describing the underlying version of libproj in use"
function pj_get_release()
    bytestring(ccall((:pj_get_release, libproj), Cstring, ()))
end

"Get human readable error string from a proj.4 error code"
function pj_strerrno(code::Integer)
    bytestring(ccall((:pj_strerrno, libproj), Cstring, (Cint,), code))
end

"Get global errno string in human readable form"
function pj_strerrno()
    pj_strerrno(pj_errno())
end

"Get proj.4 error code"
function pj_errno()
    unsafe_load(ccall((:pj_get_errno_ref, libproj), Ptr{Cint}, ()))
end


#-------------------------------------------------------------------------------
# ProjPJ initialization and destruction

"""
Initialize C level ProjPJ pointer from a proj.4 formatted projection string.
"""
function pj_init_plus(proj_string)
    proj_ptr = ccall((:pj_init_plus, libproj), Ptr{Void}, (Cstring,), proj_string)
    if proj_ptr == C_NULL
        # TODO: use context?
        error("Could not parse projection: \"$proj_string\": $(pj_strerrno())")
    end
    proj_ptr
end

"Free C datastructure associated with a projection. For internal use!"
function pj_free(proj_ptr)
    @assert proj_ptr != C_NULL
    ccall((:pj_free, libproj), Void, (Ptr{Void},), proj_ptr)
end

"""
Return the lat/lon coordinate system on which a crs is based.  If the
coordinate system passed in is latlong, a clone of the same will be returned.
"""
function pj_latlong_from_proj(proj_ptr)
    ccall((:pj_latlong_from_proj, libproj), Ptr{Void}, (Ptr{Void},), proj_ptr)
end

"Get projection definition string in the proj.4 plus format"
function pj_get_def(proj_ptr)
    @assert proj_ptr != C_NULL
    opts = 0 # Apparently obsolete argument, not used in current proj source
    bytestring(ccall((:pj_get_def, libproj), Cstring, (Ptr{Void}, Cint), proj_ptr, opts))
end


#-------------------------------------------------------------------------------
# Information about coordinate systems

function pj_is_latlong(proj_ptr)
    @assert proj_ptr != C_NULL
    ccall((:pj_is_latlong, libproj), Cint, (Ptr{Void},), proj_ptr) != 0
end

function pj_is_geocent(proj_ptr)
    @assert proj_ptr != C_NULL
    ccall((:pj_is_geocent, libproj), Cint, (Ptr{Void},), proj_ptr) != 0
end

"""
Fetch the internal definition of the spheroid as a tuple
`(major_axis, eccentricity_squared)`.
"""
function pj_get_spheroid_defn(proj_ptr)
    major_axis = Ref{Cdouble}()
    eccentricity_squared = Ref{Cdouble}()
    ccall((:pj_get_spheroid_defn, libproj), Void, (Ptr{Void}, Ptr{Cdouble}, Ptr{Cdouble}),
          proj_ptr, major_axis, eccentricity_squared)
    major_axis[], eccentricity_squared[]
end

"Return true if the two datums are identical, otherwise false."
function pj_compare_datums(p1_ptr, p2_ptr)
    Bool(ccall((:pj_compare_datums, libproj), Cint, (Ptr{Void}, Ptr{Void}), p1_ptr, p2_ptr))
end


#-------------------------------------------------------------------------------
# Transformations between coordinate systems

"""
Low level interface to pj_transform, which transforms between two coordinate
systems. C_NULL can be passed in for z to ignore the height component.
"""
function pj_transform!(src_ptr, dest_ptr, point_count, point_stride,
                       x::Ptr{Cdouble}, y::Ptr{Cdouble}, z::Ptr{Cdouble})
    @assert src_ptr != C_NULL && dest_ptr != C_NULL
    err = ccall((:pj_transform, libproj), Cint, (Ptr{Void}, Ptr{Void}, Clong, Cint, Ptr{Cdouble}, Ptr{Cdouble},
                Ptr{Cdouble}), src_ptr, dest_ptr, point_count, point_stride, x, y, z)
    err != 0 && error("transform error: $(pj_strerrno(err))")
end

function pj_transform!(src_ptr, dest_ptr, position::Vector{Cdouble})
    @assert src_ptr != C_NULL && dest_ptr != C_NULL
    ndim = length(position)
    @assert ndim >= 2

    x = pointer(position)
    y = x + sizeof(Cdouble)
    z = (ndim == 2) ? Ptr{Cdouble}(C_NULL) : x + 2*sizeof(Cdouble)

    pj_transform!(src_ptr, dest_ptr, 1, 1, x, y, z)
    position
end

function pj_transform!(src_ptr, dest_ptr, position::Array{Cdouble,2})
    @assert src_ptr != C_NULL && dest_ptr != C_NULL
    npoints, ndim = size(position)
    @assert ndim >= 2

    x = pointer(position)
    y = x + sizeof(Cdouble)*npoints
    z = (ndim == 2) ? Ptr{Cdouble}(C_NULL) : x + 2*sizeof(Cdouble)*npoints

    pj_transform!(src_ptr, dest_ptr, npoints, 1, x, y, z)
    position
end


#-------------------------------------------------------------------------------
# Semi-obsolete(?) 2D pointwise transformation interface
#
# See the README for more discussion

immutable ProjUV
    u::Cdouble
    v::Cdouble
end

"forward projection from Lat/Lon to X/Y (only supports 2 dimensions)"
function pj_fwd!(lonlat::Vector{Cdouble}, proj_ptr)
    xy = ccall((:pj_fwd, libproj), ProjUV, (ProjUV, Ptr{Void}), ProjUV(lonlat[1], lonlat[2]), proj_ptr)
    pj_errno() == 0 || error("forward projection error: $(pj_strerrno())")
    lonlat[1] = xy.u; lonlat[2] = xy.v
    lonlat
end

"Row-wise projection from Lat/Lon to X/Y (only supports 2 dimensions)"
function pj_fwd!(lonlat::Array{Cdouble,2}, proj_ptr)
    for i=1:size(lonlat,1)
        xy = ccall((:pj_fwd, libproj), ProjUV, (ProjUV, Ptr{Void}),
                   ProjUV(lonlat[i,1], lonlat[i,2]), proj_ptr)
        lonlat[i,1] = xy.u; lonlat[i,2] = xy.v
    end
    pj_errno() == 0 || error("forward projection error: $(pj_strerrno())")
    lonlat
end

"inverse projection from X/Y to Lat/Lon (only supports 2 dimensions)"
function pj_inv!(xy::Vector{Cdouble}, proj_ptr)
    lonlat = ccall((:pj_inv, libproj), ProjUV, (ProjUV, Ptr{Void}),
                   ProjUV(xy[1], xy[2]), proj_ptr)
    pj_errno() == 0 || error("inverse projection error: $(pj_strerrno())")
    xy[1] = lonlat.u; xy[2] = lonlat.v
    xy
end

"Row-wise projection from X/Y to Lat/Lon (only supports 2 dimensions)"
function pj_inv!(xy::Array{Cdouble,2}, proj_ptr)
    for i=1:size(xy,1)
        lonlat = ccall((:pj_inv, libproj), ProjUV, (ProjUV, Ptr{Void}),
                       ProjUV(xy[i,1], xy[i,2]), proj_ptr)
        xy[i,1] = lonlat.u; xy[i,2] = lonlat.v
    end
    pj_errno() == 0 || error("inverse projection error: $(pj_strerrno())")
    xy
end


