# election-maps

Examples live: [PredictIt Senate Map 2018](http://aca.cm/pi18), [Alabama Special Election Map](http://aca.cm/al18)

I worked on most of this code ahead of the 2016 election. I found it difficult to generate "clickable" maps using some of the available R libraries - especially for custom shapefiles. Using R and Leaflet, I was able to hack together a solution. It's kind of overkill for a state-level map, but would be really helpful for visualizing county-level results.

Generally, the R script takes a shapefile (usually from GADM) and some form of data (election results, polls, PredictIt, etc) to generate a geoJSON file. The geoJSON file is loaded and rendered using Leaflet, which adds features like mouseover, colors, links, etc. I will probably move generation of colors over to R - I have been using color ramps in some of my PNG maps and it would be nice to keep visual consistency.

With some difficulty I was even able to get this working inside of an individual Wordpress page using the "Scripts n Styles" plugin!
