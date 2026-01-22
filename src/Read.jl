# =============================================================
#		module: read
# =============================================================
module read

	using Dates, CSV, Tables, DataFrames

	Base.@kwdef mutable struct METEO
		# Humidity [0-1]
      RelativeHumidity            :: Union{Missing,Vector}
		# Solar radiation max [ W/m³]
      SolarRadiation_Max  :: Union{Missing,Vector}
		# Solar radiation mean [ W/m³]
      SolarRadiation_Mean :: Union{Missing,Vector}
		# Solar radiation min [ W/m³]
      SolarRadiation_Min  :: Union{Missing,Vector}
		# Maximum temperature [⁰C]
      T_Max            :: Union{Missing,Vector}
		# Minimum temperature [⁰C]
      T_Min            :: Union{Missing,Vector}
		# Velocity of wind speed [M S⁻¹]
      Wind                   :: Union{Missing,Vector}
	end

	function READ_WEATHER(Path_Input)

		@assert isfile(Path_Input)

		Data₀ = CSV.read(Path_Input, DataFrame; header=true)

      Year                = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Year))
      Month               = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Month))
      Day                 = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Day))
      Hour                = convert(Vector{Int64}, Tables.getcolumn(Data₀, :Hour))

		DateTime = Dates.DateTime.(Year, Month, Day, Hour) #  <"standard"> "proleptic_gregorian" calendar

      RelativeHumidity    = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("Humidity[%]")))
      SolarRadiation_Max  = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("SolarRadiation_Max[W/M3]")))
      SolarRadiation_Mean = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("SolarRadiation_Mean[W/M3]")))
      SolarRadiation_Min  = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("SolarRadiation_Min[W/M3]")))
      T_Max               = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("AirTemperature_Max[⁰C]")))
      T_Min               = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("AirTemperature_Min[⁰C]")))
      Wind                = convert(Union{Vector,Missing}, Tables.getcolumn(Data₀, Symbol.("WindSpeed[M/S]")))

		Nmeteo = length(Year)

		meteo = METEO(RelativeHumidity,  SolarRadiation_Max, SolarRadiation_Mean, SolarRadiation_Min, T_Max, T_Min, Wind)

		# Testing for missing data
		FieldName = propertynames(meteo)
		for iiFieldName ∈ FieldName
			Struct_Array = getfield(meteo, iiFieldName)

			for i=1:Nmeteo
				if ismissing(Struct_Array[i])
					@error "$(iiFieldName) cell is empty at Id= $i"
				end
			end
		end

	return DateTime, meteo, Nmeteo
	end

end  # module: read
# ............................................................