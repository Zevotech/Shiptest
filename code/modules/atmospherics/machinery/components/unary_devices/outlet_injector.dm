/obj/machinery/atmospherics/components/unary/outlet_injector
	icon_state = "inje_map-3"

	name = "air injector"
	desc = "Has a valve and pump attached to it."

	use_power = IDLE_POWER_USE
	can_unwrench = TRUE
	shift_underlay_only = FALSE
	hide = TRUE

	resistance_flags = FIRE_PROOF | UNACIDABLE | ACID_PROOF //really helpful in building gas chambers for xenomorphs

	var/injecting = 0

	var/volume_rate = 100

	var/frequency = 0
	var/id = null
	var/datum/radio_frequency/radio_connection

	interacts_with_air = TRUE
	layer = GAS_SCRUBBER_LAYER

	pipe_state = "injector"

/obj/machinery/atmospherics/components/unary/outlet_injector/CtrlClick(mob/user)
	if(can_interact(user))
		on = !on
		investigate_log("was turned [on ? "on" : "off"] by [key_name(user)]", INVESTIGATE_ATMOS)
		update_appearance()
	return ..()

/obj/machinery/atmospherics/components/unary/outlet_injector/AltClick(mob/user)
	if(can_interact(user))
		volume_rate = MAX_TRANSFER_RATE
		investigate_log("was set to [volume_rate] L/s by [key_name(user)]", INVESTIGATE_ATMOS)
		to_chat(user, span_notice("You maximize the volume output on [src] to [volume_rate] L/s."))
		update_appearance()
	return ..()

/obj/machinery/atmospherics/components/unary/outlet_injector/Destroy()
	SSradio.remove_object(src,frequency)
	return ..()

/obj/machinery/atmospherics/components/unary/outlet_injector/update_icon_nopipes()
	cut_overlays()
	if(showpipe)
		// everything is already shifted so don't shift the cap
		add_overlay(getpipeimage(icon, "inje_cap", initialize_directions))

	if(!nodes[1] || !on || !is_operational)
		icon_state = "inje_off"
	else
		icon_state = "inje_on"

/obj/machinery/atmospherics/components/unary/outlet_injector/process_atmos(seconds_per_tick)
	..()

	injecting = TRUE

	if(!on || !is_operational || !isopenturf(loc))
		return

	var/datum/gas_mixture/air_contents = airs[1]

	if(!air_contents || air_contents.return_temperature() <= 0)
		return

	loc.assume_air_ratio(air_contents, volume_rate / air_contents.return_volume())
	air_update_turf()

	update_parents()

/obj/machinery/atmospherics/components/unary/outlet_injector/proc/inject()

	if(on || injecting || !is_operational)
		return

	var/datum/gas_mixture/air_contents = airs[1]

	injecting = TRUE

	if(air_contents.return_temperature() > 0)
		loc.assume_air_ratio(air_contents, volume_rate / air_contents.return_volume())
		update_parents()

	flick("inje_inject", src)

/obj/machinery/atmospherics/components/unary/outlet_injector/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	if(frequency)
		radio_connection = SSradio.add_object(src, frequency)

/obj/machinery/atmospherics/components/unary/outlet_injector/proc/broadcast_status()

	if(!radio_connection)
		return

	var/datum/signal/signal = new(list(
		"tag" = id,
		"device" = "AO",
		"power" = on,
		"volume_rate" = volume_rate,
		//"timestamp" = world.time,
		"sigtype" = "status"
	))
	radio_connection.post_signal(src, signal)

/obj/machinery/atmospherics/components/unary/outlet_injector/atmosinit()
	set_frequency(frequency)
	broadcast_status()
	..()

/obj/machinery/atmospherics/components/unary/outlet_injector/receive_signal(datum/signal/signal)

	if(!signal.data["tag"] || (signal.data["tag"] != id) || (signal.data["sigtype"]!="command"))
		return

	if("power" in signal.data)
		on = text2num(signal.data["power"])

	if("power_toggle" in signal.data)
		on = !on

	if("inject" in signal.data)
		INVOKE_ASYNC(src, PROC_REF(inject))
		return

	if("set_volume_rate" in signal.data)
		var/number = text2num(signal.data["set_volume_rate"])
		var/datum/gas_mixture/air_contents = airs[1]
		volume_rate = clamp(number, 0, air_contents.return_volume())

	addtimer(CALLBACK(src, PROC_REF(broadcast_status)), 2)

	if(!("status" in signal.data)) //do not update_icon
		update_appearance()


/obj/machinery/atmospherics/components/unary/outlet_injector/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosPump", name)
		ui.open()

/obj/machinery/atmospherics/components/unary/outlet_injector/ui_data()
	var/data = list()
	data["on"] = on
	data["rate"] = round(volume_rate)
	data["max_rate"] = round(MAX_TRANSFER_RATE)
	return data

/obj/machinery/atmospherics/components/unary/outlet_injector/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("power")
			on = !on
			investigate_log("was turned [on ? "on" : "off"] by [key_name(usr)]", INVESTIGATE_ATMOS)
			. = TRUE
		if("rate")
			var/rate = params["rate"]
			if(rate == "max")
				rate = MAX_TRANSFER_RATE
				. = TRUE
			else if(text2num(rate) != null)
				rate = text2num(rate)
				. = TRUE
			if(.)
				volume_rate = clamp(rate, 0, MAX_TRANSFER_RATE)
				investigate_log("was set to [volume_rate] L/s by [key_name(usr)]", INVESTIGATE_ATMOS)
	update_appearance()
	broadcast_status()

/obj/machinery/atmospherics/components/unary/outlet_injector/can_unwrench(mob/user)
	. = ..()
	if(. && on && is_operational)
		to_chat(user, span_warning("You cannot unwrench [src], turn it off first!"))
		return FALSE

// mapping

/obj/machinery/atmospherics/components/unary/outlet_injector/layer2
	piping_layer = 2
	icon_state = "inje_map-2"

/obj/machinery/atmospherics/components/unary/outlet_injector/layer4
	piping_layer = 4
	icon_state = "inje_map-4"

/obj/machinery/atmospherics/components/unary/outlet_injector/on
	on = TRUE

/obj/machinery/atmospherics/components/unary/outlet_injector/on/layer2
	piping_layer = 2
	icon_state = "inje_map-2"

/obj/machinery/atmospherics/components/unary/outlet_injector/on/layer4
	piping_layer = 4
	icon_state = "inje_map-4"

/obj/machinery/atmospherics/components/unary/outlet_injector/atmos
	frequency = FREQ_ATMOS_STORAGE
	on = TRUE
	volume_rate = 400

/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/atmos_waste
	name = "atmos waste outlet injector"
	id =  ATMOS_GAS_MONITOR_WASTE_ATMOS
/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/engine_waste
	name = "engine outlet injector"
	id = ATMOS_GAS_MONITOR_WASTE_ENGINE
/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/toxin_input
	name = "plasma tank input injector"
	id = ATMOS_GAS_MONITOR_INPUT_TOX
/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/oxygen_input
	name = "oxygen tank input injector"
	id = ATMOS_GAS_MONITOR_INPUT_O2
/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/nitrogen_input
	name = "nitrogen tank input injector"
	id = ATMOS_GAS_MONITOR_INPUT_N2
/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/mix_input
	name = "mix tank input injector"
	id = ATMOS_GAS_MONITOR_INPUT_MIX
/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/nitrous_input
	name = "nitrous oxide tank input injector"
	id = ATMOS_GAS_MONITOR_INPUT_N2O
/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/air_input
	name = "air mix tank input injector"
	id = ATMOS_GAS_MONITOR_INPUT_AIR
/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/carbon_input
	name = "carbon dioxide tank input injector"
	id = ATMOS_GAS_MONITOR_INPUT_CO2
/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/incinerator_input
	name = "incinerator chamber input injector"
	id = ATMOS_GAS_MONITOR_INPUT_INCINERATOR
/obj/machinery/atmospherics/components/unary/outlet_injector/atmos/toxins_mixing_input
	name = "toxins mixing input injector"
	id = ATMOS_GAS_MONITOR_INPUT_TOXINS_LAB
