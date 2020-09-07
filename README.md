# Proj4.jl

[![Build status](https://travis-ci.org/JuliaGeo/Proj4.jl.svg?branch=master)](https://travis-ci.org/JuliaGeo/Proj4.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/tscgm13l1pvajqqa/branch/master?svg=true)](https://ci.appveyor.com/project/JuliaGeo/proj4-jl/branch/master)

A simple Julia wrapper around the [PROJ](https://proj.org/) cartographic projections library.

# WARNING

This version relies on having [GMT](https://github.com/GenericMappingTools/GMT.jl) installed and will use it to find the system libraries
needed for this package. This has the advantage of and saving you disk space. However, being a fork it may risk to go out of sync with time.

It would be nice if this solution could be integrated in the officially registered package as an install option but atm I don't know
how to implement that.

See also same solution for:

- [GDAL](https://github.com/joa-quim/GDAL.jl)
- [LibGEOS](https://github.com/joa-quim/LibGEOS.jl)
- [NetCDF](https://github.com/joa-quim/NetCDF.jl)

## Installation

```
pkg> add https://github.com/joa-quim/Proj4.jl
```
To test if it is installed correctly, use:
```
pkg> test Proj4
```

Basic example:

```julia
using Proj4

wgs84 = Projection("+proj=longlat +datum=WGS84 +no_defs")
utm56 = Projection("+proj=utm +zone=56 +south +datum=WGS84 +units=m +no_defs")

transform(wgs84, utm56, [150 -27 0])
# Should result in [202273.913 7010024.033 0.0]
```

API documentation for the underlying C API may be found here:
https://proj.org/development/reference/index.html
