//Speech verbs.

///Say verb
/mob/verb/say_verb(message as text)
	set name = "Say"
	set category = "IC"
	set instant = TRUE
	if(typing_indicator)
		set_typing_indicator(FALSE)
	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return
	//queue this message because verbs are scheduled to process after SendMaps in the tick and speech is pretty expensive when it happens.
	//by queuing this for next tick the mc can compensate for its cost instead of having speech delay the start of the next tick
	if(message)
		QUEUE_OR_CALL_VERB_FOR(VERB_CALLBACK(src, TYPE_PROC_REF(/atom/movable, say), message), SSspeech_controller)

///Whisper verb
/mob/verb/whisper_verb(message as text)
	set name = "Whisper"
	set category = "IC"
	set instant = TRUE
	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return
	if(message)
		QUEUE_OR_CALL_VERB_FOR(VERB_CALLBACK(src, TYPE_PROC_REF(/mob, whisper), message), SSspeech_controller)

///whisper a message
/mob/proc/whisper(message, datum/language/language=null)
	say(message, language = language) //only living mobs actually whisper, everything else just talks

///The me emote verb
/mob/verb/me_verb(message as text)
	set name = "Me"
	set category = "IC"

	if(typing_indicator)
		set_typing_indicator(FALSE)
	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return

	message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))

	QUEUE_OR_CALL_VERB_FOR(VERB_CALLBACK(src, TYPE_PROC_REF(/mob, emote), "me", 1, message, TRUE), SSspeech_controller)

///Speak as a dead person (ghost etc)
/mob/proc/say_dead(message)
	var/name = real_name
	var/alt_name = ""

	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return

	var/jb = is_banned_from(ckey, "Deadchat")
	if(QDELETED(src))
		return

	if(jb)
		to_chat(src, span_danger("You have been banned from deadchat."))
		return



	if (src.client)
		if(src.client.prefs.muted & MUTE_DEADCHAT)
			to_chat(src, span_danger("You cannot talk in deadchat (muted)."))
			return

		if(SSlag_switch.measures[SLOWMODE_SAY] && !HAS_TRAIT(src, TRAIT_BYPASS_MEASURES) && src == usr)
			if(!COOLDOWN_FINISHED(client, say_slowmode))
				to_chat(src, span_warning("Message not sent due to slowmode. Please wait [SSlag_switch.slowmode_cooldown/10] seconds between messages.\n\"[message]\""))
				return
			COOLDOWN_START(client, say_slowmode, SSlag_switch.slowmode_cooldown)

		if(src.client.handle_spam_prevention(message,MUTE_DEADCHAT))
			return

	var/mob/dead/observer/O = src
	if(isobserver(src) && O.deadchat_name)
		name = "[O.deadchat_name]"
	else
		if(mind && mind.name)
			name = "[mind.name]"
		else
			name = real_name
		if(name != real_name)
			alt_name = " (died as [real_name])"

	var/spanned = say_quote(say_emphasis(message))
	var/source = "[span_game("<span class='prefix'>DEAD:")] [span_name("[(src.client.prefs.chat_toggles & CHAT_GHOSTCKEY) ? "([src.key]) " : ""][name]")][alt_name]"
	var/rendered = " [span_message("[emoji_parse(spanned)]")]</span>"
	log_talk(message, LOG_SAY, tag="DEAD")
	if(SEND_SIGNAL(src, COMSIG_MOB_DEADSAY, message) & MOB_DEADSAY_SIGNAL_INTERCEPT)
		return
	var/displayed_key = key
	if(client?.holder?.fakekey)
		displayed_key = null
	deadchat_broadcast(rendered, source, follow_target = src, speaker_key = displayed_key)

///Check if this message is an emote
/mob/proc/check_emote(message, forced)
	if(message[1] == "*")
		emote(copytext(message, length(message[1]) + 1), intentional = !forced)
		return TRUE

/mob/proc/check_for_custom_say_emote(message, list/mods)
	var/customsaypos = findtext(message, "*")
	if(!customsaypos)
		return message
	if (is_banned_from(ckey, "Emote"))
		return copytext(message, customsaypos + 1)
	mods[MODE_CUSTOM_SAY_EMOTE] = lowertext(copytext_char(message, 1, customsaypos))
	message = copytext(message, customsaypos + 1)
	if (!message)
		mods[MODE_CUSTOM_SAY_ERASE_INPUT] = TRUE
		message = "an interesting thing to say"
	return message
///Check if the mob has a hivemind channel
/mob/proc/hivecheck()
	return 0

///Check if the mob has a ling hivemind
/mob/proc/lingcheck()
	return LINGHIVE_NONE

///WS Begin - Check if the mob has a borer hivemind channel
/mob/proc/borercheck()
	return FALSE
//WS end

///The amount of items we are looking for in the message
#define MESSAGE_MODS_LENGTH 6
/**
 * Extracts and cleans message of any extenstions at the begining of the message
 * Inserts the info into the passed list, returns the cleaned message
 *
 * Result can be
 * * SAY_MODE (Things like aliens, channels that aren't channels)
 * * MODE_WHISPER (Quiet speech)
 * * MODE_SING (Singing)
 * * MODE_HEADSET (Common radio channel)
 * * RADIO_EXTENSION the extension we're using (lots of values here)
 * * RADIO_KEY the radio key we're using, to make some things easier later (lots of values here)
 * * LANGUAGE_EXTENSION the language we're trying to use (lots of values here)
 */
/mob/proc/get_message_mods(message, list/mods)
	for(var/I in 1 to MESSAGE_MODS_LENGTH)
		// Prevents "...text" from being read as a radio message
		if (length(message) > 1 && message[2] == message[1])
			continue

		var/key = message[1]
		var/chop_to = 2 //By default we just take off the first char
		if(key == "#" && !mods[WHISPER_MODE])
			mods[WHISPER_MODE] = MODE_WHISPER
		else if(key == "%" && !mods[MODE_SING])
			mods[MODE_SING] = TRUE
		else if(key == ";" && !mods[MODE_HEADSET])
			mods[MODE_HEADSET] = TRUE
		else if((key in GLOB.department_radio_prefixes) && length(message) > length(key) + 1 && !mods[RADIO_EXTENSION])
			mods[RADIO_KEY] = lowertext(message[1 + length(key)])
			mods[RADIO_EXTENSION] = GLOB.department_radio_keys[mods[RADIO_KEY]]
			chop_to = length(key) + 2
		else if(key == "," && !mods[LANGUAGE_EXTENSION])
			for(var/ld in GLOB.all_languages)
				var/datum/language/LD = ld
				if(initial(LD.key) == message[1 + length(message[1])])
					// No, you cannot speak in xenocommon just because you know the key
					if(!can_speak_language(LD))
						return message
					mods[LANGUAGE_EXTENSION] = LD
					chop_to = length(key) + length(initial(LD.key)) + 1
			if(!mods[LANGUAGE_EXTENSION])
				return message
		else
			return message
		message = trim_left(copytext_char(message, chop_to))
		if(!message)
			return
	return message
