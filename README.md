# election-maps

I worked on most of this code ahead of the 2016 election. I found it difficult to generate "clickable" maps using some of the available R libraries - especially for custom shapefiles. Using R and Leaflet, I was able to hack together a solution. It's kind of overkill for a state-level map, but would be really helpful for visualizing county-level results.

Generally, the R script takes a shapefile (usually from GADM) and some form of data (election results, polls, PredictIt, etc) to generate a geoJSON file. The geoJSON file is loaded using Leaflet.

With some difficulty I was able to get this working inside of an individual Wordpress page using the "Scripts n Styles" plugin.
