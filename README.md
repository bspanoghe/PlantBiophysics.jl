# PlantBiophysics

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://VEZY.github.io/PlantBiophysics.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://VEZY.github.io/PlantBiophysics.jl/dev)
[![Build Status](https://github.com/VEZY/PlantBiophysics.jl/workflows/CI/badge.svg)](https://github.com/VEZY/PlantBiophysics.jl/actions)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)

A pure Julia package to simulate biophysical processes for plants such as photosynthesis, conductances for heat, water vapor and CO₂, latent, sensible energy fluxes, net radiation and temperature.

The benefits of using this package are:

- Blazing fast (μs for the whole energy balance + photosynthesis + conductances)
- Easy to use
- Great composability. Makes it easy to extend (add your model for any process, and it just works with the others)
- Easy to read, the code implement the equations as they are written in the scientific articles (thanks Julia Unicode!)
- Included in the Archimed platform. Will be used by other packages to simulate single leaves, voxels, canopies...
- Error propagation

## Examples

Here is an example usage with a simulation of the energy balance and assimilation of a leaf:

```julia
# ]add PlantBiophysics https://github.com/VEZY/PlantBiophysics.jl
using PlantBiophysics

# Declaring the meteorology for the simulated time-step:
meteo = Atmosphere(T = 22.0, Wind = 0.8333, P = 101.325, Rh = 0.4490995)

# Using the model from Medlyn et al. (2011) for Gs and the model of Monteith and Unsworth (2013) for the energy balance:
leaf = ModelList(
    energy_balance = Monteith(),
    photosynthesis = Fvcb(),
    stomatal_conductance = Medlyn(0.03, 12.0),
    status = (Rₛ = 13.747, sky_fraction = 1.0, PPFD = 1500.0, d = 0.03)
)

energy_balance!(leaf, meteo)

leaf[:A]
```

For more examples, please read the documentation.

## Roadmap

- [x] Add FvCB model
- [x] Add FvCB iterative model
- [x] Add stomatal + boundary layer conductance models
- [x] Add energy balance model, coupled with photosynthesis amd stomatal conductance models
- [x] Make the functions work on the output from `read_model`.
- [x] Rename skyFraction into sky_fraction
- [ ] Add a new conductance model using the version from Duursma, Remko A, Christopher J Blackman, Rosana Lop, et K Martin-StPaul. 2018. « On the Minimum Leaf Conductance: Its Role in Models of Plant Water Use, and Ecological and Environmental Controls ». New Phytologist, 13.
- [x] Make the functions compatible with an MTG, e.g. apply photosynthesis to an MTG, and use the right method for each node. NB: I think the models should be a field of the node.
- [ ] Make the functions compatible with several meteorological time-steps
  - [x] Add a new struct for that: Weather
  - [x] Do it for energy_balance
  - [x] photosynthesis
  - [x] stomatal conductance
  - [x] Add tests for each
  - [x] Update the doc!
  - [x] Check if it works with MTGs
- [ ] Evaluate using Schymanski et al. (2017) data + leaf measurements models (in progress)
- [ ] Check Schymanski input: is Rs = Rnleaf ok? Because Rs is Rn - Rll.
- [ ] Add more documentation + tutorial:
  - [x] add doc about the design (components, models, model values, multiple dispatch)
  - [x] add doc about input files
  - [x] add doc for each process
  - [x] add a list of models for each process
  - [x] add documentation for each model
  - [x] add a tutorial for a single leaf at one time-step
  - [x] add a tutorial for a single leaf at several time-step
  - [x] add a tutorial for a plant
  - [x] How to implement a new model -> e.g. conductance (add a `variables` method)
  - [x] How to implement a new component:
- [ ] Use [PrettyTables.jl](https://ronisbr.github.io/PrettyTables.jl/stable/#PrettyTables.jl) for printing the Weather and simulation outputs
- [ ] Try to make `get_component_type()` more generic? Or easily extendable?
- [x] Use leaf[:var] in the models implementations instead of leaf.status.var. It will make the code way clearer.
- [ ] Do we have a `setindex!` method for `leaf[:var]`? Implement it if missing.
- [ ] Make boundary layer conductances true models as for stomatal conductances, but maybe define the current ones as default when calling the function (I mean if no model is provided, use the ones currently in use).
- [ ] Make a diagram of a leaf for gaz and energy exchanges
- [ ] Add checks on the models provided for a simulation: for example Fvcb requires a stomatal conductance model. At the moment Julia returns an error on missing method for the particular implementation of photosynthesis!_(Fvcb,Gs) (in short). We could check before that both are needed and present, and return a more informational error if missing.
- [ ] Implement a Gm model. Cf. the [GECROS](https://models.pps.wur.nl/gecros-detailed-eco-physiological-crop-growth-simulation-model-analyse-genotype-environment) model.
- [x] Replace component models by MutableNamedTuples ? It could alleviate the need to implement a different component model when needing a new model as it allows as many fields as we want. A call to a function would need to include the type of the model though ? *e.g.* `energy_balance!(mtnt.energy_balance, mtnt, meteo, constant)`, or we do that in the low-level functions so the use only pass the mtnt. -> solution was to make the call to the low-level functions generic for the models (no constraint on the type), but dispatch on the type of the first argument instead that is the model type for this function. This changes nothing to the high-level functions but make the possibility to provide other things than component models.
- [x] Move the definitions of the abstract models near their processes: e.g. the definition of `AbstractAModel` should be in the `photosynthesis.jl` file.
- [ ] Change the way we store parameters, models and status:
  - [ ] Add a new struct for the list of models, with two fields: models and status.
  - [ ] Models can be a struct, Namedtuple or whatever struct that can be called with `models.process`.
  - [ ] The status field must be part of the struct in input of the high-level functions for easy construction, but be passed as an argument to the low-level functions so we avoid the copy(object, object[i]) in the high-level calls.
  - [ ] Make a custom type for status so they are indexable? Maybe use [StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl) instead ? Not sure, `status[i].A = 12` does not modify the array, only `status.A[i] = 12` does, and we will provide status[i] as input to the low-level function so... Or else we get the output of the low level function, and re-assign it to the status: `status[i] = output_status`, but this is not the best solution. Use a dataframe with a view instead for several time steps ? Make a microbenchmark, dataframes should be fast.
  - [ ] Make sure all functions currently applied to the status are still needed, and if so check if they work.
  - [ ] Add a check on the combination of models + status to see if the initialisation is complete, but make it optional (arg `check=true` by default).
  - [ ] Make a new `submodels` function for each model that list all models that are used by a model. It can be nothing, an abstract model (e.g. `AbstractAModel`), a concrete model (e.g. `Fvcb`) or any combinations of models (e.g. photosynthesis + stomatal conductance).
  - [ ] Make a function to build a tree of models based on the `submodels` outputs.
- [ ] Remove checks on the models when calling the processes functions, and move it to the construction of the group of models and/or to the user with a check function.
- [ ] For the computation of MTG + Weather, give an option on which way the computation is done: compute one time-step for each node, and then the second..., or compute all time-steps for each node at once. The latter avoids visiting the tree n times, so it should be the default. But sometimes models need the result of other nodes before continuing, so the former is necessary. Add the option with a type so we use dispatch, e.g.: `TimeStepFirst` and `NodeFirst`.

## Contributing

Contributions are welcome! If you develop a model for a process, please make a pull request so the community can enjoy it!

See contributor's guide badge for more informations: [![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac).

## Similar projects

- [MAESPA](http://maespa.github.io/)
- [photosynthesis](https://github.com/cran/photosynthesis) R package
- [plantecophys](https://bitbucket.org/remkoduursma/plantecophys/src/master/) R package
Leuning et al. (1995)
- [LeafGasExchange](https://github.com/TESTgroup-BNL/LeafGasExchange) R package

## References

Baldocchi, Dennis. 1994. « An analytical solution for coupled leaf photosynthesis and
stomatal conductance models ». Tree Physiology 14 (7-8‑9): 1069‑79.
<https://doi.org/10.1093/treephys/14.7-8-9.1069>.

Duursma, R. A., et B. E. Medlyn. 2012. « MAESPA: a model to study interactions between water
limitation, environmental drivers and vegetation function at tree and stand levels, with an
example application to [CO2] × drought interactions ». Geoscientific Model Development 5
(4): 919‑40. <https://doi.org/10.5194/gmd-5-919-2012>.

Farquhar, G. D., S. von von Caemmerer, et J. A. Berry. 1980. « A biochemical model of
photosynthetic CO2 assimilation in leaves of C3 species ». Planta 149 (1): 78‑90.

Leuning, R., F. M. Kelliher, DGG de Pury, et E.-D. SCHULZE. 1995. « LeafModels nitrogen,
photosynthesis, conductance and transpiration: scaling from leaves to canopies ». Plant,
Cell & Environment 18 (10): 1183‑1200.

Medlyn, B. E., E. Dreyer, D. Ellsworth, M. Forstreuter, P. C. Harley, M. U. F. Kirschbaum, X. Le Roux, et al. 2002. « Temperature response of parameters of a biochemically based model of photosynthesis. II. A review of experimental data ». Plant, Cell & Environment 25 (9): 1167‑79. <https://doi.org/10.1046/j.1365-3040.2002.00891.x>.

Monteith, John L., et Mike H. Unsworth. 2013. « Chapter 13 - Steady-State Heat Balance: (i) Water Surfaces, Soil, and Vegetation ». In Principles of Environmental Physics (Fourth Edition), edited by John L. Monteith et Mike H. Unsworth, 217‑47. Boston: Academic Press.

Schymanski, Stanislaus J., et Dani Or. 2017. « LeafModels-Scale Experiments Reveal an Important
Omission in the Penman–Monteith Equation ». Hydrology and Earth System Sciences 21 (2): 685‑706. <https://doi.org/10.5194/hess-21-685-2017>.

Vezy, Rémi, Mathias Christina, Olivier Roupsard, Yann Nouvellon, Remko Duursma, Belinda Medlyn, Maxime Soma, et al. 2018. « Measuring and modelling energy partitioning in canopies of varying complexity using MAESPA model ». Agricultural and Forest Meteorology 253‑254 (printemps): 203‑17. <https://doi.org/10.1016/j.agrformet.2018.02.005>.
