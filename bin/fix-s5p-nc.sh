#!/bin/bash
ncatted -a bounds,longitude,o,c,longitude_bounds -a bounds,latitude,o,c,latitude_bounds $1
ncatted -a coordinates,sulfurdioxide_total_vertical_column,o,c,'longitude latitude' $1
ncatted -a coordinates,sulfurdioxide_total_vertical_column_precision,o,c,'longitude latitude' $1