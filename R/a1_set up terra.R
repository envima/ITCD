# specify package settings
## set terra temp path
terra::terraOptions(tempdir = "/scratch")

## supress .aux files in terra::writeRaster
terra::setGDALconfig("GDAL_PAM_ENABLED", "FALSE")
