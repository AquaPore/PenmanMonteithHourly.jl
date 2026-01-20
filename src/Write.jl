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
		function TABLE_PET(DateTime, meteo, Nmeteo, Path_Output)
			Matrix₁, FieldName_String = write.STRUCT_2_FIELDNAME(Nmeteo, meteo)

			pushfirst!(FieldName_String, string("Date")) # Write the "Id" at the very begenning

			println(FieldName_String)

			CSV.write(Path_Output, Tables.table([DateTime Matrix₁]), writeheader=true, header=FieldName_String, bom=true)
		return nothing
		end  # function: TABLE_PET
	# ------------------------------------------------------------------


end  # module: write
# ............................................................