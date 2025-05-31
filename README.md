# R script to run montobeo species in Biomod2


### Species presence coordinates

You can download the vector file with the <a href="https://drive.google.com/uc?export=download&id=1ohSr_InDlzXThOP3GuJrV5B14aYqv73I">species occurrences</a> modeled in MontObEO (3 MB).

After loading the file you can filter the species you want to model and prepare the required subset of data:

```r
library(sf)

# load species occurrences
allSpecies_data <- st_read('./species_montobeo_WGS84_4326.gpkg')

# filter Cervus_elaphus
species_data <- allSpecies_data[which(allSpecies_data$Species == 'Cervus_elaphus'),]

# Extract coordinates from presence points
coords <- st_coordinates(species_data)

# Create a data frame with coordinates and presence
species_df <- data.frame(
  x = coords[, 1],
  y = coords[, 2],
  presence = 1  # 1 para presença
)


plot(region); points(species_df)

```
examples of other species (occurrences)

Accipiter_nisus (17), Cervus_elaphus (94); Sylvia_atricapilla (161); Pelophylax_perezi (304)
