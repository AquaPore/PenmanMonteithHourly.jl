[![Build Status](https://github.com/AquaPore/PET.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/AquaPore/PET.jl/actions/workflows/CI.yml?query=branch%3Amaster)


# **POTENTIAL EVAPOTRANSPIRATION PENMAN MONTEITH FAO 56**
# *For variable timestep less or equal than an hour*


# PARTICULARITY OF THIS SOFTWARES

* Adjuste output to any time step;
* Correct for missing data by linear interpolation;
* Flags missing data were interpolation is not possible;
* Write output to time step of interest ΔT;
* Options in TOML;

## INPUT DATA

* Year
* Month
* Day
* Hour
* Minute
* Humidity[%]
* SolarRadiation[W/m²]
* AirTemperature[°C]
* WindSpeed[m/s]

## OUTPUT

Outputs in *.csv* for non iterpolated and interpolated output. The PETY output is always positive.

* Dates
* Potential evapotranspiration [mm]
* 🎏_DataMissing

# OPTIONS

see .toml file

```julia
[path]
Path_Input       = "DATA\\INPUT\\DataMinute\\Timoleague_Climate_Minute.csv"
Path_Output_Plot = "DATA\\OUTPUT\\Timoleague_Pet_10minutes.svg"
Path_Output_Csv  = "DATA\\OUTPUT\\Timoleague_Pet_10minutes.csv"
"Path_Output_ΔToutput_Csv"  = "DATA\\OUTPUT\\Timoleague_Pet_ΔToutput.csv" # COutput csv table with timestep ΔT_Output

[date]

Date_Start = [2020,10,1,0,0] # Starting date of simulation [Year, Month, Day, Hour, Minute]
Date_End = [2026,1,26,7,0]   # Ending date of simulation [Year, Month, Day, Hour, Minute]
[flag]
"🎏_PetObs"   = false # <true> or <false> if having observed PET
"🎏_RaParam" = true # <true> or <false> if <false> then computed with petFunc.aerodynamic.Rₐ_INV_AERODYNAMIC_RESISTANCE(...)
"🎏_RsParam" = false # <true> or <false> if <false> then computed with petFunc.aerodynamic.Rₛ_SURFACE_RESISTANCE(...)

# Outputs
	"🎏_Plot"     = true # <true> or <false> if plotting
	"🎏_Table"    = false # <true> or <false> if tables in csv
[output]
"ΔT_Output" = 86400 # 86400 [mm] time step of output starting at Date_Start

[missings]
"ΔTmax_Missing" = 14400 # [second] maximum time were there is consecutative data missing before flagged as missing
MissingValue = -9999 # Value of missing data in the input

[param]
Latitude              = 51.61666666666667 # [degree]
Longitude             = -7.116666666666667 # [degree]
Longitude_LocalTime   = 0.0 # Longitude of center of time zone East to west e.g. greenwich
Zaltitude             = 100.0 # [m] altitude;
"α"                   = 0.25 # 0.23 [-] albedo or canopy reflection coefficient
SoilHeatFlux_Sunlight = 0.2 # 0.1 [-] Adjustment of soil heat flux parameters
SoilHeatFlux_Night    = 0.5  # 0.6[-] Adjustment of soil heat flux parameters

# *** IF <🎏_Ra_Param> = true

  RaParam              = 300.0 # 208.0  aerodynamic resistance to turbulent
# ELSE

  Hcrop               = 0.1 # [m] height of the crop
  Z_Humidity          = 2.0 # [m] height from ground of measuring humidity;
  Z_Wind              = 2.0 # [m] height from ground of measuring wind;
# --------------------------------------------

# *** IF <🎏_RS_Param> = true

  "Rₛ"  = 90.0 # [s m-1] 40 - 70.0
# ELSE

  R_Stomatal          = 140.0 # <70-90> stomatal resistance of the well-illuminated leaf [s m⁻¹]
# --------------------------------------------

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

[cst]
"Cₚ"     = 1013.0 # [J kg-1 °C-1]
Gsc      = 82000.0 # [J m-2 second⁻¹] Solar constant
Karmen   = 0.41 # 0.41 [-]
T_Kelvin = 273.15 # Conversion from C to Kelvin
"σ"      = 0.00000005674768518518519 # [W m−2 K−4] Stefan-Boltzmann constant
"ϵ"      = 0.622 # [-] ratio molecular weight of water vapour/dry air
"ℜ"      = 287.0 # [J kg-1 K-1] specific gas constant
"ρwater" = 1000.0 # [kg m-3] density of water

```

# MODEL

The Penman-Monteith model is written as follow:

``` math
ETₒ=\frac{\varDelta (\varDelta _{Radₙ}-G)+\frac{\rho _{ₐᵢᵣ}\,\,C_ₚ(Eₛ-Eₐ)}{Rₐ}}{\varDelta +\gamma \,\,\left( 1+\frac{Rₛ}{Rₐ} \right) \,\,\lambda _ᵥ\,\,\rho _{water}}
```

# RUN MODEL

```julia

include("src/PenmanMonteithHourly.jl")
Path_Toml = raw"DATA\PARAMETER\PetOption.toml"
DayHour, DayHour_Reduced, Pet_Obs, Pet_Obs_Reduced, Pet_Sim, Pet_Sim_Reduced = pet.PenmanMonteithHourly(;Path_Toml, α=0.23);
```