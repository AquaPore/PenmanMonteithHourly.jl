# =============================================================
#		module: timestep
# =============================================================
module interpolate

	using Dates

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : TIMESETP
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function TIME_INTERPOLATION(;Nmeteo, ΔT, Pet_Sim,  Pet_Obs, ΔT_Output, DayHour )

			# Cumulating observed time
				∑T_Obs   = fill(0.0::Float64, Nmeteo)
				∑Pet_Sim = fill(0.0::Float64, Nmeteo)
				∑Pet_Obs = fill(0.0::Float64, Nmeteo)

				∑T_Obs[1] = 0
				∑Pet_Sim[1] = Pet_Sim[1]
				∑Pet_Obs[1] = Pet_Obs[1]
				for iT = 2:Nmeteo
					∑T_Obs[iT]   = ∑T_Obs[iT-1] + ΔT[iT]
					∑Pet_Sim[iT] = ∑Pet_Sim[iT-1] + Pet_Sim[iT]
					∑Pet_Obs[iT] = ∑Pet_Obs[iT-1] + Pet_Obs[iT]
				end

			# New ∑time step
				∑T_Reduced = []
				DayHour_Reduced = []
				append!(∑T_Reduced, 0::Int64)
				push!(DayHour_Reduced, DayHour[1])

				🎏Break = false
				while !(🎏Break)
					if ∑T_Reduced[end] + ΔT_Output > ∑T_Obs[end]
						🎏Break = true
						break
					else
						append!(∑T_Reduced, ∑T_Reduced[end] + ΔT_Output)
						push!(DayHour_Reduced, DayHour_Reduced[end] + Second(ΔT_Output))
						🎏Break = false
					end # if
				end # while
				Nmeteo_Reduced = length(∑T_Reduced)

			# Interpolate data
				∑Pet_Sim_Reduced = fill(0.0::Float64, Nmeteo_Reduced)
				∑Pet_Obs_Reduced = fill(0.0::Float64, Nmeteo_Reduced)

				for iT_Reduced = 1:Nmeteo_Reduced
					iT_X = 2
					🎏Break = false
					while !(🎏Break)
						if (∑T_Obs[iT_X-1] ≤ ∑T_Reduced[iT_Reduced] ≤ ∑T_Obs[iT_X]) || (iT_X == Nmeteo)
							🎏Break = true
							break
						else
							iT_X += 1
							🎏Break = false
						end # if
					end # while

				# Building a regression line which passes from POINT1(∑T_Obs[iT_X], ∑Pet_Sim[iT_Pr]) and POINT2: (∑T_Obs[iT_Pr+1], ∑Pet_Sim[iT_Pr+1])
					Intercept, Slope = POINTS_2_SlopeIntercept(∑T_Obs[iT_X-1], ∑Pet_Sim[iT_X-1], ∑T_Obs[iT_X], ∑Pet_Sim[iT_X])
					∑Pet_Sim_Reduced[iT_Reduced] = Slope * ∑T_Reduced[iT_Reduced] + Intercept

					Intercept, Slope = POINTS_2_SlopeIntercept(∑T_Obs[iT_X-1], ∑Pet_Obs[iT_X-1], ∑T_Obs[iT_X], ∑Pet_Obs[iT_X])
					∑Pet_Obs_Reduced[iT_Reduced] = Slope * ∑T_Reduced[iT_Reduced] + Intercept
			end # for iT = 1:Nmeteo_Reduced

			Pet_Sim_Reduced = fill(0.0::Float64, Nmeteo_Reduced)
			Pet_Sim_Reduced[1] = ∑Pet_Sim_Reduced[1]

			Pet_Obs_Reduced = fill(0.0::Float64, Nmeteo_Reduced)
			Pet_Obs_Reduced[1] = ∑Pet_Obs_Reduced[1]

			for iT_Reduced = 2:Nmeteo_Reduced
				Pet_Sim_Reduced[iT_Reduced] = ∑Pet_Sim_Reduced[iT_Reduced] - ∑Pet_Sim_Reduced[iT_Reduced-1]
				Pet_Obs_Reduced[iT_Reduced] = ∑Pet_Obs_Reduced[iT_Reduced] - ∑Pet_Obs_Reduced[iT_Reduced-1]
			end

		return ∑Pet_Obs_Reduced, ∑Pet_Sim_Reduced, ∑T_Obs, ∑T_Reduced, DayHour_Reduced, Nmeteo_Reduced, Pet_Obs_Reduced, Pet_Sim_Reduced
		end  # function: TIMESETP
	# ------------------------------------------------------------------


	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : POINTS_2_SlopeIntercept
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	"""POINTS_2_SlopeIntercept
	From Point1 [X1, Y1] and point2 [X2, Y2] compute Y = Slope.X₀ + Intercept
	"""
		function POINTS_2_SlopeIntercept(X1, Y1, X2, Y2)
			Slope = (Y2 - Y1) / (X2 - X1 + eps())
			Intercept = (Y1 * X2 - X1 * Y2) / (X2 - X1)
		return Intercept, Slope
		end # POINTS_2_SlopeIntercept
	#...................................................................

end  # module: timestep
# ............................................................