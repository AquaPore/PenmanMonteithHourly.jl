# =============================================================
#		module: plot
# =============================================================
module plot
	using CairoMakie, Dates

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#		FUNCTION : PLOT_PET
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		function PLOT_PET(;DayHour, Pet_Sim, Pet_Obs, Nmeteo, path)

			Line = range(0.0, stop=maximum(Pet_Obs), length=100)

			# Activating the figure
			CairoMakie.activate!(type="svg", pt_per_unit=1)
			Fig = Figure(font="Sans", titlesize=30,  xlabelsize=20, ylabelsize=20, labelsize=30, fontsize=20, width=4000, height=1200)

			Axis_1 =  Axis(Fig[1, 1], title= " Penman-Monteith",  yticklabelcolor=:black, yaxisposition=:left, rightspinecolor=:black, ytickcolor=:black, xlabel= L"$PET_{Sim}$ $[mm]$", ylabel= L"$PET_{Obs}$ $[mm]$", xgridvisible=false, ygridvisible=false, width=800, height=800)

				scatter!(Axis_1, Pet_Sim, Pet_Obs, color=:blue)
				lines!(Axis_1, Line, Line, color=:grey, linestyle=:dash, linewidth=2)

			Axis_2 =  Axis(Fig[2, 1], yticklabelcolor=:black, yaxisposition=:left, rightspinecolor=:black, ytickcolor=:black, xlabel= L"$Date$ ", ylabel= L"$PET$ ", xgridvisible=false, ygridvisible=false, width=2000, height=600, xticklabelrotation= π / 2.0)

				Step = Int64(ceil(Nmeteo / 30))
				X_Ticks= 1:Step:Nmeteo
				Time_Dates = Date.(DayHour[X_Ticks] )
				Axis_2.xticks = (X_Ticks, string.(Time_Dates))


			lines!(Axis_2, 1:1:Nmeteo, Pet_Sim, linewidth=1, color=:red, label= L"$PET_{Sim}$ $[mm]$")

			lines!(Axis_2, 1:1:Nmeteo, Pet_Obs, linewidth=1, color=(:blue, 0.6), label= L"$PET_{Obs}$ $[mm]$")

			Leg = Legend(Fig[3,1], Axis_2, framevisible=true, tellheight=true, tellwidth=true, labelsize=25, nbanks=2)


			colgap!(Fig.layout, 15)
			rowgap!(Fig.layout, 15)
			resize_to_layout!(Fig)
			trim!(Fig.layout)
			display(Fig)

			Path_Output = joinpath(pwd(), path.Path_Output_Plot)
			save(Path_Output, Fig, pt_per_unit=0.5)
			println("			 ~ ", Path_Output, "~")

		return nothing
		end  # function: PLOT_PET
	# ------------------------------------------------------------------

end  # module: plot
# ............................................................