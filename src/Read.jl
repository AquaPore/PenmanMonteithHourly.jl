# =============================================================
#		module: read
# =============================================================
module read
	using Dates, CSV, Tables, DataFrames, Logging, Revise
	import ..interpolation, ..petFunc

	global_logger(ConsoleLogger())

	Base.@kwdef mutable struct METEO
		# Id
      Id               :: Vector{Int64}
		# Humidity [0-1]
      RelativeHumidity :: Vector{Float64}
		# Solar radiation mean [ W/M⁻²]
      SolarRadiation   :: Vector{Float64}
		# Maximum temperature [⁰C]
      Temp             :: Vector{Float64}
		# Minimum temperature [⁰C]
      TempSoil         :: Vector{Float64}
		# Velocity of wind speed [M S⁻¹]
      Wind             :: Vector{Float64}
		# Data which are missing and which were artficially filled
      🎏_DataMissing   :: Vector{Bool}
	end
"""
Read weather data from .csv 

"""
	function READ_WEATHER(;date, path, flag, missings, param)

		# READING DATA FROM CSV
			Path_Input = joinpath(pwd(), path.Path_Input)
			println("		~~ ", Path_Input, "~~")
				@assert isfile(Path_Input)

			Data₀  = CSV.read(Path_Input, DataFrame; header=true)

			# Id₀     = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Id))
			Year₀   = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Year))
			Month₀  = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Month))
			Day₀    = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Day))
			Hour₀   = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Hour))
			Minute₀ = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Minute))

			DayHour = Dates.DateTime.(Year₀, Month₀, Day₀, Hour₀, Minute₀) #  <"standard"> "proleptic_gregorian" calendar
			Nmeteo₀ = length(Year₀)
			Id₀ = collect(1:1:Nmeteo₀)

			RelativeHumidity₀ = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("Humidity[%]")))
			SolarRadiation₀   = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("SolarRadiation[W/m²]")))
			Temp₀             = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("AirTemperature[°C]")))
			TempSoil₀         = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("SoilTemperature[°C]")))
			Wind₀             = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("WindSpeed[m/s]")))

			if flag.🎏_PetObs && ("PotentialEvapotranspiration[mm]" ∈ names(Data₀))
				Pet_Obs = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("PotentialEvapotranspiration[mm]")))
			else
				Pet_Obs = zeros(Nmeteo₀)
			end

		# DETERMENING PERIOD OF INTEREST
			DateTrue = fill(false, Nmeteo₀)
			DateStart = Dates.Date(Dates.Year(date.Date_Start[1]),Dates.Month(date.Date_Start[2]),Dates.Day(date.Date_Start[3]),Dates.Hour(date.Date_Start[4]), Dates.Minute(date.Date_Start[5]))

			DateEnd = Dates.Date(Dates.Year(date.Date_End[1]),Dates.Month(date.Date_End[2]),Dates.Day(date.Date_End[3]),Dates.Hour(date.Date_End[4]), Dates.Minute(date.Date_End[5]))

			for iT=1:Nmeteo₀
				if DateStart ≤ DayHour[iT] ≤ DateEnd
					DateTrue[iT] = true
				end
			end # for iT=1:Nmeteo₀
			Nmeteo = sum(DateTrue)
			@assert Nmeteo ≥ 1

		# Reducing the data to the data of interest
         Id₀               = Id₀[DateTrue]
         DayHour           = DayHour[DateTrue]
         RelativeHumidity₀ = RelativeHumidity₀[DateTrue]
         SolarRadiation₀   = SolarRadiation₀[DateTrue]
         Temp₀             = Temp₀[DateTrue]
         TempSoil₀         = TempSoil₀[DateTrue]
         Wind₀             = Wind₀[DateTrue]
         Pet_Obs           = Pet_Obs[DateTrue]

		# TIME-STEP
			ΔT = zeros(Float64, Nmeteo)
			# Computing ΔT of the time step
				for iT=1:Nmeteo
					if iT ≥ 2
						ΔT[iT] = Dates.value(DayHour[iT] - DayHour[iT-1]) / 1000
					end
				end # for iT=1:Nmeteo
				ΔT[1] = copy(ΔT[2])

				@assert minimum(ΔT)==maximum(ΔT)

			# MISSING DATA: linear interpolation between the missing variables
				🎏_DataMissing = fill(false, Nmeteo)
				SolarRadiation₀, 🎏_DataMissing   = read.FINDING_9999(;Input=SolarRadiation₀, DayHour, Nmeteo, missings,🎏_DataMissing, Error=missings.MissingValue)

					# If <🎏_DataMissing> = true but it is during night time, we can assume that SolarRadiation is close to 0 and therefore we can remove data missing and assume SolarRadiation₀ = 0.0
					for iT=1:Nmeteo
						if 🎏_DataMissing[iT]

							🎏_Daylight = petFunc.radiation.SUNLIGHT_HOURS(;DateTimeMinute=DayHour[iT], param.Latitude, param.Longitude, param.Zaltitude)

							if !(🎏_Daylight)
								SolarRadiation₀[iT] = min(SolarRadiation₀[iT], 10.0)
								🎏_DataMissing[iT] = false
							end # if !(🎏_Daylight[iT])

						end # if 🎏_DataMissing[iT]
					end # for iT=1:Nmeteo

				RelativeHumidity₀, 🎏_DataMissing = read.FINDING_9999(;Input=RelativeHumidity₀, DayHour, Nmeteo, missings, 🎏_DataMissing, Error= missings.MissingValue)
				Temp₀, 🎏_DataMissing             = read.FINDING_9999(;Input=Temp₀, DayHour, Nmeteo, missings, 🎏_DataMissing, Error=missings.MissingValue)
				TempSoil₀, 🎏_DataMissing         = read.FINDING_9999(;Input=TempSoil₀, DayHour, Nmeteo, missings, 🎏_DataMissing, Error=missings.MissingValue)
				Wind₀, 🎏_DataMissing             = read.FINDING_9999(;Input=Wind₀, DayHour, Nmeteo, missings, 🎏_DataMissing, Error=missings.MissingValue)

				if flag.🎏_PetObs
					🎏_DataMissing_PetObs = fill(false, Nmeteo)
					Pet_Obs, 🎏_DataMissing_PetObs                        = read.FINDING_9999(;Input=Pet_Obs, DayHour, Nmeteo, missings, 🎏_DataMissing=🎏_DataMissing_PetObs, Error=missings.MissingValue)
				end

					# If <🎏_DataMissing> = true but it is during night time, we can assume that SolarRadiation is close to 0 and therefore we can remove data missing and assume SolarRadiation₀ = 0.0 and it does not matter of the values of the others variables
					iiMissing = 0
					for iT=1:Nmeteo
						if 🎏_DataMissing[iT]

							🎏_Daylight = petFunc.radiation.SUNLIGHT_HOURS(;DateTimeMinute=DayHour[iT], param.Latitude, param.Longitude, param.Zaltitude)

							if !(🎏_Daylight)
								🎏_DataMissing[iT] = false
							else
								iiMissing += 1
							end # if !(🎏_Daylight[iT])

						end # if 🎏_DataMissing[iT]
					end # for iT=1:Nmeteo
					if iiMissing ≥ 1
						printstyled("		WARNING: Number of Missing data = $iiMissing"; color=:yellow)
						println("")
					end

		# CONVERSION
			for iT=1:Nmeteo
				# [%] ➡ [0-1]
					RelativeHumidity₀[iT] = RelativeHumidity₀[iT] / 100.0

				# Removing negative values
				if flag.🎏_PetObs
					Pet_Obs[iT] = max(Pet_Obs[iT], 0.0)
				end

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
		function FINDING_9999(;Input, Nmeteo, DayHour, missings, 🎏_DataMissing, Error= missings.MissingValue)
			# Error_9999 = fill(false, N)
         NoValue_Istart = []
         NoValue_Iend   = []
         Error_Count = []

			if Input[Nmeteo] == Error
				error("Cannot interpolate if for it=N is missings.MissingValue")
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

				for iT = NoValue_Istart[iError]:NoValue_Iend[iError]
				 	Input[iT] = Slope * Float64(iT) + Intercept

					if missings.ΔTmax_Missing < ΔT_Error
						🎏_DataMissing[iT] = true
					end # if missings.ΔTmax_Missing < ΔT_Error

				end # for iT =NoValue_Istart[iError]:NoValue_Iend[iError]
			end

		return  Input, 🎏_DataMissing
		end  # function: FINDING_999
	# ------------------------------------------------------------------
end  # module: read
# ............................................................