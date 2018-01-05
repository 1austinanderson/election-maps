
library("jsonlite")
library("RCurl")
library("geojsonio")
library("RMySQL")
library("rgeos")
library("sp")

### A pre-processed, simplified version of the GADM dataset for state boundaries
### SpatialPolygons object - 49 states + DC
load("can.Rdata")


### Got these manually from predictit.org - will need to be revisited once they open more markets
reelecMarkets<-c("TEST.MT", "WARREN.MA", "CRUZ.TX", "SANDERS.VT", "HEIT.ND", "MCCA.MO", "STAB.MI", "MANCHIN.WV", "NELSON.FL", "BROW.OH", "DONNELLY.IN", "MENE.NJ", "BALD.WI", "FEIN.AZ", "HELL.NV", "KING.ME", "HEIN.NM")
partyMarkets<-c("TNSEN18","AZSEN18","PARTY.MNSEN.18")



reelecUrls<-paste("https://www.predictit.org/api/marketdata/ticker/",reelecMarkets,"SENATE.2018",sep="")

result<-matrix(, nrow =51 , ncol = 2)
mapUrls<-matrix(, nrow =51 , ncol = 1)

### Don't really need DC for Senate races obviously but stays consistent with some of my other code
row.names(result)<-append(append(state.abb[1:8],"DC"),state.abb[9:50])

### Map which incumbents are in which state and their parties
reelecIndices<-c(27,22,44,46,35,26,23,49,10,36,15,31,50,5,29,20,32)
incumbentIndices<-c(1,1,-1,1,1,1,1,1,1,1,1,1,1,1,-1,1,1)

### We could do this in parallel with mcmapply or similar but runtime is acceptable right now (~10 sec)
for(i in c(1:length(reelecMarkets))){
    jsonInput<-fromJSON(readLines(reelecUrls[i]))
    prices<-jsonInput$Contracts
    mapUrls[reelecIndices[i]]<-jsonInput$URL
    buyYes<-prices$BestBuyYesCost
    sellYes<-prices$BestSellYesCost

     ### Buy Yes and Sell Yes have all the information in the Yes/No markets
    demPrice<-1*(incumbentIndices[i]==-1)+incumbentIndices[i]*(buyYes+sellYes)/2
     ### Might be better to take last sale price into account too if we were trading
     ### This is fine for general visualization though
    
    result[reelecIndices[i],1]<-demPrice
    result[reelecIndices[i],2]<-(1-demPrice)
}

partyUrls<-paste("https://www.predictit.org/api/marketdata/ticker/",partyMarkets ,sep="")

### Could be cleaner, but this works
partyIndices<-c(43,3,24)

for(i in c(1:length(partyMarkets))){
    jsonInput<-fromJSON(readLines(partyUrls[i]))
    prices<-jsonInput$Contracts
    mapUrls[partyIndices[i]]<-jsonInput$URL
    buyDemYes<-prices[prices$TickerSymbol==paste("DEM.",partyMarkets[i],sep=""),]$BestBuyYesCost
    sellDemYes<-prices[prices$TickerSymbol==paste("DEM.",partyMarkets[i],sep=""),]$BestSellYesCost
    buyRepYes<-prices[prices$TickerSymbol==paste("GOP.",partyMarkets[i],sep=""),]$BestBuyYesCost
    sellRepYes<-prices[prices$TickerSymbol==paste("GOP.",partyMarkets[i],sep=""),]$BestSellYesCost
    
     ### A little more complicated in the "linked" markets w/ separate GOP and DEM Yes/No
    demPrice<-(buyDemYes+sellDemYes+2-buyRepYes-sellRepYes)/4
     ### If there are any significant third parties this will break
    
    result[partyIndices[i],1]<-demPrice
    result[partyIndices[i],2]<-(1-demPrice)
}


### Take out Hawaii and Alaska from the map
### (I could work on resizing translating them into view for a future map)
results<-result[-12,][-2,]
mapUrls<-mapUrls[-12][-2]

### Set up the map and encode features into geojson file

### Centroids are for location of state abbreviation text
trueCentroids<-gCentroid(can,byid=TRUE)

### That SpatialPolygons object we loaded earlier
canjs<-geojson_list(can)

for(i in 1:length(canjs$features)){
    if(is.na(results[i,1])==FALSE){
        ### This is what we do if we have data for the state
        canjs$features[[i]]$properties$urlto<-mapUrls[i]
        canjs$features[[i]]$properties$probs<-results[i,1]
        margin<-max(results[i,1],results[i,2])
        
        ###Set up "margin" mouseover text
        if(results[i,1]>results[i,2]){
            canjs$features[[i]]$properties$poptxt<-paste(row.names(results)[i],": Democrat ",100*round(margin,2),"%",sep="")
        }else{
            canjs$features[[i]]$properties$poptxt<-paste(row.names(results)[i],": Republican ",100*round(margin,2),"%",sep="")}

    }else{
        canjs$features[[i]]$properties$probs<- -1
        canjs$features[[i]]$properties$poptxt<-paste(row.names(results)[i],": No Market",sep="")
    }
    canjs$features[[i]]$properties$centx<-trueCentroids[i]$x
    canjs$features[[i]]$properties$centy<-trueCentroids[i]$y
    canjs$features[[i]]$properties$stname<-row.names(results)[i]
}


geojson_write(canjs,file="/var/www/html/predictit/predictit.geojson")

### Adding "var statesData = " to the beginning of the file
### That way I can just "include" pit.geojson later

fileName <- '/var/www/html/predictit/predictit.geojson'
block<-paste("var statesData = ",readChar(fileName, file.info(fileName)$size),sep="")
write(block, file = fileName)
