module main
import toml
import strings
import time
import math
import os

type FlatKvp = map[string]toml.Any


const langs = [ "id", "en", "jp", "ww" ]

struct GendescApp
{
pub mut:
	is_debug bool
	strmap FlatKvp
	exe_dir string
	verbose bool
}

fn get_value(this string, mut out_f &string) bool
{
	index := this.index('=') or { -1 }
	if index < 0 || index > this.len { 
		return false
	}
	out_f = this.substr(index + 1, this.len)
	return true
}

fn (mut this GendescApp) register_key(core_map toml.Any, key string)
{
	match core_map 
	{
		map[string]toml.Any { 
			for c_key in core_map.keys()
			{
				value := core_map[c_key] or { continue }
				n_key := if key.len == 0 { "${c_key}" } else { "${key}.${c_key}" }
				this.register_key(value, n_key)
			}
		}
		[]toml.Any
		{
			for i, item in core_map
			{
				n_key := if key.len == 0 { "[${i}]" } else { "${key}[${i}]" }
				this.register_key(item, n_key)
			}
			l_key := if key.len == 0 { "len" } else { "${key}.len" }
			this.strmap[l_key] = core_map.len
		}
		toml.Null
		{ 
			// do nothing
		}
		else { 
			this.strmap[key] = core_map
		}
	}
}

fn convert_to_widechar(str string) string
{
	lookup := {
		`0`: "０"
		`1`: "１", `2`: "２", `3`: "３"
		`4`: "４", `5`: "５", `6`: "６"
		`7`: "７", `8`: "８", `9`: "９"
	}

	mut sb := strings.new_builder(1)
	for chr in str.runes()
	{
		append := lookup[chr] or { "" }
		sb.write_string(append)
	}
	return sb.str()
}

fn (mut this GendescApp) add_time()
{
	now := time.now()
	day_str := "${now.day}"
	mon_str := "${now.month}"
	yer_str := "${now.year}"
	this.strmap["now.day.half"]   = day_str
	this.strmap["now.month.half"] = mon_str
	this.strmap["now.year.half"]  = yer_str
	this.strmap["now.day.wide"]   = convert_to_widechar(day_str)
	this.strmap["now.month.wide"] = convert_to_widechar(mon_str)
	this.strmap["now.year.wide"]  = convert_to_widechar(yer_str)
}

fn (mut this GendescApp) process_name_by_lang( fore string,lang string, reverse bool, joiner string)
{
	a_count_k := this.strmap["${fore}.${lang}.len"] or { return }
	a_count := a_count_k.int()

	mut name_k := []string{}

	for i in 0 .. a_count
	{
		v_k := this.strmap["${fore}.${lang}[${i}]"] or { continue }
		v := v_k.string()
		name_k << v
	}

	this.strmap["${fore}.${lang}.fore"] = name_k.first()
	this.strmap["${fore}.${lang}.back"] = name_k.last()

	if reverse 
	{
		name_k.reverse_in_place()
	}

	f_name := name_k.join(joiner)
	this.strmap["${fore}.${lang}"] = f_name
	this.strmap["${fore}.${lang}.lower"] = f_name.to_lower()
}

fn (mut this GendescApp) process_char_name()
{
	for lang in langs 
	{
		if lang == "jp" { continue } // Special case
		this.process_name_by_lang("char.name", lang, false, " ")
	}
	this.process_name_by_lang("char.name", "jp", true, "")
}

fn (mut this GendescApp) process_va_name()
{
	for lang in langs 
	{
		if lang == "jp" { continue } // Special case
		this.process_name_by_lang("char.va", lang, false, " ")
	}
	this.process_name_by_lang("char.va", "jp", true, "")
}

fn (mut this GendescApp) process_chapter_by_lang(lang string)
{
	ln_count_k := this.strmap["chapters.${lang}.len"] or { return }
	tm_count_k := this.strmap["chapters.times.len"] or { return }
	
	lcount := ln_count_k.int()
	tcount := tm_count_k.int()
	count := math.min(lcount, tcount)

	mut sb := strings.new_builder(1)
	for i in 0 .. count
	{
		ts_k := this.strmap["chapters.times[${i}]"] or { continue }
		nm_k := this.strmap["chapters.${lang}[${i}]"] or { continue }
		ts := ts_k.string()
		nm := nm_k.string()

		sb.writeln("${ts} ${nm}")
	}
	this.strmap["chapters.${lang}"] = sb.str()
}

fn (mut this GendescApp) process_chapters()
{
	for lang in langs
	{
		this.process_chapter_by_lang(lang)
	}
}

fn (mut this GendescApp) process_tags_by_lang(lang string)
{
	len_k := this.strmap["tags.${lang}.len"] or { return }
	len := len_k.int()

	mut sb := strings.new_builder(1)
	for i in 0 .. len 
	{
		str_k := this.strmap["tags.${lang}[${i}]"] or { continue }
		mut str := str_k.string()
		str = this.check_and_reevaluate(str, 0)

		if i == len - 1
		{
			sb.write_string(str)
		} 
		else
		{
			sb.write_string("${str}, ")
		}
	}
	this.strmap["tags.${lang}"] = sb.str().trim_space()
}

fn (mut this GendescApp) process_hashtags_by_lang(lang string)
{
	len_k := this.strmap["tags.${lang}.len"] or { return }
	len := len_k.int()

	mut sb := strings.new_builder(1)
	for i in 0 .. len 
	{
		str_k := this.strmap["tags.${lang}[${i}]"] or { continue }
		mut str := str_k.string()
		str = this.check_and_reevaluate(str, 0)
		str = str.replace(" ", "")
		
		hashtag := "#${str}"
		sb.write_string(hashtag)
		this.strmap["tags.hash.${lang}[${i}]"] = hashtag
		if i < len - 1
		{
			sb.write_rune(` `)
		} 
	}
	this.strmap["tags.hash.${lang}"] = sb.str().trim_space()
}

fn (mut this GendescApp) process_shorts_hashtags_by_lang(lang string)
{
	len_k := this.strmap["tags.shorts_hash_indices.len"] or { return }
	len := len_k.int()

	// put indices
	mut indices := []int {}
	for i in 0 .. len 
	{
		index_k := this.strmap["tags.shorts_hash_indices[${i}]"] or { continue }
		index := index_k.int()
		indices << index
	}

	mut sb := strings.new_builder(1)
	for i in indices
	{
		hash_k := this.strmap["tags.hash.${lang}[${i}]"] or { continue }
		hash := hash_k.string()
		sb.write_string("${hash} ")
	}

	this.strmap["tags.shorts_hash.${lang}"] = sb.str().trim_space()
}

fn (mut this GendescApp) process_hashtags()
{
	for lang in langs
	{
		this.process_tags_by_lang(lang)
		this.process_hashtags_by_lang(lang)
		this.process_shorts_hashtags_by_lang(lang)
	}
}

fn (mut this GendescApp) process_honorifics()
{
	enable_k := this.strmap["char.honor.use"] or { return }
	enable := enable_k.bool()
	

	// Empty honorifics
	if !enable
	{
		for lang in langs
		{
			_ := this.strmap["char.honor.${lang}"] or { continue }
			this.strmap["char.honor.${lang}"] = ""	
		}
	}
}

fn (mut this GendescApp) process_additionals()
{
	this.add_time()
	this.process_char_name()
	this.process_va_name()
	this.process_honorifics()
	this.process_chapters()
	this.process_hashtags()
}

fn is_an_escape(str string, i int) bool
{
	if i - 1 < 0 { return false }
	return str[i - 1] != `\\`
}

fn get_keys(str string) []string
{
	mut retval := []string{}
	mut is_in_key := false
	mut key_idx := -1
	for i, chr in str
	{
		if chr == `{` && !is_in_key 
		{
			is_in_key = true
			key_idx = i
		} else if chr == `}` && is_in_key
		{
			is_in_key = false
			retval << str.substr(key_idx + 1, i)
		}
	}
	if is_in_key
	{
		retval << str.substr(key_idx + 1, str.len)
	}
	return retval
}

fn (this GendescApp) check_and_reevaluate(str string, loop int) string
{
	if loop > 128 { panic("String \"${str}\" went bigger than 128 callstack deep and may cause stack overflow") } 
	keys := get_keys(str)
	mut n_str := str
	for key in keys
	{
		r_str := this.evaluate(key, loop + 1)
		n_str = n_str.replace("{${key}}", r_str)
	}
	return n_str
}

fn (this GendescApp) evaluate(key string, loop int) string
{
	if loop > 128 { panic("Key ${key} went bigger than 128 callstack deep and may cause stack overflow") } 
	str_k := this.strmap[key] or { return "" }
	return this.check_and_reevaluate(str_k.string(), loop)
}

fn (mut this GendescApp) process()
{
	desc_file_path := os.join_path(os.getwd(), "desc.toml")
	if !os.exists(desc_file_path)
	{
		panic("ERR: desc.toml does not exists in current directory! which is at \"${desc_file_path}\"")
		return
	}

	desc_file := toml.parse_file(desc_file_path) or { panic("Cannot open or parse desc.toml (\"${desc_file_path}\") - ${err}") } 
	desc_keys := desc_file.to_any()

	this.register_key(desc_keys, "")
	template := this.evaluate("template", 0);

	tmpl_file_path := os.join_path(this.exe_dir, "templates", "${template}.toml")
	if !os.exists(tmpl_file_path)
	{
		panic("ERR: template file ${template} does not exists in template directory in ${tmpl_file_path}")
	}

	tmpl_file := toml.parse_file(tmpl_file_path) or { panic("Cannot open or parse template file (\"${tmpl_file_path}\") - ${err}") } 

	tmpl_keys := tmpl_file.to_any()

	this.register_key(tmpl_keys, "")
	this.process_additionals()

	mut unr_keys := []string{}

	if this.verbose {
		println("INF: Values")
		for k, v in this.strmap
		{
			if v is string
			{
				kn_keys := get_keys(v)
				println("- ${k} -> ${v.replace("\n", "\\n")}")

				for key in kn_keys
				{
					if !unr_keys.contains(key) && !this.strmap.keys().contains(key)
					{
						unr_keys << key
					}
				}
			}
			else
			{
				println("- ${k} -> ${v}")
			}
		}
	}

	unr_keys.sort_ignore_case()

	if this.verbose
	{
		println("INF: Unresolved Replacement Keys (${unr_keys.len} in total)")
		for i, dkeys in unr_keys
		{
			println("- [${i}] ${dkeys}")
		}
	}

}

fn (this GendescApp) present(section string, copy bool)
{
	has_sect := this.strmap.keys().contains(section)
	if !has_sect
	{
		panic("Cannot find request section ${section}!")
	}

	retval := this.evaluate(section, 0)
	separator := "================================"
	println(separator)
	println(retval)
	println(separator)

	if copy 
	{
		os.execute("wl-copy -o \"${retval}\"")
	}
}