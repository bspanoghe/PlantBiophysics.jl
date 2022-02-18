# First simulation

```@setup usepkg
using PlantBiophysics
using Dates
```

Mare your first simulation for a leaf energy balance, photosynthesis and stomatal conductance altogether with few lines of codes:

```@example usepkg
using PlantBiophysics, Dates

meteo = read_weather(
    joinpath(dirname(dirname(pathof(PlantBiophysics))),"test","inputs","meteo.csv"),
    :temperature => :T,
    :relativeHumidity => (x -> x ./100) => :Rh,
    :wind => :Wind,
    :atmosphereCO2_ppm => :Cₐ,
    :Re_SW_f => :Ri_SW_f,
    date_format = DateFormat("yyyy/mm/dd")
)

leaf = LeafModels(
        energy = Monteith(),
        photosynthesis = Fvcb(),
        stomatal_conductance = Medlyn(0.03, 12.0),
        Rₛ = meteo[:Ri_SW_f] .* 0.8,
        skyFraction = 1.0,
        PPFD = meteo[:Ri_SW_f] .* 0.8 .* 0.48 .* 4.57,
        d = 0.03
)

energy_balance!(leaf,meteo)

DataFrame(leaf)
```

Curious to understand more ? Head to the next section to learn more about parameter fitting, or to the [First simulation](@ref) section for more details about how to make simulations.