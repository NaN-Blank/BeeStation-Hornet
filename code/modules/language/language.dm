#define SCRAMBLE_CACHE_LEN 50 //maximum of 50 specific scrambled lines per language

/*
	Datum based languages. Easily editable and modular.
*/

/datum/language
	var/name = "an unknown language"  // Fluff name of language if any.
	var/desc = "A language."          // Short description for 'Check Languages'.
	var/speech_verb = "says"          // 'says', 'hisses', 'farts'.
	var/ask_verb = "asks"             // Used when sentence ends in a ?
	var/exclaim_verb = "exclaims"     // Used when sentence ends in a !
	var/whisper_verb = "whispers"     // Optional. When not specified speech_verb + quietly/softly is used instead.
	var/sing_verb = "sings"			  // Used for singing.
	var/list/signlang_verb = list("signs", "gestures") // list of emotes that might be displayed if this language has NONVERBAL or SIGNLANG flags
	var/key                           // Character used to speak in language
	// If key is null, then the language isn't real or learnable.
	var/flags                         // Various language flags.
	var/list/syllables                // Used when scrambling text for a non-speaker.
	var/sentence_chance = 5      // Likelihood of making a new sentence after each syllable.
	var/space_chance = 55        // Likelihood of getting a space in the random scramble string
	var/list/spans = list()
	var/list/scramble_cache = list()
	var/default_priority = 0          // the language that an atom knows with the highest "default_priority" is selected by default. if -1, it will not be chosen as dafault by auto-update.

	// if you are seeing someone speak popcorn language, then something is wrong.
	var/icon = 'icons/misc/language.dmi'
	var/icon_state = "popcorn"

	// get_icon() proc will return a complete string rather than calling a proc every time.
	var/fast_icon_span

/// Returns TRUE/FALSE based on seeing a language icon is validated to a given hearer in the parameter.
/datum/language/proc/display_icon(atom/movable/hearer)
	// ghosts want to know how it is going.
	if((flags & LANGUAGE_ALWAYS_SHOW_ICON_TO_GHOSTS) && \
			(isobserver(hearer) || (HAS_TRAIT(hearer, TRAIT_METALANGUAGE_KEY_ALLOWED) && istype(src, /datum/language/metalanguage))))
		return TRUE

	var/understands = hearer.has_language(src.type)
	if(understands)
		// It's something common so that you don't have to see a language icon
		// or, it's not a valid language that should show a language icon
		if((flags & LANGUAGE_HIDE_ICON_IF_UNDERSTOOD) || (flags & LANGUAGE_HIDE_ICON_TO_YOURSELF))
			return FALSE

	else
		// Standard to Galatic Common
		if(flags & LANGUAGE_ALWAYS_SHOW_ICON_IF_NOT_UNDERSTOOD)
			return TRUE

		// You'll typically end here - not being able to see a language icon
		if(!HAS_TRAIT(hearer, TRAIT_LINGUIST))
			return FALSE
		else if(flags & LANGUAGE_HIDE_ICON_IF_NOT_UNDERSTOOD__LINGUIST_ONLY) // don't merge with the if above. it's different check.
			return FALSE

	// If you reach here, you'd be a linguist quirk holder, and will be eligible to see a lang icon
	return TRUE

/datum/language/proc/get_icon()
	if(!fast_icon_span)
		var/datum/asset/spritesheet_batched/sheet = get_asset_datum(/datum/asset/spritesheet_batched/chat)
		fast_icon_span = sheet.icon_tag("language-[icon_state]")
	return fast_icon_span

/datum/language/proc/get_random_name(gender, name_count=2, syllable_count=4, syllable_divisor=2)
	if(!syllables || !syllables.len)
		if(gender==FEMALE)
			return capitalize(pick(GLOB.first_names_female)) + " " + capitalize(pick(GLOB.last_names))
		else
			return capitalize(pick(GLOB.first_names_male)) + " " + capitalize(pick(GLOB.last_names))

	var/full_name = ""
	var/new_name = ""

	for(var/i in 0 to name_count)
		new_name = ""
		var/Y = rand(FLOOR(syllable_count/syllable_divisor, 1), syllable_count)
		for(var/x in Y to 0)
			new_name += pick(syllables)
		full_name += " [capitalize(LOWER_TEXT(new_name))]"

	return "[trim(full_name)]"

/datum/language/proc/check_cache(input)
	var/lookup = scramble_cache[input]
	if(lookup)
		scramble_cache -= input
		scramble_cache[input] = lookup
	. = lookup

/datum/language/proc/add_to_cache(input, scrambled_text)
	// Add it to cache, cutting old entries if the list is too long
	scramble_cache[input] = scrambled_text
	if(scramble_cache.len > SCRAMBLE_CACHE_LEN)
		scramble_cache.Cut(1, scramble_cache.len-SCRAMBLE_CACHE_LEN-1)

/datum/language/proc/scramble(input)

	if(!syllables || !syllables.len)
		return stars(input)

	// If the input is cached already, move it to the end of the cache and return it
	var/lookup = check_cache(input)
	if(lookup)
		return lookup

	var/input_size = length_char(input)
	var/scrambled_text = ""
	var/capitalize = TRUE

	while(length_char(scrambled_text) < input_size)
		var/next = pick(syllables)
		if(capitalize)
			next = capitalize(next)
			capitalize = FALSE
		scrambled_text += next
		var/chance = rand(100)
		if(chance <= sentence_chance)
			scrambled_text += ". "
			capitalize = TRUE
		else if(chance > sentence_chance && chance <= space_chance)
			scrambled_text += " "

	scrambled_text = trim(scrambled_text)
	var/ending = copytext_char(scrambled_text, -1)
	if(ending == ".")
		scrambled_text = copytext_char(scrambled_text, 1, -2)
	var/input_ending = copytext_char(input, -1)
	if(input_ending in list("!","?","."))
		scrambled_text += input_ending

	add_to_cache(input, scrambled_text)

	return scrambled_text

/datum/language/proc/get_spoken_verb(msg_end)
	switch(msg_end)
		if("!")
			return exclaim_verb
		if("?")
			return ask_verb
	return speech_verb

#undef SCRAMBLE_CACHE_LEN
