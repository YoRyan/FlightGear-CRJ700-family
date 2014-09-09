## Bombardier CRJ700 series
## VNAV advisory system
###########################

var VNAV_UPDATE_PERIOD = 0.5;

var VNAV =
{
	route_manager: props.globals.getNode("autopilot/route-manager", 1),
	output_node: props.globals.initNode("autopilot/route-manager/vnav/target-altitude-ft", 0, "DOUBLE"),
	current_waypoint: 0,
	update: func
	{
		VNAV.current_waypoint = getprop("autopilot/route-manager/current-wp");
		var alt_preselect = getprop("controls/autoflight/altitude-select");
		var alt_cruise = getprop("autopilot/route-manager/cruise/altitude-ft");
		var alt_ceiling = math.min(alt_preselect, alt_cruise);
		var alt_target = 0;
		var from_info = VNAV.get_from_waypoint();
		if (from_info == nil or from_info[1] == nil) return;
		var to_info = VNAV.get_to_waypoint();
		if (to_info == nil or to_info[1] == nil) return;
		var alt_descent = VNAV.get_descent_altitude(to_info[1]) + to_info[0];
		var alt_climb = VNAV.get_climb_altitude(from_info[1]) + from_info[0];
		alt_target = math.min(alt_ceiling, alt_descent, alt_climb);
		VNAV.output_node.setDoubleValue(alt_target);
	},
	_loop_: func
	{
		VNAV.update();
		settimer(VNAV._loop_, VNAV_UPDATE_PERIOD);
	},
	get_from_waypoint: func
	{
		if (VNAV.current_waypoint <= 0) return;
		var from_waypoint = VNAV.route_manager.getNode("route/wp[" ~ (VNAV.current_waypoint - 1) ~ "]", 1);
		var from_dist = nil;
		var to_waypoint_rel = VNAV.route_manager.getNode("wp[0]", 1);
		var to_dist = to_waypoint_rel.getNode("dist", 1).getValue();
		if (to_dist != nil)
		{
			from_dist = from_waypoint.getNode("leg-distance-nm", 1).getValue() - to_dist;
		}
		var from_alt = from_waypoint.getNode("altitude-ft", 1).getValue();
		if (from_alt == nil or from_alt < 0) from_alt = 0;
		return [from_alt, from_dist];
	},
	get_to_waypoint: func
	{
		var to_waypoint_rel = VNAV.route_manager.getNode("wp[0]", 1);
		var to_waypoint = VNAV.route_manager.getNode("route/wp[" ~ VNAV.current_waypoint ~ "]", 1);
		var to_dist = to_waypoint_rel.getNode("dist", 1).getValue();
		var to_alt = to_waypoint.getNode("altitude-ft", 1).getValue();
		if (to_alt == nil or to_alt < 0) to_alt = 0;
		return [to_alt, to_dist];
	},
	get_climb_altitude: func(dist)
	{
		var vpa = getprop("autopilot/route-manager/vnav/climb-vpa-deg") * D2R;
		var alt = math.tan(vpa) * dist * NM2M * M2FT;
		return alt;
	},
	get_climb_distance: func(alt)
	{
		var vpa = getprop("autopilot/route-manager/vnav/climb-vpa-deg") * D2R;
		var dist = alt / math.tan(vpa) * FT2M * M2NM;
		return dist;
	},
	get_descent_altitude: func(dist)
	{
		var vpa = getprop("autopilot/route-manager/vnav/descent-vpa-deg") * D2R;
		var alt = math.tan(vpa) * dist * NM2M * M2FT;
		return alt;
	},
	get_descent_distance: func(alt)
	{
		var vpa = getprop("autopilot/route-manager/vnav/descent-vpa-deg") * D2R;
		var dist = alt / math.tan(vpa) * FT2M * M2NM;
		return dist;
	}
};
settimer(VNAV._loop_, 2);
