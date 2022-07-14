# IXIS Technical Challenge
 Code and Documentation for IXIS Technical Challenge
 
## How to use repository?
* Install the following `R` packages:
  - `targets`
  - `tidymodels`
  - `vip`
  - `ggcorrplot`
  - `readr`
  - `skimr`
 
* Clone/download the repository

* Open `ixis.Rproj` in RStudio (though this isn't necessary)

* Open `_targets.R` to see my ML pipeline, Lines 25 - 65.
  - A diagram of this pipeline can be seen by `tar_visnetwork()`
    
* Run `tar_make()` to create all the output which will be saved in `_targets/objects`. These objects be read with `tar_read()` 

* The `function.R` has all the hard work and is well coded.
