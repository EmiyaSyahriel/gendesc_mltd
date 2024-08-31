module main
import strings

fn get_value(this string, mut out_f &string) bool
{
	index := this.index('=') or { -1 }
	if index < 0 || index > this.len { 
		return false
	}
	out_f = this.substr(index + 1, this.len)
	return true
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
