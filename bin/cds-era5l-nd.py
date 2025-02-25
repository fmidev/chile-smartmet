#!/usr/bin/env python3
import sys
import cdsapi

# daily ERA5-Land for Nordic domain

c = cdsapi.Client()
year= sys.argv[1]
month= sys.argv[2]
day= sys.argv[3]

dataset = "reanalysis-era5-land"
request = {
    "variable": [
        "2m_dewpoint_temperature",
        "2m_temperature",
        "skin_temperature",
        "soil_temperature_level_1",
        "soil_temperature_level_2",
        "soil_temperature_level_3",
        "soil_temperature_level_4",
        "lake_bottom_temperature",
        "lake_ice_depth",
        "lake_ice_temperature",
        "lake_mix_layer_depth",
        "lake_mix_layer_temperature",
        "lake_shape_factor",
        "lake_total_layer_temperature",
        "snow_albedo",
        "snow_cover",
        "snow_density",
        "snow_depth",
        "snow_depth_water_equivalent",
        "snowfall",
        "snowmelt",
        "temperature_of_snow_layer",
        "skin_reservoir_content",
        "volumetric_soil_water_layer_1",
        "volumetric_soil_water_layer_2",
        "volumetric_soil_water_layer_3",
        "volumetric_soil_water_layer_4",
        "forecast_albedo",
        "surface_latent_heat_flux",
        "surface_net_solar_radiation",
        "surface_net_thermal_radiation",
        "surface_sensible_heat_flux",
        "surface_solar_radiation_downwards",
        "surface_thermal_radiation_downwards",
        "evaporation_from_bare_soil",
        "evaporation_from_open_water_surfaces_excluding_oceans",
        "evaporation_from_the_top_of_canopy",
        "evaporation_from_vegetation_transpiration",
        "potential_evaporation",
        "runoff",
        "snow_evaporation",
        "sub_surface_runoff",
        "surface_runoff",
        "total_evaporation",
        "10m_u_component_of_wind",
        "10m_v_component_of_wind",
        "surface_pressure",
        "total_precipitation",
        "leaf_area_index_high_vegetation",
        "leaf_area_index_low_vegetation",
        "high_vegetation_cover",
        "glacier_mask",
        "lake_cover",
        "low_vegetation_cover",
        "lake_total_depth",
        "land_sea_mask",
        "soil_type",
        "type_of_high_vegetation",
        "type_of_low_vegetation"
    ],
    "year": year,
    "month": month,
    "day": [day],
    "time": [
        "00:00", "01:00", "02:00",
        "03:00", "04:00", "05:00",
        "06:00", "07:00", "08:00",
        "09:00", "10:00", "11:00",
        "12:00", "13:00", "14:00",
        "15:00", "16:00", "17:00",
        "18:00", "19:00", "20:00",
        "21:00", "22:00", "23:00"
    ],
    "data_format": "grib",#"netcdf", #
    "download_format": "unarchived",
    "area": [72, 3, 52, 33] # Nordic domain
}

client = cdsapi.Client()
output = f'/home/users/smartmet/data/ERA5L_{year}{month}{day}T000000_sfc-1h-nd.grib' #.grib'
client.retrieve(dataset, request).download(output)
