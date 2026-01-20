# =============================================================
#		module: evapoFunc
# =============================================================
module evapoFunc


	# =============================================================
	#		module: aerodynamic
	# =============================================================
	module aerodynamic

		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION :Rₐ_INV
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		rₐ: [s m⁻¹] AERODYNAMIC RESISTANCE,

		INPUT
			Z_Wind:  [m] height of wind measurements,
			Z_Humidity: [m]:  height of humidity measurements,
			wIND: [m s⁻¹] wind speed at height Z_Wind,
			Hcrop: [m] height of the crop

		PROCESSES
			Z_ZERO_PLANE() [m]zero plane displacement height ,
			Z_ROUGHNESS_MOMENTUM() [m] roughness length governing momentum transfer [m],
			Z_ROUGHNESS_TRANSFER() [m] roughness length governing transfer of heat and vapour [m],

		# CONSTANT
			k [m] von Karman's constant, 0.41 [-],
		"""
		function Rₐ_INV_AERODYNAMIC_RESISTANCE(;Hcrop, Karmen, Wind, Z_Humidity, Z_Wind)

			#------------------------------
				function Z_ZERO_PLANE(Hcrop)
					Z_0 = (2.0 / 3.0) * Hcrop
				return Z_0
				end
			#------------------------------
			#------------------------------
				function Z_ROUGHNESS_MOMENTUM(Hcrop)
					Z_RoughnessMomentum = 0.123 * Hcrop
				return Z_RoughnessMomentum
				end  # function: Z_ROUGHNESS_MOMENTUM
			#------------------------------
			#------------------------------
				function Z_ROUGHNESS_TRANSFER(Z_RoughnessMomentum)
					Z_RoughnessTransfer = 0.1 * Z_RoughnessMomentum
					return Z_RoughnessTransfer
				end  # function: Z_ROUGHNESSMOMENTUM
			#------------------------------

			Z_0 = Z_ZERO_PLANE(Hcrop)
			Z_RoughnessMomentum = Z_ROUGHNESS_MOMENTUM(Hcrop)
			Z_RoughnessTransfer = Z_ROUGHNESS_TRANSFER(Z_RoughnessMomentum)

			if Z_Wind < Z_0
				error("Z_Wind = $Z_Wind ≥ Z_0 = $Z_0")
			end
			if Z_Humidity < Z_0
				error("Z_Humidity = $Z_Wind ≥ Z_0 = $Z_0")
			end

			Rₐ_Inv =  (Wind * Karmen^2 ) / log((Z_Wind - Z_0 ) / Z_RoughnessMomentum) * log((Z_Humidity - Z_0) / Z_RoughnessTransfer)

			return Rₐ_Inv
			end  # function: Rₐ_INV_AERODYNAMIC_RESISTANCE
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION :  Rₛ_SURFACE_RESISTANCE
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
			Rₛ: [s m⁻¹] SURFACE RESISTANCE

			INPUT:
				R_Stomatal: [s m⁻¹] bulk stomatal resistance of the well-illuminated leaf
				Hcrop: [m] height of the crop
		"""
			function Rₛ_SURFACE_RESISTANCE(;R_Stomatal, Hcrop)
				LAI = min(24.0 * Hcrop, 5.0)
				LAIactive = LAI * 0.5

				Rₛ = R_Stomatal / LAIactive
			return Rₛ
			end  # function: Rₛ_SURFACE_RESISTANCE
		# ------------------------------------------------------------------

	end  # module: aerodynamic
	# ............................................................


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : ATMOSPHERIC_PRESSURE
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function ATMOSPHERIC_PRESSURE(;Z_Altitude)
			P = 101.3 * ((293.0 - 0.0065 * Z_Altitude) / 293 ) ^ 5.26
		return P
		end  # function: ATMOSPHERIC_PRESSURE
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : γ_PSYCHROMETRIC
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		γ PSYCHROMETRIC CONSTANT [kPa °C-1],

		INPUT:
		P atmospheric pressure [kPa],

		CONSTANTS:
			λ: [MJ kg-1] latent heat of vaporization, 2.45 ,
			cp: [MJ kg-1 °C-1] specific heat at constant pressure, 1.013 10-3 ,
			ε: ratio molecular weight of water vapour/dry air = 0.622.

		"""


		function γ_PSYCHROMETRIC(;Cp, P, ϵ, λ)
			γ = (Cp * P) /  (ϵ * λ)
		return γ
		end  # function: ϵ
	# ------------------------------------------------------------------








	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : Eᴼ_SATURATED_VAPOUR_PRESSURE
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function Eᴼ_SATURATED_VAPOUR_PRESSURE(;T)
			Eᴼ = 0.6108 * exp(17.27 * T / (T + 237.3))
		return Eᴼ
		end  # function: SATURATED_VAPOUR_PRESSURE
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : Ea_ACTUAL_VAPOUR_PRESSURE_RH
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function Ea_ACTUAL_VAPOUR_PRESSURE_RH(;RelativeHumidity, Eₛ)
			Ea = 	RelativeHumidity * Eₛ
			# @assert Ea ≤ 1.0
			@assert Eₛ ≥ Ea
		return Ea
		end  # function: Ea_ACTUAL_VAPOUR_PRESSURE_RH
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : Ea_ACTUAL_VAPOUR_PRESSURE_RH
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function Ea_ACTUAL_VAPOUR_PRESSURE_Tdew(;Tdew)
			Eₐ = 0.6108 * exp((17.27 * Tdew)/(Tdew + 237.3))
		return Eₐ
		end  # function: Ea_ACTUAL_VAPOUR_PRESSURE_RH
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : Ea_2_Tdew
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function Ea_2_Tdew(Eₐ)
			D = (1 / 17.27) * log(Eₐ / 0.6108)
			C =237.3
			Tdew = C * D / (1.0 - D)
		return Tdew
		end  # function: Ea_2_Tdew
	# ------------------------------------------------------------------



	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : Δ_SATURATION_VAPOUR_P_CURVE
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function Δ_SATURATION_VAPOUR_P_CURVE(T)
			ΔP = 4098 *0.6108 * exp(17.27 * T / (T + 237.3)) / (T + 237.3) ^ 2
		return ΔP
		end  # function: Δ_SATURATION_VAPOUR_P_CURVE
	# ------------------------------------------------------------------



	# =============================================================
	#		module: radiation
	# =============================================================
	module radiation
		using Dates

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : Extraterrestrial_radiation
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""Estimate daily extraterrestrial radiation (*Ra*, 'top of the atmosphere
		radiation').

		Based on equation 21 in Allen et al (1998). If monthly mean radiation is
		required make sure *sol_dec*. *sha* and *irl* have been calculated using
		the day of the year that corresponds to the middle of the month.

		**Note**: From Allen et al (1998): "For the winter months in latitudes
		greater than 55 degrees (N or S), the equations have limited validity.
		Reference should be made to the Smithsonian Tables to assess possible
		deviations."

		:param latitude: Latitude [radians]
		:param sol_dec: Solar declination [radians]. Can be calculated using
			``sol_dec()``.
		:param sha: Sunset hour angle [radians]. Can be calculated using
			``sunset_hour_angle()``.
		:param ird: Inverse relative distance earth-sun [dimensionless]. Can be
			calculated using ``inv_rel_dist_earth_sun()``.
		:return: Daily extraterrestrial radiation [MJ m-2 day-1]
		:rtype: float
		"""

		function  Rₐ_EXTRATERRESTRIAL_RADIATION_HOURLY(;Gsc, Latitude, Date)

			Latitude_Radian = Latitude * π/180

			DayOfYear = Dates.dayofyear(Date)

			Hour = Dates.hour(Date)

			dᵣ_INVERSE_DISTANCE_SUN_EARTH(DayOfYear) = 1.0 + 0.033 * cos(DayOfYear * 2.0 * π / 365.0)
			dᵣ = dᵣ_INVERSE_DISTANCE_SUN_EARTH(DayOfYear)

			δ_SOLAR_INCLINATION(DayOfYear) = 0.409 * sin(DayOfYear * 2.0 * π / 365.0 - 1.39)
			δ = δ_SOLAR_INCLINATION(DayOfYear)

			# ω_SOLAR_TIME_ANGLE(Latitude_Radian, δ) = acos(-tan(Latitude_Radian) * tan(δ))

			b = 2* π * (DayOfYear - 81) /364

			Sc = 0.1645 * sin(2*b) - 0.1255 * cos(b) - 0.025 * sin(b)

			ωₛ_SOLAR_TIME_ANGLE(Hour, Sc) = ((Hour + Sc ) -12.0) * π / 12.0

			ωₛ = ωₛ_SOLAR_TIME_ANGLE(Hour, Sc)

			ω₂ =
			ω₁ =

		Rₐ = (12.0 * 60.0 / π) * Gsc * dᵣ * (ω₂ - ω₁) * sin(Latitude_Radian) * sin(δ) + cos(Latitude_Radian) * cos(δ) * (sin(ω₂)- sin(ω₁))

		return
		end  # function: Extraterrestrial_radiation
	# ------------------------------------------------------------------

		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Rso_CLEAR_SKY_RADIATION
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			function Rso_CLEAR_SKY_RADIATION(;Rₐ, Z_Altitude)
				Rₛₒ = (0.75 + 2.0E-5 * Z_Altitude) * Rₐ
			return Rₛₒ
			end  # function: Rso_CLEAR_SKY_RADIATION
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Rₙₛ_NET_SHORTWAVE_RADIATION
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			function Rₙₛ_NET_SHORTWAVE_RADIATION(;α, Rₛ)
			"""The net shortwave radiation resulting from the balance between incoming and reflected solar radiation
				* α albedo or canopy reflection coefficient, which is 0.23 for the hypothetical grass reference crop [dimensionless]"""

				Rₙₛ = (1.0 - α ) * Rₛ
			return Rₙₛ
			end  # function: Rₙₛ_NET_SHORTWAVE_RADIATION
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Rₙₗ_LONGWAVE RADIATION
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			function Rₙₗ_LONGWAVE_RADIATION(;σ, T_Min, T_Max, eₐ, Rₛ, Rₛₒ, T_Kelvin )
				T1 = (σ * ((T_Kelvin + T_Max)^4 + (T_Kelvin + T_Min)^4) / 2.0)

				# Correction for air humidity
				T2 = (0.34 - (0.14 * √eₐ))

				# Correction fro effect of cloundiness
				T3 = (1.35 * min(Rₛ / Rₛₒ, 1.0) - 0.35)
				Rₙₗ =  T1 * T2 * T3
			return Rₙₗ
			end  # function: Rₙₗ_LONGWAVE RADIATION
		# ------------------------------------------------------------------



		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Rₙ_NET_RADIATION
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			function Rₙ_NET_RADIATION(Rₙₗ, Rₙₛ)
				Rₙ = Rₙₛ + Rₙₗ
			return Rₙ
			end  # function: RN
		# ------------------------------------------------------------------



	end  # module: radiation
	# ............................................................

end  # module: evapoFunc
# ............................................................

