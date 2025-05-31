
library(biomod2)


setwd('C:/Users/panad/Documents/FCUP/MontObEO/app biomod Ensemble/BioMod2/monte_biomod')

library(terra)

# definir ROI
region <- terra::vect('C:/Users/panad/Documents/FCUP/GIS/Shps/Montesinho/Montesinho_WGS_84.shp')

library(sf)

# Carregar dados da espécie
allSpecies_data <- st_read('./species_montobeo_WGS84_4326.gpkg')

species_data <- allSpecies_data[which(allSpecies_data$Species == 'Cervus_elaphus'),]
# Accipiter_nisus # Cervus_elaphus - 94 # Sylvia_atricapilla # Pelophylax_perezi - 300


# Extrair coordenadas dos pontos de presença
coords <- st_coordinates(species_data)

# Criar um data frame com as coordenadas e a presença
species_df <- data.frame(
  x = coords[, 1],
  y = coords[, 2],
  presence = 1  # 1 para presença
)


plot(region); points(species_df)


######## load predictors ############
predictors <- rast('./WorldClim4Bands.tif')

plot(predictors)

###################

# Format Data with pseudo-absences
myBiomodData <- BIOMOD_FormatingData(
  resp.name = 'Cervus',
  resp.var = species_df$presence,
  resp.xy = coords,
  expl.var = predictors,
  PA.nb.rep = 1, # pseudoAbsences sets
  PA.nb.absences = 90,
  PA.strategy = 'random', # pseudoAbsences creation
  filter.raster = T # para remover duplicados
)
#plot(myBiomodData)

# model
myBiomodModelOut <- BIOMOD_Modeling(
                bm.format = myBiomodData,
                modeling.id = 'modID_monte_bigboss',
                models = c("MAXNET", "RF", "XGBOOST"),
                CV.strategy = 'random',
                CV.nb.rep = 1,
                CV.perc = 0.8,
                CV.do.full.models = FALSE,
                OPT.strategy = 'bigboss',
                metric.eval = c('ROC'),
                #var.import = 1,
                #seed.val = 42
)

#myBiomodModelOut

# Avaliar o desempenho dos modelos
evals <- get_evaluations(myBiomodModelOut)

opt <- get_options(myBiomodModelOut)
opt

# Project single models
myBiomodProj <- BIOMOD_Projection(
                    bm.mod = myBiomodModelOut,
                    proj.name = 'monte_bigboss',
                    new.env = predictors,
                    models.chosen = 'all',
                    #metric.binary = 'all',
                    #metric.filter = 'all',
                    build.clamping.mask = FALSE,
                    on_0_1000 = FALSE)


plot(myBiomodProj)


########### Model ensemble models #############

myBiomodEM <- BIOMOD_EnsembleModeling(
                      bm.mod = myBiomodModelOut,
                      models.chosen = 'all',
                      em.by = 'all',
                      em.algo = c('EMmean', 'EMcv', 'EMci', 'EMmedian', 'EMca', 'EMwmean'),
                      metric.select = c('ROC'),
                      metric.select.thresh = c(0.7),
                      metric.eval = c('ROC'),
                      var.import = 3,
                      EMci.alpha = 0.05,
                      EMwmean.decay = 'proportional')
myBiomodEM



# Get evaluation scores & variables importance
eval_EM <- get_evaluations(myBiomodEM)
importance_EM <- get_variables_importance(myBiomodEM)

# Represent evaluation scores & variables importance
bm_PlotEvalMean(bm.out = myBiomodEM, group.by = 'full.name')
bm_PlotEvalBoxplot(bm.out = myBiomodEM, group.by = c('full.name', 'full.name'))
bm_PlotVarImpBoxplot(bm.out = myBiomodEM, group.by = c('expl.var', 'full.name', 'full.name'))
bm_PlotVarImpBoxplot(bm.out = myBiomodEM, group.by = c('expl.var', 'algo', 'merged.by.run'))
bm_PlotVarImpBoxplot(bm.out = myBiomodEM, group.by = c('algo', 'expl.var', 'merged.by.run'))


# Project ensemble models (from single projections)
myBiomodEMProj <- BIOMOD_EnsembleForecasting(
                      bm.em = myBiomodEM, 
                      bm.proj = myBiomodProj,
                      models.chosen = 'all',
                      metric.binary = 'all',
                      metric.filter = 'all')

# Project ensemble models (building single projections)
myBiomodEMProj <- BIOMOD_EnsembleForecasting(
                      bm.em = myBiomodEM,
                      proj.name = 'CurrentEM',
                      new.env = predictors,
                      models.chosen = 'all',
                      metric.binary = 'all',
                      metric.filter = 'all')
myBiomodEMProj
plot(myBiomodEMProj)


