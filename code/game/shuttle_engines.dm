#define ENGINE_UNWRENCHED 0
#define ENGINE_WRENCHED 1
#define ENGINE_WELDED 2
#define ENGINE_WELDTIME 200

/obj/structure/shuttle
	name = "shuttle"
	icon = 'icons/turf/shuttle.dmi'
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	max_integrity = 500
	armor = list("melee" = 100, "bullet" = 10, "laser" = 10, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 70) //default + ignores melee

/obj/structure/shuttle/engine
	name = "engine"
	desc = "A bluespace engine used to make shuttles move."
	density = TRUE
	anchored = TRUE
	var/state = ENGINE_WELDED //welding shmelding

//Ugh this is a lot of copypasta from emitters, welding need some boilerplate reduction
/obj/structure/shuttle/engine/can_be_unfasten_wrench(mob/user, silent)
	if(state == ENGINE_WELDED)
		if(!silent)
			to_chat(user, span_warning("[src] is welded to the floor!"))
		return FAILED_UNFASTEN
	return ..()

/obj/structure/shuttle/engine/default_unfasten_wrench(mob/user, obj/item/I, time = 20)
	. = ..()
	if(. == SUCCESSFUL_UNFASTEN)
		if(anchored)
			state = ENGINE_WRENCHED
		else
			state = ENGINE_UNWRENCHED

/obj/structure/shuttle/engine/wrench_act(mob/living/user, obj/item/I)
	..()
	default_unfasten_wrench(user, I)
	return TRUE

/obj/structure/shuttle/engine/welder_act(mob/living/user, obj/item/I)
	. = ..()
	switch(state)
		if(ENGINE_UNWRENCHED)
			to_chat(user, span_warning("The [src.name] needs to be wrenched to the floor!"))
		if(ENGINE_WRENCHED)
			if(!I.tool_start_check(user, src, amount=0))
				return TRUE

			user.visible_message(span_notice("[user.name] starts to weld the [name] to the floor."), \
				span_notice("You start to weld \the [src] to the floor..."), \
				span_hear("You hear welding."))

			if(I.use_tool(src, user, ENGINE_WELDTIME, volume=50))
				state = ENGINE_WELDED
				to_chat(user, span_notice("You weld \the [src] to the floor."))

		if(ENGINE_WELDED)
			if(!I.tool_start_check(user, src, amount=0))
				return TRUE

			user.visible_message(span_notice("[user.name] starts to cut the [name] free from the floor."), \
				span_notice("You start to cut \the [src] free from the floor..."), \
				span_hear("You hear welding."))

			if(I.use_tool(src, user, ENGINE_WELDTIME, volume=50))
				state = ENGINE_WRENCHED
				to_chat(user, span_notice("You cut \the [src] free from the floor."))
	return TRUE

/obj/structure/shuttle/engine/heater
	name = "engine heater"
	icon_state = "heater"
	desc = "Directs energy into compressed particles in order to power engines."

/obj/structure/shuttle/platform
	name = "engine platform"
	icon_state = "platform"
	desc = "A platform for engine components."
	density = TRUE
	anchored = TRUE
	pass_flags_self = PASSPLATFORM

/obj/structure/shuttle/platform/corner
	icon_state = "platform_corner"

/obj/structure/shuttle/engine/propulsion
	name = "propulsion engine"
	icon_state = "propulsion"
	desc = "A standard reliable bluespace engine used by many forms of shuttles."
	opacity = TRUE

/obj/structure/shuttle/engine/propulsion/left
	name = "left propulsion engine"
	icon_state = "propulsion_l"

/obj/structure/shuttle/engine/propulsion/right
	name = "right propulsion engine"
	icon_state = "propulsion_r"

/obj/structure/shuttle/engine/propulsion/burst
	name = "burst engine"
	desc = "An engine that releases a large bluespace burst to propel it."

/obj/structure/shuttle/engine/propulsion/burst/cargo
	state = ENGINE_UNWRENCHED
	anchored = FALSE

/obj/structure/shuttle/engine/propulsion/burst/left
	name = "left burst engine"
	icon_state = "burst_l"

/obj/structure/shuttle/engine/propulsion/burst/right
	name = "right burst engine"
	icon_state = "burst_r"

/obj/structure/shuttle/engine/router
	name = "engine router"
	icon_state = "router"
	desc = "Redirects around energized particles in engine structures."

/obj/structure/shuttle/engine/large
	name = "engine"
	opacity = TRUE
	icon = 'icons/obj/2x2.dmi'
	icon_state = "large_engine"
	desc = "A very large bluespace engine used to propel very large ships."
	bound_width = 64
	bound_height = 64
	appearance_flags = 0

/obj/structure/shuttle/engine/huge
	name = "engine"
	opacity = TRUE
	icon = 'icons/obj/3x3.dmi'
	icon_state = "huge_engine"
	desc = "An extremely large bluespace engine used to propel extremely large ships."
	bound_width = 96
	bound_height = 96
	appearance_flags = 0

#undef ENGINE_UNWRENCHED
#undef ENGINE_WRENCHED
#undef ENGINE_WELDED
#undef ENGINE_WELDTIME
