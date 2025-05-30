/datum/buildmode_mode/boom
	key = "boom"

	var/devastation = -1
	var/heavy = -1
	var/light = -1
	var/flash = -1
	var/flames = -1

/datum/buildmode_mode/boom/show_help(client/target_client)
	to_chat(target_client, span_purple(boxed_message(
		"[span_bold("Set explosion destructiveness")] -> Right Mouse Button on buildmode button\n\
		[span_bold("Kaboom")] -> Mouse Button on obj\n\n\
		[span_warning("NOTE:")] Using the \"Config/Launch Supplypod\" verb allows you to do this in an IC way (i.e., making a cruise missile come down from the sky and explode wherever you click!)"))
	)

/datum/buildmode_mode/boom/change_settings(client/target_client)
	devastation = input(target_client, "Range of total devastation. -1 to none", text("Input")) as num|null
	if(devastation == null)
		devastation = -1
	heavy = input(target_client, "Range of heavy impact. -1 to none", text("Input")) as num|null
	if(heavy == null)
		heavy = -1
	light = input(target_client, "Range of light impact. -1 to none", text("Input")) as num|null
	if(light == null)
		light = -1
	flash = input(target_client, "Range of flash. -1 to none", text("Input")) as num|null
	if(flash == null)
		flash = -1
	flames = input(target_client, "Range of flames. -1 to none", text("Input")) as num|null
	if(flames == null)
		flames = -1

/datum/buildmode_mode/boom/handle_click(client/target_client, params, obj/object)
	var/list/modifiers = params2list(params)

	if(LAZYACCESS(modifiers, LEFT_CLICK))
		explosion(object, devastation, heavy, light, flash, FALSE, TRUE, flames)
		log_admin("Build Mode: [key_name(target_client)] caused an explosion(dev=[devastation], hvy=[heavy], lgt=[light], flash=[flash], flames=[flames]) at [AREACOORD(object)]")
