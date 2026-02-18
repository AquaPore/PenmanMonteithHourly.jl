# =============================================================
#		module: option
# =============================================================
module readtoml

using Configurations, TOML

@option struct PATH
	StationName ::String
	Path_Input::String
	Path_Output::String
	Filename_Input_ClimateCsv::String
   Filename_Output_Plot::String
   Filename_Output_TableCsv::String
   Filename_Output_TableΔTCsv::String

end # struct DATA

@option mutable struct PARAM
	Hcrop                 :: Float64
	Latitude              :: Float64
	Longitude             :: Float64
	Longitude_LocalTime   :: Float64
	R_Stomatal            :: Float64
	Zaltitude             :: Float64
	Z_Humidity            :: Float64
	Z_Wind                :: Float64
	α                    :: Float64
	SoilHeatFlux_Sunlight :: Float64
	SoilHeatFlux_Night    :: Float64
	Rₛ                  :: Float64
	RaParam               :: Float64
end # STRUCT PARAM

@option struct CST
	Cₚ     :: Float64
	Gsc      :: Float64
	Karmen   :: Float64
	T_Kelvin :: Float64
	σ       :: Float64
	ϵ       :: Float64
	ℜ      :: Float64
	ρwater  :: Float64
end # struct CST

@option struct DATE
	# Id_Start ::Int64
	# Id_End :: Int64
	Date_Start::Vector{Int}
	Date_End::Vector{Int}
end # struct DATE

@option struct OUTPUT
	ΔT_Output::Integer
end # struct DATE

@option struct MISSINGS
	ΔTmax_Missing::Integer
	MissingValue::Integer
end # struct DATE

@option struct FLAG
	🎏_RaParam::Bool
	🎏_RsParam::Bool
	🎏_PetObs::Bool
	🎏_Plot::Bool
	🎏_Table::Bool
end # struct DATE

@option struct OPTION
	path::PATH
	param::PARAM
	cst::CST
	date::DATE
	flag::FLAG
	output::OUTPUT
	missings::MISSINGS
end

# ----------------------------
function READTOML(PathToml)
	@assert isfile(PathToml)
	return Configurations.from_toml(OPTION, PathToml)
end  # function: OPTION

end  # module: option
# ..........................................................
