##
## Bombardier CRJ700 series
##
## Nasal control wrappers
##
##

var _ENGINES = 2;
var _SPEEDBRAKE_POSITIONS = [0, 0.25, 0.5, 0.75, 1];
# incAileron() was only designed to adjust autopilot heading settings
# so for roll, just hardcode an increment of 1
var _AP_ROLL_STEP = 1.0;
# incElevator() was only designed to adjust autopilot altitude settings
# so for pitch, just hardcode an increment of 1
var _AP_PITCH_STEP = 1.0;
# incThrottle() was only designed to adjust autopilot IAS settings
# so for Mach, just hardcode an increment of .01
var _AP_MACH_STEP = 0.01;

# aileron controls
var _incAileronAP = func (delta) {
        var mode = props.globals.getNode("controls/autoflight/lateral-mode", 1).getValue();
        if (mode == 0) {
                # basic roll mode
                #
                # If we are holding roll, aileron control adjusts the target
                # roll.
                # If we are holding heading, aileron control adjusts the target
                # heading.
                var roll_mode = props.globals.getNode("controls/autoflight/basic-roll-mode",
                                1).getValue();
                if (roll_mode == 0) {
                        if (delta > 0) {
                                fgcommand("property-adjust", props.Node.new({
                                                property: "controls/autoflight/basic-roll-select",
                                                step: _AP_ROLL_STEP
                                }));
                        } elsif (delta < 0) {
                                fgcommand("property-adjust", props.Node.new({
                                                property: "controls/autoflight/basic-roll-select",
                                                step: -_AP_ROLL_STEP
                                }));
                        }
                } elsif (roll_mode == 1) {
                        fgcommand("property-assign", props.Node.new({
                                        property: "controls/autoflight/basic-roll-heading-select",
                                        value: (getprop("controls/autoflight/basic-roll-heading-select")
                                                        + delta) % 360
                        }));
                }
        } elsif (mode == 1) {
                # heading select mode
                fgcommand("property-assign", props.Node.new({
                                property: "controls/autoflight/heading-select",
                                value: (getprop("controls/autoflight/heading-select") + delta) % 360
                }));
        }
};
incAileron = func (v, a) {
        if (props.globals.getNode("controls/autoflight/autopilot/engage", 1).
                        getBoolValue()) {
                _incAileronAP(a);
        } else {
                fgcommand("property-adjust", props.Node.new({
		                property: "controls/flight/aileron",
			        step: v,
			        min: -1,
			        max: 1
                }));
        }
};

# elevator controls
var _incElevatorAP = func (delta) {
        var mode = props.globals.getNode("controls/autoflight/vertical-mode", 1).
                        getValue();
        if (mode == 0) {
                # basic pitch mode
                if (delta > 0) {
                        fgcommand("property-adjust", props.Node.new({
                                        property: "controls/autoflight/pitch-select",
                                        step: _AP_PITCH_STEP
                        }));
                } elsif (delta < 0) {
                        fgcommand("property-adjust", props.Node.new({
                                        property: "controls/autoflight/pitch-select",
                                        step: -_AP_PITCH_STEP
                        }));
                }
        } elsif (mode == 1) {
                # altitude hold mode
                fgcommand("property-adjust", props.Node.new({
                                property: "controls/autoflight/altitude-select",
                                step: delta
                }));
        } elsif (mode == 2) {
                # vertical speed hold mode
                #
                # Stock incElevator() doesn't adjust vertical speed setting, but
                # implement it anyway - do what the user expects.
                fgcommand("property-adjust", props.Node.new({
                                property: "controls/autoflight/vertical-speed-select",
                                step: delta
                }));
        }
};
incElevator = func (v, a) {
        if (props.globals.getNode("controls/autoflight/autopilot/engage", 1).
                        getBoolValue()) {
                _incElevatorAP(a);
        } else {
                fgcommand("property-adjust", props.Node.new({
		                property: "controls/flight/elevator",
	                        step: v,
	                        min: -1,
			        max: 1
                }));
        }
};

# throttle controls
var _incThrottleAP = func (delta) {
        var mode = props.globals.getNode("controls/autoflight/speed-mode", 1).
                        getValue();
        if (mode == 0) {
                # speed hold mode (IAS)
                fgcommand("property-adjust", props.Node.new({
                                property: "controls/autoflight/speed-select",
                                step: delta
                }));
        } elsif (mode == 1) {
                # speed hold mode (Mach)
                if (delta > 0) {
                        fgcommand("property-adjust", props.Node.new({
                                        property: "controls/autoflight/mach-select",
                                        step: _AP_MACH_STEP
                        }));
                } elsif (delta < 0) {
                        fgcommand("property-adjust", props.Node.new({
                                        property: "controls/autoflight/mach-select",
                                        step: -_AP_MACH_STEP
                        }));
                }
        }
};
var _incThrottleEngine = func (number, delta) {
        var selected = props.globals.getNode("sim/input/selected").
                        getChild("engine", number, 1);
        if (selected.getBoolValue()) {
                fgcommand("property-adjust", props.Node.new({
                                property: "controls/engines/engine[" ~ number ~
                                                "]/throttle",
                                step: delta,
                                min: 0,
                                max: 1
                }));
        }
};
incThrottle = func (v, a) {
        if (props.globals.getNode("controls/autoflight/autothrottle-engage", 1).
                        getBoolValue()) {
                _incThrottleAP(a);
        } else {
                for (var i = 0; i < _ENGINES; i += 1) {
                        _incThrottleEngine(i, v);
                }
        }
};

# misc engine controls
var toggleArmReversers = func () {
        for (var i = 0; i < _ENGINES; i += 1) {
                fgcommand("property-toggle", props.Node.new({
                                property: "controls/engines/engine[" ~ i ~
                                                "]/reverser-armed"
                }));
        }
};
var reverseThrust = func () {
        for (var i = 0; i < _ENGINES; i += 1) {
                CRJ700.engines[i].toggle_reversers();
        }
};
var _incThrustModeEngine = func (number, delta) {
        var selected = props.globals.getNode("sim/input/selected").
                        getChild("engine", number, 1);
        if (selected.getBoolValue())
        {
                var engine = props.globals.getNode("controls/engines").
                                getChild("engine", number, 1);
                var modeN = engine.getChild("thrust-mode", 0, 1);
                if (modeN.getValue() == 0) {
                        if (!(engine.getChild("cutoff", 0, 1).getBoolValue() or
                                        engine.getChild("reverser", 0, 1).getBoolValue())) {
                                fgcommand("property-adjust", props.Node.new({
                                                property: modeN.getPath(),
                                                step: delta,
                                                min: 0,
                                                max: 3
                                }));
                        }
                } else {
                        fgcommand("property-adjust", props.Node.new({
                                        property: modeN.getPath(),
                                        step: delta,
                                        min: 0,
                                        max: 3
                        }));
                }
        }
}
var incThrustModes = func (v)
{
        for (var i = 0; i < _ENGINES; i += 1) {
                _incThrustModeEngine(i, v);
        }
};

# tiller controls
var stepTiller = func (v) {
        fgcommand("property-adjust", props.Node.new({
                        property: "controls/gear/tiller-steer-deg",
                        step: v,
                        min: -80,
                        max: 80
        }));
};
var setTiller = func (v) {
        fgcommand("property-assign", props.Node.new({
                        property: "controls/gear/tiller-steer-deg",
                        value: v
        }));
};

# misc flight controls
var cycleSpeedbrake = func () {
        fgcommand("property-cycle", props.Node.new({
                        property: "controls/flight/speedbrake",
                        value: _SPEEDBRAKE_POSITIONS
        }));
};
var stepGroundDump = func (v) {
        fgcommand("property-adjust", props.Node.new({
                        property: "controls/flight/ground-lift-dump",
                        step: v,
                        min: 0,
                        max: 2
        }));
};
