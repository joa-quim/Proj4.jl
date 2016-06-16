immutable SRID
    auth::Symbol
    id::Int
end

SRID() = SRID(:UNDEF, -1)

immutable ProjPJ
    ptr::Ptr{Void}
end


type ProjCRS
    rep::ProjPJ
    srid::SRID # Optional
end

immutable ProjPoint{N,T}
    point::Vec{N,T}
    crs::ProjCRS
end

immutable Proj4Transformation <: AbstractTransformation{ProjPoint, ProjPoint}
    from_crs_cache::Dict{SRID,ProjCRS}
    to_crs::ProjCRS
end

function transform(trans::Proj4Transformation, p::SRIDPoint)
    if !haskey(trans.from_crs_cache, p.srid)
        trans.from_crs_cache[p.srid] = ProjCRS(p.srid)
    end
    outpoint = pj_transform(trans.from_crs_cache[p.srid], trans.to_crs, p.point)
    PointPoint(outpoint, trans.to_crs)
end

################################################################################
################################################################################
################################################################################

########################
# CRS, SRID and cache: #
########################

immutable SRID
    auth::Symbol
    id::Int
end

SRID() = SRID(:UNDEF, -1)

srid_dict = Dict{Symbol, Dict{Int, ASCIIString}}()
srid_dict[:epsrg] = epsrg

immutable ProjPJ
    ptr::Ptr{Void}
end

type ProjCRS
    rep::ProjPJ
    srid::SRID # Optional
end

ProjCRS(rep::ProjPJ) = ProjCRS(rep, SRID())

projpj_cache = Dict{SRID, ProjPJ}()

function ProjCRS(srid::SRID)
    if haskey(projpj_cache, srid)
        return ProjCRS(projpj_cache[srid], srid)
    else
        # make `projpj` from `srid`
        if !haskey(srid_dict, srid.auth) || !haskey(srid_dict[srid.auth], srid.id)
            error("SRID $srid not found in projection string cache")
        end
        projstring = srid_dict[srid.auth][srid.id]

        # e.g. use
        # ...

        projpj_cache[srid] = projpj
        return ProjCRS(projpj, srid)
    end
end

##############################
# Low-level transformations: #
##############################

immutable ProjTransformation <: AbstractTransformation{Vec, Vec}
    to_crs::ProjCRS
    from_crs::ProjCRS
end

Base.inv(trans::ProjTransformation) = ProjTransformation(trans.from_crs, trans.to_crs)

ProjTransformation(from_CRS, to_CRS) = ProjReverse(to_CRS) ∘ ProjForward(from_CRS)

#
# Mid-level constructor-based interface
#
ProjPoint(p::ProjPoint, crs::ProjCRS) = ...


###########################
# Interface with Geodesy: #
###########################


function make_lla_from_projcrs(crs::ProjCRS)
    ProjTransformation(latlon_from_proj(crs), crs)
end

immutable LLAfromProj4 <: AbstractTransformation{LLA, Vec}
    crs::ProjCRS # For Vec
    lla_crs::ProjCRS
end

immutable Proj4fromLLA <: AbstractTransformation{LLA, Vec}
    crs::ProjCRS # For Vec
    lla_crs::ProjCRS # For LLA
end

Base.inv(trans::LLAfromProj4) = Proj4fromCRS(trans.crs, trans.datum)
Base.inv(trans::Proj4fromCRS) = LLAfromProj4(trans.crs, trans.datum)

# ... and so on ...

LLA(Vec{3}, SRID)
ECEF(Vec{3}, SRID)
UTMZ(Vec{3}, SRID)
UTM(Vec{3}, SRID, isnorth, zone)




for x, srid in data
    lla = transform(LLAfromProj4(:epsg, srid), x)
end


################################################################################
################################################################################
################################################################################
