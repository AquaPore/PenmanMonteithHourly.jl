# =============================================================
#		module: write
# =============================================================
module write

	import Dates, CSV, Tables

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : STRUCT_2_FIELDNAMES
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function STRUCT_2_FIELDNAME(N::Int64, Structure)
			FieldName_Array = propertynames(Structure)

			N_FieldName = length(FieldName_Array)

			# Matrix
				Matrix = fill(0.0, (N, N_FieldName))

				i = 1
				for FieldName in FieldName_Array
					Struct_Array = getfield(Structure, FieldName)
					if isa(Struct_Array, Array)
						Matrix[1:N,i] = Float64.(Struct_Array[1:N])
					else
						Matrix[1,i] = Float64.(Struct_Array)
					end
					i += 1
				end

			# HEADER
			FieldName_String = fill(""::String, N_FieldName)
			i=1
			for FieldNames in FieldName_Array
				FieldName_String[i] =  String(FieldNames)
				i += 1
			end

		return Matrix, FieldName_String
		end # function STRUCT_2_FIELDNAME
	# .................................................................


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : TABLE_PET
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function TABLE_PET(;DayHour, meteo, Nmeteo, Pet_Sim, Pet_Obs, path, flag)

			Path_Output = joinpath(pwd(), path.Path_Output_Csv)
			println("		~~ ", Path_Output, "~~")

			Matrix₁, FieldName_String = write.STRUCT_2_FIELDNAME(Nmeteo, meteo)

			pushfirst!(FieldName_String, string("Date")) # Write the "Id" at the very begenning
			push!(FieldName_String, string("Pet_Sim")) # Write the "Id" at the very begenning

			if flag.🎏_PetObs
				push!(FieldName_String, string("Pet_Obs")) # Write the "Id" at the very begenning
			end

			if flag.🎏_PetObs
				CSV.write(Path_Output, Tables.table([DayHour Matrix₁ Pet_Sim Pet_Obs]), writeheader=true, header=FieldName_String, bom=true)
			else
				CSV.write(Path_Output, Tables.table([DayHour Matrix₁ Pet_Sim]), writeheader=true, header=FieldName_String, bom=true)
			end
		return nothing
		end  # function: TABLE_PET
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : TABLE_PET_ΔToutput
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function TABLE_PET_ΔToutput(;DayHour_Reduced, Pet_Obs_Reduced, Pet_Sim_Reduced, path, flag)

			Path_Output = joinpath(pwd(), path.Path_Output_ΔToutput_Csv)
			println("		~~ ", Path_Output, "~~")

			if flag.🎏_PetObs
				Header = ["Date", "Pet_Obs", "Pet_Sim"]
				CSV.write(Path_Output, Tables.table([DayHour_Reduced Pet_Obs_Reduced Pet_Sim_Reduced]), writeheader=true, header=Header, bom=true)
			else
				Header = ["Date", "Pet_Obs"]
				CSV.write(Path_Output, Tables.table([DayHour_Reduced Pet_Obs_Reduced ]), writeheader=true, header=Header, bom=true)
			end
		return nothing
		end  # function: TABLE_PET
	# ------------------------------------------------------------------



end  # module: write
# ............................................................