"""
include(raw"src\\PET.jl")
"""

module pet
	import Dates, CSV, Tables

	include("Read.jl")
	include("Write.jl")
	include("ReadToml.jl")

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PET
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function RUN_PET()

			# Read TOML input file
				Path_Toml₀ =  raw"DATA\PARAMETER\PetOption.toml"
				Path_Toml = joinpath(pwd(), Path_Toml₀)
				option = readtoml.READTOML(Path_Toml)


			# T_Max = 25.0
			# T_Min = 18.0

			# Rh_Min = 0.54
			# Rh_Max = 0.83


			# P = pet.ATMOSPHERIC_PRESSURE(;option.cst.Z_Altitude)

			# γ = pet.FUNC_γ(;option.cst.Cp, P, option.cst.ϵ, option.cst.λ)

			# Ra_Inv = pet.RA_INV(;option.cst.Hcrop, option.cst.Karmen, Wind=1.0, option.cst.Z_Humidity, option.cst.Z_Wind)

			# Rs = pet.RS(;option.cst.R_Stomatal, option.cst.Hcrop)

			# Eₛ_Min =pet.Eᴼ_SATURATED_VAPOUR_PRESSURE(;T=T_Min)

			# Eₛ_Max = pet.Eᴼ_SATURATED_VAPOUR_PRESSURE(;T=T_Max)

			# Eₛ = (Eₛ_Min + Eₛ_Max) * 0.5

			# Eₐ = (pet.Ea_ACTUAL_VAPOUR_PRESSURE_RH(;RelativeHumidity=Rh_Max, Eₛ=Eₛ_Min) + pet.Ea_ACTUAL_VAPOUR_PRESSURE_RH(;RelativeHumidity=Rh_Min, Eₛ=Eₛ_Max)) * 0.5

			# println(Eₐ)

			# Tdew = pet.Ea_2_Tdew(Eₐ)

			# println(Tdew)



			# Pet = () / ()


			# Eₐ = (Eₛ_Min * Rh_Max + Eₛ_Max * Rh_Min) / 2.0

			# println(Eₛ - Eₐ)

				# 	Path_Input = joinpath(pwd(), option.path.Path_Input)
				# 	DateTime, meteo, Nmeteo = read.READ_WEATHER(Path_Input)


				# 	Path_Output = joinpath(pwd(), option.path.Path_Output)
				# 	write.TABLE_PET(DateTime, meteo, Nmeteo, Path_Output)

				# @show meteo
		end  # function: PET
	# ------------------------------------------------------------------




end



# - `Rn` (W m-2): net radiation. Carefull: not the isothermal net radiation
# - `VPD` (kPa): air vapor pressure deficit
# - `γˢ` (kPa K−1): apparent value of psychrometer constant (see `PlantMeteo.γ_star`)
# - `Rbₕ` (s m-1): resistance for heat transfer by convection, i.e. resistance to sensible heat
# - `Δ` (KPa K-1): rate of change of saturation vapor pressure with temperature (see `PlantMeteo.e_sat_slope`)
# - `ρ` (kg m-3): air density of moist air.
# - `aₛₕ` (1,2): number of sides that exchange energy for heat (2 for leaves)
# - `Cₚ` (J K-1 kg-1): specific heat of air for constant pressure
# '''
