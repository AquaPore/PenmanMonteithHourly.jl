"""
include(raw"src\\PET.jl")
"""

module pet
	import Dates, CSV, Tables

	include("Read.jl")
	include("Write.jl")
	include("ReadToml.jl")
	include("EvapoFunc.jl")

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PET
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function RUN_PET()

			# Read TOML input file
				Path_Toml₀ =  raw"DATA\PARAMETER\PetOption.toml"
				Path_Toml = joinpath(pwd(), Path_Toml₀)
				option = readtoml.READTOML(Path_Toml)

				Path_Input = joinpath(pwd(), option.path.Path_Input)
				DateTime, meteo, Nmeteo = read.READ_WEATHER(Path_Input)

				PET = zeros(Float64, Nmeteo)

				# for  (iT, iiDateTime) in enumerate(DateTime)

					pet.PENMAN_MONTEITH_HOURLY(;cst=option.cst, param=option.param, meteo)



				# 	Path_Output = joinpath(pwd(), option.path.Path_Output)
				# 	write.TABLE_PET(DateTime, meteo, Nmeteo, Path_Output)

				# @show meteo
		end  # function: PET
	# ------------------------------------------------------------------

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PENMAN_MONTEITH
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	function PENMAN_MONTEITH_HOURLY(;cst, param, meteo)

		# evapoFunc.PET_PENMAN_MONTEITH_HOURLY(; cst.Cₚ, eₐ, eₛ, G, Rₐ_Inv, Rₙ, Rₛ, γ, Δ, λ, ρₐᵢᵣ)
		# meteo.Wind[1] = 1.0

		Wind = 1.5
		T =30
		RelativeHumidity = 2.24 / 4.24
		Radₛ = 3.47


		Year = 2020
		Month=10
		Day=1
		Hour=13

		Date = DateTime = Dates.DateTime.(Year, Month, Day, Hour)

		Rₐ_Inv = evapoFunc.aerodynamic.Rₐ_INV_AERODYNAMIC_RESISTANCE(;param.Hcrop, cst.Karmen, Wind, param.Z_Humidity, param.Z_Wind)
		println("Rₐ_INV =",  1/ Rₐ_Inv)

		Rₛ = evapoFunc.aerodynamic.Rₛ_SURFACE_RESISTANCE(;param.R_Stomatal, param.Hcrop)
			@show Rₛ

		Pressure = evapoFunc.physics.ATMOSPHERIC_PRESSURE(;param.Z_Altitude)
			println("Pressure=", Pressure )

		γ = evapoFunc.physics.γ_PSYCHROMETRIC(;cst.Cₚ, Pressure, cst.ϵ, cst.λ)
			@show γ

		ρₐᵢᵣ = evapoFunc.physics.ρₐᵢᵣ_AIR_DENSITY(;Pressure, T, cst.T_Kelvin, cst.ℜ)
			@show ρₐᵢᵣ

		Δ = evapoFunc.humidity.Δ_SATURATION_VAPOUR_P_CURVE(;T)
			@show Δ

		Eₛ = evapoFunc.humidity.Eᴼ_SATURATION_VAPOUR_PRESSURE(;T)
			@show Eₛ

		Eₐ = evapoFunc.humidity.Eₐ_ACTUAL_VAPOUR_PRESSURE_RH(;RelativeHumidity, Eₛ)
		@show Eₐ
		@show Eₛ - Eₐ

		Radₐ = evapoFunc.radiation.Rₐ_EXTRATERRESTRIAL_RADIATION_HOURLY(;Date, cst.Gsc, param.Latitude_Minute, param.Latitude_ᴼ, param.Longitude_Minute, param.Longitude_ᴼ, param.Z_Altitude)
			@show Radₐ

		Radₙₗ = evapoFunc.radiation.Radₙₗ_LONGWAVE_RADIATION(;cst.σₕₒᵤᵣ, T, Eₐ, Radₛ, cst.T_Kelvin, Radₐ, param.Z_Altitude)
		@show Radₙₗ

		ΔRadₙ = evapoFunc.radiation.ΔRadₙ_NET_RADIATION(;Radₙₗ, param.α, Radₛ)
		@show ΔRadₙ

		G = evapoFunc.ground.G_SOIL_HEAT_FLUX_HOURLY(;Date, param.Latitude_Minute, param.Latitude_ᴼ, param.Longitude_Minute, param.Longitude_ᴼ, ΔRadₙ, param.Z_Altitude)
			@show G

		ETₒ = evapoFunc.penmanmonteith.PET_PENMAN_MONTEITH_HOURLY(;cst.Cₚ, Eₐ, Eₛ, G, Rₐ_Inv, ΔRadₙ, Rₛ, γ, Δ, cst.λ, ρₐᵢᵣ)

		@show ETₒ

	return nothing
	end  # function: PENMAN_MONTEITH
	# ------------------------------------------------------------------

end

