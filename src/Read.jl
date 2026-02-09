# =============================================================
#		module: read
# =============================================================
module read
	using Dates, CSV, Tables, DataFrames
	import ..interpolation

	Base.@kwdef mutable struct METEO
		# Id
      Id               :: Union{Missing,Vector}
		# Humidity [0-1]
      RelativeHumidity :: Union{Missing,Vector}
		# Solar radiation mean [ W/M⁻²]
      SolarRadiation   :: Union{Missing,Vector}
		# Maximum temperature [⁰C]
      Temp             :: Union{Missing,Vector}
		# Minimum temperature [⁰C]
      TempSoil         :: Union{Missing,Vector}
		# Velocity of wind speed [M S⁻¹]
      Wind             :: Union{Missing,Vector}
		# Data which are missing and which were artficially filled
      🎏_DataMissing   :: Vector{Bool}
	end
"""
Read weather data from .csv

"""
	function READ_WEATHER(; date, path, flag, missings)

		# READING DATA FROM CSV
			Path_Input = joinpath(pwd(), path.Path_Input)
			@assert isfile(Path_Input)
			Data₀  = CSV.read(Path_Input, DataFrame; header=true)

			Id₀     = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Id))
			Year₀   = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Year))
			Month₀  = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Month))
			Day₀    = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Day))
			Hour₀   = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Hour))
			Minute₀ = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Minute))

			Nmeteo₀ = length(Year₀)

			DayHour = Dates.DateTime.(Year₀, Month₀, Day₀, Hour₀, Minute₀) #  <"standard"> "proleptic_gregorian" calendar

			RelativeHumidity₀ = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("Humidity[%]")))
			SolarRadiation₀   = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("SolarRadiation[W/m²]")))
			Temp₀             = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("AirTemperature[°C]")))
			TempSoil₀         = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("SoilTemperature[°C]")))
			Wind₀             = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("WindSpeed[m/s]")))

			if flag.🎏_PetObs
				Pet_Obs = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("PotentialEvapotranspiration[mm]")))
			else
				Pet_Obs = zeros(Nmeteo₀)
			end
			# 🎏_DataMissing      = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("FlagMissing")))

		# DETERMENING PERIOD OF INTEREST
			DateTrue = fill(false, Nmeteo₀)
			convert(Vector{Bool},DateTrue)
			for iD=1:Nmeteo₀
				if date.Id_Start ≤ iD ≤ date.Id_End
					DateTrue[iD] = true
				else
					DateTrue[iD] = false
				end
			end

			# The new number of data
				Nmeteo = date.Id_End - date.Id_Start + 1

		# TIME-STEP
			ΔT = zeros(Float64, Nmeteo₀)
			# Computing ΔT of the time step
				for iT=date.Id_Start:date.Id_End
					if iT ≥ 2
						ΔT[iT] = Dates.value(DayHour[iT] - DayHour[iT-1]) / 1000
						if ΔT[iT] < 600 || ΔT[iT] > 600
							println("Dates issue=", iT, " = ",ΔT[iT])
						end
					end
				end # for iT=1:Nmeteo
				ΔT[1] = copy(ΔT[2])

		# Reducing the data to the data of interest
			ΔT = ΔT[DateTrue]
			DayHour = DayHour[DateTrue]

		🎏_DataMissing = fill(false, Nmeteo)

		# MISSING DATA: linear interpolation between the missing variables
         RelativeHumidity₀, 🎏_DataMissing = read.FINDING_9999(;Input=RelativeHumidity₀[DateTrue], DayHour, Nmeteo, missings, 🎏_DataMissing, Error=-9999)
         SolarRadiation₀, 🎏_DataMissing   = read.FINDING_9999(;Input=SolarRadiation₀[DateTrue], DayHour, Nmeteo, missings, 🎏_DataMissing, Error=-9999)
         Temp₀, 🎏_DataMissing             = read.FINDING_9999(;Input=Temp₀[DateTrue], DayHour, Nmeteo, missings, 🎏_DataMissing, Error=-9999)
         TempSoil₀, 🎏_DataMissing         = read.FINDING_9999(;Input=TempSoil₀[DateTrue], DayHour, Nmeteo, missings, 🎏_DataMissing, Error=-9999)
         Wind₀, 🎏_DataMissing             = read.FINDING_9999(;Input=Wind₀[DateTrue], DayHour, Nmeteo, missings, 🎏_DataMissing, Error=-9999)

         Pet_Obs, ~           = read.FINDING_9999(;Input=Pet_Obs[DateTrue], DayHour, Nmeteo, missings, 🎏_DataMissing, Error=-9999)

		# CONVERSION
			for iT=1:Nmeteo
				# [%] ➡ [0-1]
					RelativeHumidity₀[iT] = RelativeHumidity₀[iT] / 100.0

				# Removing negative values
					Pet_Obs[iT] = max(Pet_Obs[iT], 0.0)

				# Solar radiation filter
					SolarRadiation₀[iT] = max(SolarRadiation₀[iT] - 0.1, 0.0)
			end # for iT=1:Nmeteo

      meteo = METEO(Id=Id₀, RelativeHumidity=RelativeHumidity₀, SolarRadiation=SolarRadiation₀, Temp=Temp₀, TempSoil=TempSoil₀, Wind=Wind₀, 🎏_DataMissing=🎏_DataMissing)

	return DayHour, meteo, Nmeteo, Pet_Obs, ΔT
	end # function READ_WEATHER


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : FINDING_999
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	""" Linear intyerpolation between the missing data if not greater than 4 hours"""
		function FINDING_9999(;Input, Nmeteo, DayHour, missings, 🎏_DataMissing, Error= -9999)
			# Error_9999 = fill(false, N)
         NoValue_Istart = []
         NoValue_Iend   = []
         Error_Count = []

			if Input[Nmeteo] == Error
				error("Cannot interpolate if for it=N is -9999")
			end

			iError = 0
			for iT=1:Nmeteo-1
				if Input[iT] == Error
					if Input[max(iT-1,1)] ≠ Error
						NoValue_Istart = append!(NoValue_Istart, iT)
						iError = 1
					end

					if Input[min(iT+1, Nmeteo)] ≠ Error
						NoValue_Iend = append!(NoValue_Iend, iT)

						Error_Count = append!(Error_Count, iError)
					else
						iError += 1
					end
				end
			end # for i=1:N

			@assert length(NoValue_Istart) == length(NoValue_Iend)

			N = length(NoValue_Istart)
			for iError=1:N
				ΔT_Error = Dates.value( DayHour[NoValue_Iend[iError]+1] - DayHour[NoValue_Istart[iError]]) / 1000.0

            X1 = max(NoValue_Istart[iError] - 1, 1)
            Y1 = Input[X1]
            X2 = min(NoValue_Iend[iError] + 1, Nmeteo)
            Y2 = Input[X2]

				Intercept, Slope = interpolation.POINTS_2_SlopeIntercept(X1, Y1, X2, Y2)

				for iT =NoValue_Istart[iError]:NoValue_Iend[iError]
				 	Input[iT] = Slope * Float64(iT) + Intercept

					if missings.ΔTmax_Missing < ΔT_Error
						🎏_DataMissing[iT] = true
						@show 🎏_DataMissing[iT]
					end # if missings.ΔTmax_Missing < ΔT_Error

				end # for iT =NoValue_Istart[iError]:NoValue_Iend[iError]
			end

		return  Input, 🎏_DataMissing
		end  # function: FINDING_999
	# ------------------------------------------------------------------
end  # module: read
# ............................................................