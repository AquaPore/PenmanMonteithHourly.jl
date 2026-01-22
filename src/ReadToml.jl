# =============================================================
#		module: option
# =============================================================
module readtoml

	using Configurations, TOML

	@option mutable struct PATH
      Path_Input  :: String
      Path_Output :: String
	end # struct DATA

	@option mutable struct PARAM
      Hcrop            :: Float64
      Latitude_ᴼ       :: Float64
      Latitude_Minute  :: Float64
      Longitude_ᴼ      :: Float64
      Longitude_Minute :: Float64
      R_Stomatal       :: Float64
      Z_Altitude       :: Float64
      Z_Humidity       :: Float64
      Z_Wind           :: Float64
      α                :: Float64
	end # STRUCT PARAM

	@option struct CST
      Cₚ       :: Float64
      Gsc      :: Float64
		Karmen   :: Float64
      T_Kelvin :: Float64
      λ        :: Float64
      σ        :: Float64
		σₕₒᵤᵣ     :: Float64
      ϵ        :: Float64
		ℜ       :: Float64
	end # struct CST

	@option mutable struct OPTION
      path  :: PATH
      param :: PARAM
      cst   :: CST
	end


	# ----------------------------
	function READTOML(PathToml)
		@assert isfile(PathToml)
	return Configurations.from_toml(OPTION, PathToml)
	end  # function: OPTION

end  # module: option
# ............................................................