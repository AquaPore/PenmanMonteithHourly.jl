# =============================================================
#		module: evapoFunc
# =============================================================
module evapoFunc
	# =============================================================
	#		module: penmanmonteith
	# =============================================================
	module penmanmonteith

		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : PENMAN_MONTEITH_HOURLY
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			function PET_PENMAN_MONTEITH_HOURLY(; Cₚ, Eₐ, Eₛ, G, Rₐ_Inv, ΔRadₙ, Rₛ, γ, Δ, λ, ρₐᵢᵣ)

				@show inv(λ)
				ETₒ = inv(λ) * (Δ * (ΔRadₙ - G) + ρₐᵢᵣ * Cₚ * (Eₛ - Eₐ) * Rₐ_Inv) / (Δ + γ * (1.0 + Rₛ * Rₐ_Inv))

			return ETₒ
			end  # function: PENMAN_MONTEITH_HOURLY
		# ------------------------------------------------------------------

	end  # module: penmanmonteith
	# ............................................................

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
			#..............................

			#------------------------------
				function Z_ROUGHNESS_MOMENTUM(Hcrop)
					Z_RoughnessMomentum = 0.123 * Hcrop
				return Z_RoughnessMomentum
				end  # function: Z_ROUGHNESS_MOMENTUM
			#.....................................

			#------------------------------
				function Z_ROUGHNESS_TRANSFER(Z_RoughnessMomentum)
					Z_RoughnessTransfer = 0.1 * Z_RoughnessMomentum
					return Z_RoughnessTransfer
				end  # function: Z_ROUGHNESSMOMENTUM
			#........................................

			Z_0 = Z_ZERO_PLANE(Hcrop)
			Z_RoughnessMomentum = Z_ROUGHNESS_MOMENTUM(Hcrop)
			Z_RoughnessTransfer = Z_ROUGHNESS_TRANSFER(Z_RoughnessMomentum)

			if Z_Wind < Z_0
				error("Z_Wind = $Z_Wind ≥ Z_0 = $Z_0")
			end
			if Z_Humidity < Z_0
				error("Z_Humidity = $Z_Wind ≥ Z_0 = $Z_0")
			end

			Rₐ_Inv = ( Wind * Karmen^2 ) / (log((Z_Wind - Z_0 ) / Z_RoughnessMomentum) * log((Z_Humidity - Z_0) / Z_RoughnessTransfer))

			return Rₐ_Inv
			end  # function: Rₐ_INV_AERODYNAMIC_RESISTANCE
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION :  Rₛ_SURFACE_RESISTANCE
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		Rₛ: [s m⁻¹] SURFACE RESISTANCE

		INPUT:
			* R_Stomatal: [s m⁻¹] bulk stomatal resistance of the well-illuminated leaf,
			* Hcrop: [m] height of the crop
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


	# =============================================================
	#		module: psychometric
	# =============================================================
	module physics
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : ATMOSPHERIC_PRESSURE
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			function ATMOSPHERIC_PRESSURE(;Z_Altitude)
				Pressure = 101.3 * ((293.0 - 0.0065 * Z_Altitude) / 293 ) ^ 5.26
			return Pressure
			end  # function: ATMOSPHERIC_PRESSURE
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : γ_PSYCHROMETRIC
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		γ PSYCHROMETRIC CONSTANT [kPa °C-1],
		The specific heat at constant pressure is the amount of energy required to increase the temperature of a unit mass of air by one degree at constant pressure.

		INPUT:
			Pressure: [kPa] atmospheric pressure ,

		CONSTANTS:
			* λ: [MJ kg-1] latent heat of vaporization, 2.45 ,
			* Cp: [MJ kg-1 °C-1] specific heat at constant pressure, 1.013 10-3 ,
			* ε: ratio molecular weight of water vapour/dry air = 0.622.
		"""
			function γ_PSYCHROMETRIC(;Cₚ, Pressure, ϵ, λ)
				γ = (Cₚ * Pressure) /  (ϵ * λ)
			return γ
			end  # function: ϵ
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : ρₐᵢᵣ_AIR_DENSITY
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		ρₐᵢᵣ MEAN AIR DENSITY AT CONSTANT PRESSURE [kg m-3]

		INPUT:
			* Pressure: [kPa] Atmospheric pressure,
			* T_Kelvin: constant Conversion from C to Kelvin,
			* ℜ: [ kJ kg-1 K-1] constantspecific gas constant
		"""
			function ρₐᵢᵣ_AIR_DENSITY(;Pressure, T, T_Kelvin, ℜ)
				ρₐᵢᵣ = Pressure / (ℜ * (T_Kelvin + T))
			return ρₐᵢᵣ
			end  # function: ρₐᵢᵣ_AIR_DENSITY
			# ------------------------------------------------------------------
	end  # module: physics
	# ............................................................


	# =============================================================
	#		module: humidity
	# =============================================================
	module humidity
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Eᴼ_SATURATED_VAPOUR_PRESSURE
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		Eᴼ(T) [kPa]: saturation vapour pressure at the air temperature
		"""
			function Eᴼ_SATURATION_VAPOUR_PRESSURE(;T)
				Eᴼ = 0.6108 * exp(17.27 * T / (T + 237.3))
			return Eᴼ
			end  # function: SATURATED_VAPOUR_PRESSURE
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Ea_ACTUAL_VAPOUR_PRESSURE_RH
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		Eₐ [kPa] ACTUAL VAPOUR PRESSURE

		INPUT
		RelativeHumidity: [0-1  degree of saturation of the air (eₐ) to the saturation (eₛ =eₒ(T)) vapour pressure at the same temperature (T):
		"""
			function Eₐ_ACTUAL_VAPOUR_PRESSURE_RH(;RelativeHumidity, Eₛ)
				Eₐ = 	RelativeHumidity * Eₛ
				@assert RelativeHumidity ≤ 1.0
				@assert Eₛ ≥ Eₐ
			return Eₐ
			end  # function: Ea_ACTUAL_VAPOUR_PRESSURE_RH
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Δ_SATURATION_VAPOUR_P_CURVE
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			"""
			Δ: [kPa °C-1] SLOPE OF SATURATION VAPOUR PRESSURE CURVE AT AIR TEMPERATURE T ,
			slope of the relationship between saturation vapour pressure and temperature
			"""
			function Δ_SATURATION_VAPOUR_P_CURVE(;T)
				Δ = 4098.0 *0.6108 * exp(17.27 * T / (T + 237.3)) / (T + 237.3) ^ 2
			return Δ
			end  # function: Δ_SATURATION_VAPOUR_P_CURVE
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Ea_2_Tdew
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		""" not used """
			function Eₐ_2_Tdew(;Eₐ)
				P₁ = (1.0 / 17.27) * log(Eₐ / 0.6108)
				Tdew = 237.3 * P₁ / (1.0 - P₁)
			return Tdew
			end  # function: Ea_2_Tdew
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Ea_ACTUAL_VAPOUR_PRESSURE_RH
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			""" not used """
			function Eₐ_ACTUAL_VAPOUR_PRESSURE_Tdew(;Tdew)
				Eₐ = 0.6108 * exp((17.27 * Tdew)/(Tdew + 237.3))
			return Eₐ
			end  # function: Ea_ACTUAL_VAPOUR_PRESSURE_RH
		# ------------------------------------------------------------------

	end  # module: humidity
	# ............................................................


	# =============================================================
	#		module: radiation
	# =============================================================
	module radiation
		using Dates, SolarPosition, Dates

		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION :  ωₛ_SUNSET_HOUR_ANGLE
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			function ωₛ_SUNSET_HOUR_ANGLE(;Latitude_Radian, δ)
            ωₛ  = acos(-tan(Latitude_Radian) * tan(δ))
			return ωₛ
			end # ωₛ_SUNSET_HOUR_ANGLE
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION :  N_HOURS_DAYLIGHT
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			function N_HOURS_DAYLIGHT(;ωₛ)
            Ndaylight = 2.0 * 24.0 * ωₛ / (2.0 * π)
			return Ndaylight
			end # N_HOURS_DAYLIGHT
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : ω_SOLAR_TIME_ANGLE_HOUR
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		""" Solar time angle, accounts that earth rotates 15ᵒ every hour. Hour angle is negative before solar noon, 0 at solar noon and positive afterwards"""
			function ω_SOLAR_TIME_ANGLE_HOUR(;🎏_Tradition=false, Date, Latitude, Longitude, Z_Altitude, ΔT=1.0)
				if !🎏_Tradition
					# define observer location (latitude, longitude, altitude in meters)
					Obs = Observer(Latitude, Longitude, Z_Altitude)

					Positions = SolarPosition.solar_position(Obs, Date, PSA(), HUGHES());
					SolarNoon = SolarPosition.Utilities.next_solar_noon(Obs,Date, SPA())

					Positions_SolarNoon = SolarPosition.solar_position(Obs, SolarNoon, PSA(), HUGHES())
					ω = (Positions.azimuth - Positions_SolarNoon.azimuth) * π / 180.0
				else
               Lz        = 15.0 # [Degree ]Longitude of the center of the local time Lz = 15.0 for senegal
               DayOfYear = max(Dates.dayofyear(Date) -1, 1)
               Hour      = Dates.hour(Date)

					B  = 2 * π * (DayOfYear - 81) / 364
					Sc = 0.1645 * sin(2.0*B) - 0.1255 * cos(B) - 0.025 * sin(B)
					ω  = (((Hour+0.5) + 0.06667 * (Lz - Longitude) + Sc ) - 12.0) * π / 12.0
				end
				@show ω
				ω₁ = ω - π * ΔT / 24.0
				ω₂ = ω + π * ΔT / 24.0

				@show ω₁, ω₂

			return ω₁, ω₂
			end #  ω_SOLAR_TIME_ANGLE_HOUR
			# ------------------------------------------------------------------

		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Extraterrestrial_radiation
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		* Rₐ [MJ m-2 hour-1] EXTRATERRESTRIAL RADIATION IN THE HOUR (OR SHORTER) PERIOD ,

		INPUT
			* Gsc: [MJ m-2 min-1] solar constant = 0.0820 ,
			* Dₑₛ: [m] inverse relative distance Earth-Sun (Equation 23),
			* δ: solar declination [rad] (Equation 24),
			* ϕ: latitude [rad] (Equation 22),
			* ω1 [rad]: solar time angle at beginning of period [rad] (Equation 29),
			* ω2 [rad]: solar time angle at end of period  (Equation 30).
			* ΔT [hour] time step
			* Longitude_ᴼ : Longitude of the measured site [degress west of Greenwish]
			* longitude of the measurement site [degrees west of Greenwich]

		PROCESS
			ω [rad] solar time angle at midpoint of hourly or shorter period [rad]
			ωₛ [rad] sunset hour angle
		"""
		function  Rₐ_EXTRATERRESTRIAL_RADIATION_HOURLY(;Date, Gsc, Latitude_Minute, Latitude_ᴼ, Longitude_Minute, Longitude_ᴼ, Lz= 0.0, Z_Altitude, ΔT=1.0)

			Latitude = (Latitude_ᴼ + Latitude_Minute / 60.0)
			Longitude = (Longitude_ᴼ + Longitude_Minute / 60.0)
			Latitude_Radian = Latitude * π / 180.0
         DayOfYear       = Dates.dayofyear(Date)

			δ_SOLAR_INCLINATION(DayOfYear) = 0.409 * sin(DayOfYear * 2.0 * π / 365.0 - 1.39)
				δ = δ_SOLAR_INCLINATION(DayOfYear)

			ω₁, ω₂ = ω_SOLAR_TIME_ANGLE_HOUR(;🎏_Tradition=true, Date, Latitude, Longitude, Z_Altitude, ΔT=1.0)

			Dₑₛ_INVERSE_DISTANCE_SUN_EARTH(DayOfYear) = 1.0 + 0.033 * cos(DayOfYear * 2.0 * π / 365.0)
				Dₑₛ = Dₑₛ_INVERSE_DISTANCE_SUN_EARTH(DayOfYear)

			Radₐ =  (12.0 / π) * Gsc * Dₑₛ * ((ω₂ - ω₁) * sin(Latitude_Radian) * sin(δ) + cos(Latitude_Radian) * cos(δ) * (sin(ω₂)- sin(ω₁)))
		return Radₐ
		end  # function: Extraterrestrial_radiation
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Rₙₗ_LONGWAVE RADIATION
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		Rₙₗ: [MJ m-2 hour-1] NET OUTGOING LONGWAVE RADIATION.

		INPUT
			* σₕₒᵤᵣ: [MJ K-4 m-2 hour-1] Stefan-Boltzmann constant [ 4.903 10-9 ];
			* T: [ᵒC] average hourly temperature,
			* Eₐ: [kPa] actual vapour pressure;
			* Radₛ: [MJ m-2 hour-1] measured solar radiation;

		PROCESSES
			* Radₛₒ[MJ m-2 hour-1]: clear-sky radiation.

			Radₛ/Radₛₒ relative shortwave radiation (limited to ≤ 1.0),
		"""
			function Radₙₗ_LONGWAVE_RADIATION(;σₕₒᵤᵣ, T, Eₐ, Radₛ, T_Kelvin, Radₐ, Z_Altitude)

				function Radₛₒ_CLEAR_SKY_RADIATION(;Radₐ, Z_Altitude)
					return Radₛₒ = (0.75 + 2.0E-5 * Z_Altitude) * Radₐ
				end

				# if 🎏_Hourly
				# T₁ = (σ * ((T_Kelvin + T_Max)^4 + (T_Kelvin + T_Min)^4) / 2.0)

				Radₛₒ = Radₛₒ_CLEAR_SKY_RADIATION(;Radₐ, Z_Altitude)

				# Correction for effect of cloundiness
				Radₙₗ =  (σₕₒᵤᵣ * (T_Kelvin + T) ^4) * (0.34 - (0.14 * √Eₐ)) * (1.35 * min(Radₛ / Radₛₒ, 1.0) - 0.35)
			return Radₙₗ
			end  # function: Rₙₗ_LONGWAVE RADIATION
		# ------------------------------------------------------------------


		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : Radₙ_NET_RADIATION
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		Rₙ [MJ m-2 day-1] NET RADIATION AT THE CROP SURFACE

		INPUT
			* Radₙₛ: [MJ m-2 day-1] Incoming net shortwave radiation,
		 	* Radₙₗ: [MJ m-2 day-1] Outgoing net longwave radiation.

		PARAMETER
			* α: [-] albedo or canopy reflection coefficient, which is 0.23 for the hypothetical grass reference crop

		PROCESSES
			* Radₙₛ: [MJ m-2 day-1] net shortwave radiation resulting from the balance between incoming and reflected solar radiation
		"""
			function ΔRadₙ_NET_RADIATION(;Radₙₗ, α, Radₛ)

				function Radₙₛ_NET_SHORTWAVE_RADIATION_REFLECTED(;α, Radₛ)
					Radₙₛ = (1.0 - α ) * Radₛ
				return Radₙₛ
				end  # function: Rₙₛ_NET_SHORTWAVE_RADIATION

		 		Radₙₛ = Radₙₛ_NET_SHORTWAVE_RADIATION_REFLECTED(;α, Radₛ)

				ΔRadₙ = Radₙₛ - Radₙₗ
			return ΔRadₙ
			end  # function: Rₙ_NET_RADIATION
		# ------------------------------------------------------------------

	end  # module: radiation
	# ............................................................


	# =============================================================
	#		module: ground
	# =============================================================
	module ground
		using SolarPosition, Dates

		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		#		FUNCTION : G_SOIL_HEAT_FLUX
		# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		"""
		G: [MJ m-2 day-1] SOIL HEAT FLUX DENSITY

		INPUT
			* Rₙ: [MJ m-2 day-1] measured solar radiation;
		"""
			function G_SOIL_HEAT_FLUX_HOURLY(;Date, Latitude_Minute, Latitude_ᴼ, Longitude_Minute, Longitude_ᴼ, ΔRadₙ, Z_Altitude)

				# Determening if daylight or nighttime or daylight
					Latitude = (Latitude_ᴼ + Latitude_Minute / 60.0)
					Longitude = (Longitude_ᴼ + Longitude_Minute / 60.0)

					Obs = Observer(Latitude, Longitude, Z_Altitude)

					Tsunrise = SolarPosition.next_sunrise(Obs, DateTime(Date))
					Tsunrise_Hour = Dates.hour(Tsunrise)

					Tsunset = SolarPosition.next_sunset(Obs, DateTime(Date))
					Tsunset_Hour = Dates.hour(Tsunset)

					T_Hour = Dates.hour(Date)

				if Tsunset_Hour ≥ T_Hour ≥ Tsunrise_Hour
					return G = 0.1 * ΔRadₙ
				else
					return G = 0.5 * ΔRadₙ
				end
			end  # function: G_SOIL_HEAT_FLUX
		# ------------------------------------------------------------------

	end  # module: ground
	# ............................................................

end  # module: evapoFunc
# ............................................................

