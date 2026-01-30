# =============================================================
#		module: option
# =============================================================
module readtoml

	using Configurations, TOML

	@option struct PATH
      Path_Input       :: String
      Path_Output_Csv  :: String
      Path_Output_Plot :: String
	end # struct DATA

	@option struct PARAM
		Hcrop               :: Float64
		Latitude_ᴼ          :: Float64
		Latitude_Minute     :: Float64
		Longitude_ᴼ         :: Float64
		Longitude_Minute    :: Float64
		Longitude_LocalTime :: Float64
		R_Stomatal          :: Float64
		Z_Altitude          :: Float64
		Z_Humidity          :: Float64
		Z_Wind              :: Float64
		α                   :: Float64
		Kc                  :: Float64
		SoilHeatFlux_Sunlight :: Float64
		SoilHeatFlux_Night :: Float64
		Rₛ :: Float64
		Ra_Param :: Float64
	end # STRUCT PARAM

	@option struct CST
      Cₚ       :: Float64
      Gsc      :: Float64
      Karmen   :: Float64
      T_Kelvin :: Float64
      σ        :: Float64
      ϵ        :: Float64
      ℜ        :: Float64
      ρwater   :: Float64
	end # struct CST

	@option struct DATE
      Id_Start ::Int64
		Id_End :: Int64
	end # struct DATE

	@option struct FLAG
      🎏_Ra_Param    :: Bool
      🎏_Rs_Param    :: Bool
      🎏_ω_Tradition :: Bool
	end # struct DATE

	@option struct OPTION
		path  :: PATH
		param :: PARAM
		cst   :: CST
		date :: DATE
		flag :: FLAG
	end

	# ----------------------------
	function READTOML(PathToml)
		@assert isfile(PathToml)
	return Configurations.from_toml(OPTION, PathToml)
	end  # function: OPTION

end  # module: option
# ..........................................................