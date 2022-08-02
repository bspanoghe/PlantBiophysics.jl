
"""
Constant (forced) assimilation, given in ``μmol\\ m^{-2}\\ s^{-1}``,
coupled with a stomatal conductance model that helps computing Cᵢ.

# Examples

```julia
ConstantAGs(30.0)
```
"""
Base.@kwdef struct ConstantAGs{T} <: AbstractAModel
    A::T = 25.0
end

function inputs_(::ConstantAGs)
    (Cₛ=-999.99,)
end

function outputs_(::ConstantAGs)
    (A=-999.99, Gₛ=-999.99, Cᵢ=-999.99)
end

Base.eltype(x::ConstantAGs) = typeof(x).parameters[1]

"""
    photosynthesis!_(::ConstantAGs, models, status, meteo, constants=Constants())

Constant photosynthesis coupled with a stomatal conductance model.

# Returns

Modify the leaf status in place for A, Gₛ and Cᵢ:

- A: carbon assimilation, set to leaf.photosynthesis.A (μmol[CO₂] m-2 s-1)
- Gₛ: stomatal conductance for CO₂ (mol[CO₂] m-2 s-1)
- Cᵢ: intercellular CO₂ concentration (ppm)

# Arguments

- `::ConstantAGs`: a constant assimilation model coupled to a stomatal conductance model
- `models`: a [`ModelList`](@ref) struct holding the parameters for the model with
initialisations for:
    - `Cₛ` (mol m-2 s-1): surface CO₂ concentration.
    - any other value needed by the stomatal conductance model.
- `status`: A status, usually the leaf status (*i.e.* leaf.status)
- `meteo`: meteorology structure, see [`Atmosphere`](@ref)
- `constants = Constants()`: physical constants. See [`Constants`](@ref) for more details

# Examples

```julia
meteo = Atmosphere(T = 20.0, Wind = 1.0, P = 101.3, Rh = 0.65)
leaf = ModelList(
    photosynthesis = ConstantAGs(),
    stomatal_conductance = Medlyn(0.03, 12.0),
    status = (Cₛ = 400.0, Dₗ = 2.0)
)

photosynthesis!(leaf,meteo,Constants())

status(leaf, :A)
status(leaf, :Cᵢ)
```
"""
function photosynthesis!_(::ConstantAGs, models, status, meteo, constants=Constants())

    # Net assimilation (μmol m-2 s-1)
    status.A = models.photosynthesis.A

    # Stomatal conductance (mol[CO₂] m-2 s-1)
    stomatal_conductance!_(models.stomatal_conductance, models, status, meteo)

    # Intercellular CO₂ concentration (Cᵢ, μmol mol)
    status.Cᵢ = min(status.Cₛ, status.Cₛ - status.A / status.Gₛ)

    return nothing
end
