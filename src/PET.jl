"""
include(raw"src\\PET.jl")
"""

module pet
	import Dates, CSV, Tables

	include("Read.jl")
	include("Write.jl")
	include("ReadToml.jl")
	include("EvapoFunc.jl")
	include("Interpolation.jl")
	include("Plot.jl")

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PET
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function RUN_PET(;α)
			printstyled(" ==== Running PET ======= \n", color=:blue)

			# Read TOML input file
            Path_Toml₀ = raw"DATA\PARAMETER\PetOption.toml"
            Path_Toml  = joinpath(pwd(), Path_Toml₀)
            option     = readtoml.READTOML(Path_Toml)

			# Read .csv
				DayHour, meteo, Nmeteo, Pet_Obs, ΔT = read.READ_WEATHER(; option.date, option.path, option.flag, option.missings)

				Pet_Sim = zeros(Float64, Nmeteo)

			# Input which remain constant
				Latitude, Longitude = pet.PENMAN_MONTEITH_CONSTANT(; option.param.Latitude_Minute, option.param.Latitude_ᴼ, option.param.Longitude_Minute, option.param.Longitude_ᴼ)

			# Computing for evey time step
				Threads.@threads for iT =1:Nmeteo
					Pet_Sim[iT] = pet.PENMAN_MONTEITH(;DayHour, cst=option.cst, iT, Latitude, Longitude, meteo, param=option.param,  ΔT₁=ΔT[iT], option.flag)
				end # for iT =1:Nmeteo

			# Interpolation
			 ∑Pet_Obs_Reduced, ∑Pet_Sim_Reduced, ∑T_Obs, ∑T_Reduced, DayHour_Reduced, Nmeteo_Reduced, Pet_Obs_Reduced, Pet_Sim_Reduced = interpolation.TIME_INTERPOLATION(;Nmeteo, ΔT, Pet_Sim, Pet_Obs, option.output.ΔT_Output, DayHour)

			# Writting output csv
					write.TABLE_PET(;DayHour, meteo, Nmeteo, option.path, Pet_Sim, Pet_Obs, option.flag)

			# Plotting output
				plot.PLOT_PET(;∑Pet_Obs_Reduced, ∑Pet_Sim_Reduced, DayHour_Reduced, Nmeteo_Reduced, option.flag, option.path, option.output, Pet_Obs_Reduced, Pet_Sim_Reduced)

		end  # function: PET
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PENMAN_MONTEITH_CONSTANT
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function PENMAN_MONTEITH_CONSTANT(;Latitude_Minute, Latitude_ᴼ, Longitude_Minute, Longitude_ᴼ)

			Latitude, Longitude = evapoFunc.utils.LATITUDE_DEGREE_HOUR_2_DEGREE(;Latitude_Minute, Latitude_ᴼ,Longitude_Minute, Longitude_ᴼ)
				println("Latitude= ", Latitude )
				println("Longitude= ", Longitude )

		return Latitude, Longitude
		end  # function: PENMAN_MONTEITH_CONSTANT
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PENMAN_MONTEITH
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function PENMAN_MONTEITH(;cst, DayHour, iT, Latitude, Longitude, meteo, param, ΔT₁, flag)

			# Reading data
				RelativeHumidity = meteo.RelativeHumidity[iT]
				Radₛᵣ             = meteo.SolarRadiation[iT]
				Temp             = meteo.Temp[iT]
				TempSoil         = meteo.TempSoil[iT]
				Wind             = meteo.Wind[iT]
				DateTime         = DayHour[iT]

			λᵥ = evapoFunc.physics.λ_LATENT_HEAT_VAPORIZATION(;Temp)

			Pressure = evapoFunc.physics.ATMOSPHERIC_PRESSURE(;cst.T_Kelvin, Temp, param.Z_Altitude)

			Radₐ, 🎏_Daylight = evapoFunc.radiation.Rₐ_EXTRATERRESTRIAL_RADIATION_HOURLY(;DateTime, cst.Gsc, Latitude, Longitude, param.Z_Altitude, ΔT₁, flag.🎏_ω_Tradition)


			# 🎏_Ra_Param = true
			if flag.🎏_Ra_Param
				Rₐ_Inv =  Wind / param.Ra_Param
			else

				Rₐ_Inv = evapoFunc.aerodynamic.Rₐ_INV_AERODYNAMIC_RESISTANCE(;param.Hcrop, cst.Karmen, Wind, param.Z_Humidity, param.Z_Wind)
			end

			if flag.🎏_Rs_Param
				Rₛ = param.Rₛ
			else
				Rₛ = evapoFunc.aerodynamic.Rₛ_SURFACE_RESISTANCE(;param.R_Stomatal, param.Hcrop)
			end

			γ = evapoFunc.physics.γ_PSYCHROMETRIC(;cst.Cₚ, Pressure, cst.ϵ, λᵥ)

			Δ = evapoFunc.humidity.Δ_SATURATION_VAPOUR_P_CURVE(;Temp)

			Eₛ = evapoFunc.humidity.Eᴼ_SATURATION_VAPOUR_PRESSURE(;Temp)

			Eₐ = evapoFunc.humidity.Eₐ_ACTUAL_VAPOUR_PRESSURE_RH(;RelativeHumidity, Eₛ)

			ρₐᵢᵣ = evapoFunc.physics.ρₐᵢᵣ_AIR_DENSITY(;Pressure, Temp, cst.T_Kelvin, cst.ℜ, Eₐ)

			Radₛₒ = evapoFunc.radiation.Radₛₒ_CLEAR_SKY_RADIATION(;Radₐ, param.Z_Altitude)

			Radₙₗ = evapoFunc.radiation.Radₙₗ_LONGWAVE_RADIATION(;cst.σ, Temp, Eₐ, Radₛᵣ, cst.T_Kelvin,  Radₛₒ)

			Radₙₛ = evapoFunc.radiation.Radₙₛ_NET_SHORTWAVE_RADIATION_REFLECTED(;param.α, Radₛᵣ)

			ΔRadₙ = evapoFunc.radiation.ΔRadₙ_NET_RADIATION(;Radₙₗ, Radₙₛ)

			G = evapoFunc.ground.G_SOIL_HEAT_FLUX_HOURLY(;DateTime, Latitude, Longitude, ΔRadₙ, param.Z_Altitude, 🎏_Daylight,SoilHeatFlux_Sunlight=param.SoilHeatFlux_Sunlight, SoilHeatFlux_Night=param.SoilHeatFlux_Night )

			Pet_Sim = evapoFunc.penmanmonteith.PET_PENMAN_MONTEITH_HOURLY(;cst.Cₚ, param.Kc, Eₐ, Eₛ, G, Rₐ_Inv, ΔRadₙ, Rₛ, γ, Δ, λᵥ, ρₐᵢᵣ, ΔT₁, cst.ρwater)

		return Pet_Sim
		end  # function: PENMAN_MONTEITH
	#------------------------------------------------------------------
end

pet.RUN_PET(;α=0.2)