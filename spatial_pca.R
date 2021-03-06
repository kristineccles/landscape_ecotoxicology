#############################################################################
# PCA and BCA for complex exposures
# Written in R Version 3.5.2
#############################################################################

# Load Libraries
library(factoextra)
library(ggplot2)
library(ade4)
library (adegraphics)
library(lattice)
library(sp)
library(adegenet)
library(spdep)
library(adespatial)
library(maptools)

# Combining plots for publication quality
library(ggpubr)
library(sjPlot)

###############################################################################
# Read Data
data = read.csv("amphib_metals3.csv")

# Remove missing D\data
comp_data=na.omit(data)

#################################################################################
### PCA ####
pca1= dudi.pca(df = comp_data[7:25], scannf = TRUE, nf = 5, center=TRUE)

#Plot PCA
g1=s.corcircle(pca1$co, plot=FALSE)
g2=s.label(pca1$li, plot=FALSE)
ADEgS(list(g1,g2))

#Scree Plot
scree=fviz_eig(pca1, 
               ncp=10, 
               ggtheme = theme_minimal(base_size = 18), 
               addlabels=TRUE,
               main = NULL)

#### BCA ####
# Set up lat as a factor
lat=as.factor(comp_data$Lat)

#BCA by site
bca_site=bca(pca1,lat,scannf=TRUE)

# Plot BCA-Biplot
s.arrow(bca_site$co)

#Get loadings and write to csv
bca_loadings=bca_site$co
write.csv(bca_loadings, "bca_loadings.csv")

# Montecarlo to test between species differences
rt_between_site=randtest(bca_site)
rt_between_site
# 45% of the variance is explained by site differences (p=0.001)

########################################################
#### Spatial analysis ####
# Spatial Representation of BCA 
# Create comp_dataset with bca scores and coordinates

# Aggregate the x y coordinates for site
xy=coordinates(comp_data[,3:4])
sitexy=aggregate(comp_data[,3:4], list(comp_data$Lat), mean)

# Extract information by site from BCA
dim(bca_site$tab)
scores_by_site=bca_site$li

# Attach Coordinates to sites
scores_xy=cbind(sitexy, scores_by_site)
write.csv(scores_xy, "site_scores_xy.csv")

# Prepare spatial data for mapping
colour=cbind(col="gray90", border="gray90")
rivers = readShapePoly("rivers_clip.shp", IDvar=NULL, proj4string=CRS(as.character(NA)), 
                       verbose=FALSE, repair=FALSE, force_ring=FALSE)

# Map the scores of the BCA
g1.map.bca=s.value(scores_xy[,2:3],bca_site$li, symbol="circle", 
                   pSp.col=as.factor(scores_xy$Group.1), 
                   Sp=rivers, ppoints.cex=0.75,ylim=c(55,62), xlim=c(-115,-110))

#### Create BCA with spatial information integrated- Multispati ##### Defining spatial weights
# To explore other spatial weights matrices
# listw.explore()

# Gabriel Neighbourhood- best for uneven sampling schemes
nb <- chooseCN(scores_xy[,2:3], type = 2, plot.nb = FALSE) 
lw <- nb2listw(nb, style = 'W', zero.policy = TRUE)

# Test spatial autcorrelation of BCA scores
# Moran's I
moran.randtest(scores_xy[,"Axis1"], listw=lw,nrepet=999)
moran.plot(scores_xy[,"Axis1"], listw=lw)
# Borderline positive spatial autocorrelation

moran.randtest(scores_xy[,"Axis2"], listw=lw,nrepet=999)
moran.plot(scores_xy[,"Axis2"], listw=lw)
#no spatial autocorrelation

# Write scores to csv
write.csv(cbind(xy,bca_site$li), "bca_scores.csv")

#Moran's eigenvector maps using gabriel neighbourhood
me=mem(lw)
map = s.value(scores_xy[,2:3], me[,c(1:2)], Sp=rivers, ppoints.cex=0.75,ylim=c(55,62), xlim=c(-115,-110))
scalo1=scalogram(scores_xy[,"Axis1"], me, nblocks=10)
plot(scalo1)
scalo2=scalogram(scores_xy[,"Axis2"], me, nblocks=10)
plot(scalo2)
s.arrow(me)

# Multispatial analysis
ms1=multispati(bca_site,lw,scannf=FALSE, nfposi=4,nfnega=0)
summary(ms1)
plot
s.arrow(ms1$c1)
# Output loadings 
write.csv(ms1$c1, "multispati_loadings.csv")

###############################################################
# Publication Plots
# Figure 5 
scree=fviz_eig(pca1, 
               ncp=10, 
               ggtheme = theme_minimal(base_size = 18), 
               addlabels=TRUE,
               main = NULL)

save_plot("scree.tif", scree, width = 20, height = 20, dpi = 300,
          legend.textsize = 20, legend.titlesize = 20,
          legend.itemsize = 20)
