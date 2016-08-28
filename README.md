# Proj4

## Quickstart

A simple wrapper around the proj.4 cartographic projections library.

Basic example (FIXME!):

```julia
using Proj4

wgs84 = Projection("+proj=longlat +datum=WGS84 +no_defs")
utm56 = Projection("+proj=utm +zone=56 +south +datum=WGS84 +units=m +no_defs")

transform(wgs84, utm56, [150 -27 0])
# Should result in [202273.913 7010024.033 0.0]
```

API documentation for the underlying C API may be found here:
https://github.com/OSGeo/proj.4/wiki/ProjAPI


## Relationship to the proj.4 C library

In this document `proj.4` will refer to the C library; `Proj4.jl` is the julia
wrapper.  This section discusses some conceptual difficulties with the C
library, and how we've tried to mitigate them in the wrapper.

In `proj.4` there's two rather different ways to view the central type `ProjPJ`:
One is as a *map projection*: a two dimensional mathematical transformation of
coordinates between lat-lon and a projected coordinate system.  This seems to be
the origins of the library, but the modern `ProjPJ` has grown into much more than
this.  The second is as a Coordinate Reference System (CRS): a specification of
the coordinate system and measurement datum - this is closer to how `proj.4`
works as of 2016.  See the documentation of
[Geodesy.jl](https://github.com/JuliaGeo/Geodesy.jl) for more information about
CRS.

These two related but distinct purposes for `ProjPJ` create conceptual tension
in the `proj.4` API.  We have:

* `pj_fwd` and `pj_inv` for 2D map projections (the traditional API).  These
   require a single `ProjPJ` pointer defining the coordinate system relative to
   a base lat-lon system.
* `pj_transform` for transformations between two 2D or 3D CRSs.  These require
   two `ProjPJ` structures, each of which defines a coordinate system and datum.
   The rules which `ProjPJ` uses to transform between datums seem to be somewhat
   subtle and poorly documented.

In `Proj4.jl`, we have chosen to expose the second concept as the main
abstraction, and have named the type `ProjCRS` accordingly.
