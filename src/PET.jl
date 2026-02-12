"""
include(raw"src\\PET.jl")
"""

module pet
	import Dates, CSV, Tables
	using Suppressor, Logging
	export RUN_PET

	@suppress begin
		include("Read.jl")
		include("Write.jl")
		include("ReadToml.jl")
		include("PetFunc.jl")
		include("Interpolation.jl")
		include("Plot.jl")

		global_logger(ConsoleLogger())

		import ..interpolation, ..petFunc, ..petFunc, ..plot, ..read, ..write, ..readtoml
		export RUN_PET
	end

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PET
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function RUN_PET(;Path_Toml, α=-9999, Zaltitude=-99999)
			printstyled("======= Start Running PET ========== \n", color=:red)
			println(" ")

			# Read TOML input file
            Path_Toml₁  = joinpath(pwd(), Path_Toml)
            option     = readtoml.READTOML(Path_Toml₁)

			# Default values in input and not from TOML
				if  α > 0.0 option.param.α = α end
				if  Zaltitude > 0.0 option.param.Zaltitude=Zaltitude end


			# Reading CSV & filling up missing
			printstyled( "	===== Start reading & interpolate ===== \n"; color=:green)
				DayHour, meteo, Nmeteo, Pet_Obs, ΔT= read.READ_WEATHER(; option.date, option.path, option.flag, option.missings, option.param)
			printstyled( "	===== End reading ===== \n"; color=:green)
			println("")

				Pet_Sim = zeros(Float64, Nmeteo)

			# Computing for evey time step PET
				Threads.@threads for iT =1:Nmeteo
					Pet_Sim[iT] = pet.PENMAN_MONTEITH(;cst=option.cst, DayHour, flag=option.flag, iT, meteo, param=option.param, ΔT₁=ΔT[iT])
				end # for iT =1:Nmeteo

			# Interpolation
				∑Pet_Obs_Reduced, ∑Pet_Sim_Reduced, DayHour_Reduced, Nmeteo_Reduced, Pet_Obs_Reduced, Pet_Sim_Reduced = interpolation.TIME_INTERPOLATION(;Nmeteo, ΔT, Pet_Sim, Pet_Obs, option.output.ΔT_Output, DayHour)

			# Plotting output
			if option.flag.🎏_Plot
			printstyled( "	===== Start plotting ===== \n"; color=:green)
				plot.PLOT_PET(;∑Pet_Obs_Reduced, ∑Pet_Sim_Reduced, DayHour_Reduced, Nmeteo_Reduced, flag=option.flag, path=option.path, output=option.output, Pet_Obs_Reduced, Pet_Sim_Reduced)
			printstyled( "	===== End plotting ===== \n"; color=:green)
			println("")
			end

			# Writting output csv
			if option.flag.🎏_Table
			printstyled( "	===== Start writing table ===== \n"; color=:green)

				write.TABLE_PET(;DayHour, meteo, Nmeteo, option.path, Pet_Sim, Pet_Obs, option.flag)

				write.TABLE_PET_ΔToutput(;DayHour_Reduced, Pet_Obs_Reduced, Pet_Sim_Reduced, option.path, option.flag)

			printstyled( "	===== End writing table ===== \n"; color=:green)
			println("")
			end

		println(" ")
		printstyled("======= End Running PET ========== \n", color=:red)

		return DayHour, DayHour_Reduced, Pet_Obs, Pet_Obs_Reduced, Pet_Sim, Pet_Sim_Reduced;
		end  # function: PET
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PENMAN_MONTEITH_CONSTANT
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	# 	function PENMAN_MONTEITH_CONSTANT(;Latitude_Minute, Latitude_ᴼ, Longitude_Minute, Longitude_ᴼ)

	# 		Latitude, Longitude = petFunc.utils.LATITUDE_DEGREE_HOUR_2_DEGREE(;Latitude_Minute, Latitude_ᴼ,Longitude_Minute, Longitude_ᴼ)
	# 			println("Latitude= ", Latitude )
	# 			println("Longitude= ", Longitude )

	# 	return Latitude, Longitude
	# 	end  # function: PENMAN_MONTEITH_CONSTANT
	# # ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PENMAN_MONTEITH
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function PENMAN_MONTEITH(;cst, DayHour, flag, iT, meteo, param, ΔT₁)

			# Reading data
            RelativeHumidity = meteo.RelativeHumidity[iT]
            Radₛᵣ            = meteo.SolarRadiation[iT]
            Temp             = meteo.Temp[iT]
            TempSoil         = meteo.TempSoil[iT]
            Wind             = meteo.Wind[iT]
            DateTimeMinute   = DayHour[iT]

			λᵥ = petFunc.physics.λ_LATENT_HEAT_VAPORIZATION(;Temp)

			Pressure = petFunc.physics.ATMOSPHERIC_PRESSURE(;T_Kelvin=cst.T_Kelvin, Temp, Zaltitude=param.Zaltitude)

			Radₐ= petFunc.radiation.Rₐ_EXTRATERRESTRIAL_RADIATION_HOURLY(;DateTimeMinute, Gsc=cst.Gsc, param.Latitude, param.Longitude, Zaltitude=param.Zaltitude, Longitude_LocalTime=param.Longitude_LocalTime, ΔT₁)

			# 🎏_RaParam = true
			if flag.🎏_RaParam
				Rₐ_Inv =  Wind / param.RaParam
			else
				Rₐ_Inv = petFunc.aerodynamic.Rₐ_INV_AERODYNAMIC_RESISTANCE(;Hcrop=param.Hcrop, Karmen=cst.Karmen, Wind, Z_Humidity=param.Z_Humidity, Z_Wind=param.Z_Wind)
			end

			if flag.🎏_RsParam
				Rₛ = param.Rₛ
			else
				Rₛ = petFunc.aerodynamic.Rₛ_SURFACE_RESISTANCE(;param.R_Stomatal, param.Hcrop)
			end

			γ = petFunc.physics.γ_PSYCHROMETRIC(;Cₚ=cst.Cₚ, Pressure, ϵ=cst.ϵ, λᵥ)

			Δ = petFunc.humidity.Δ_SATURATION_VAPOUR_P_CURVE(;Temp)

			Eₛ = petFunc.humidity.Eᴼ_SATURATION_VAPOUR_PRESSURE(;Temp)

			Eₐ = petFunc.humidity.Eₐ_ACTUAL_VAPOUR_PRESSURE_RH(;RelativeHumidity, Eₛ)

			ρₐᵢᵣ = petFunc.physics.ρₐᵢᵣ_AIR_DENSITY(;Pressure, Temp, T_Kelvin=cst.T_Kelvin, ℜ=cst.ℜ, Eₐ)

			Radₛₒ = petFunc.radiation.Radₛₒ_CLEAR_SKY_RADIATION(;Radₐ, Zaltitude=param.Zaltitude)

			Radₙₗ = petFunc.radiation.Radₙₗ_LONGWAVE_RADIATION(;cst.σ, Temp, Eₐ, Radₛᵣ, T_Kelvin=cst.T_Kelvin, Radₛₒ)

			Radₙₛ = petFunc.radiation.Radₙₛ_NET_SHORTWAVE_RADIATION_REFLECTED(;α=param.α, Radₛᵣ)

			ΔRadₙ = petFunc.radiation.ΔRadₙ_NET_RADIATION(;Radₙₗ, Radₙₛ)

			G = petFunc.ground.G_SOIL_HEAT_FLUX_HOURLY(;DateTimeMinute, Latitude=param.Latitude, Longitude=param.Longitude, ΔRadₙ, param.Zaltitude, SoilHeatFlux_Sunlight=param.SoilHeatFlux_Sunlight, SoilHeatFlux_Night=param.SoilHeatFlux_Night )

			Pet_Sim = petFunc.penmanmonteith.PET_PENMAN_MONTEITH_HOURLY(;Cₚ=cst.Cₚ, Eₐ, Eₛ, G, Rₐ_Inv, ΔRadₙ, Rₛ, γ, Δ, λᵥ, ρₐᵢᵣ, ΔT₁, ρwater=cst.ρwater)

		return Pet_Sim
		end  # function: PENMAN_MONTEITH
	#------------------------------------------------------------------
end

Path_Toml = raw"DATA\PARAMETER\PetOption.toml"
DayHour, DayHour_Reduced, Pet_Obs, Pet_Obs_Reduced, Pet_Sim, Pet_Sim_Reduced = pet.RUN_PET(;Path_Toml, α=0.23);