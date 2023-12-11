module template

import strings { Builder, new_builder }
import prantlf.debug { new_debug }
import prantlf.strutil { index_u8_within_nochk, skip_space_within_nochk, skip_trailing_space_within_nochk }

const d = new_debug('template')

type ReplacePart = Literal | Variable

type ReplaceAppender = fn (mut builder Builder, vars TemplateData)

@[noinit]
pub struct Replacer {
	source_len int
	appenders  []ReplaceAppender
}

pub struct ReplacerOpts {
	vars    []string
	exclude bool
}

pub fn (t &Replacer) replace(vars TemplateData) string {
	template.d.log('replace with %d appenders reserving %d characters', t.appenders.len,
		t.source_len)
	template.d.stop_ticking()

	mut builder := new_builder(t.source_len)
	for appender in t.appenders {
		appender(mut builder, vars)
	}

	res := builder.str()
	template.d.start_ticking()
	short_res := template.d.shorten(res)
	template.d.log('replaced "%s" (length %d)', short_res, res.len)
	return res
}

pub fn parse_replacer(source string) !&Replacer {
	return parse_replacer_opt(source, &ReplacerOpts{})!
}

pub fn parse_replacer_opt(source string, opts &ReplacerOpts) !&Replacer {
	parts := scan_replacer(source, opts)!

	mut appenders := []ReplaceAppender{cap: parts.len}
	parse_replace_block(source, parts, mut appenders)

	return &Replacer{
		source_len: source.len
		appenders: appenders
	}
}

fn scan_replacer(source string, opts &ReplacerOpts) ![]ReplacePart {
	if template.d.is_enabled() {
		short_s := template.d.shorten(source)
		opts_s := if opts.vars.len > 0 {
			verb := if opts.exclude {
				'exclude'
			} else {
				'include'
			}
			' ${verb} "${opts.vars.join('"", "')}"'
		} else {
			''
		}
		template.d.log_str('scan replacer "${short_s}" (length ${source.len}${opts_s})}')
		template.d.stop_ticking()
		defer {
			template.d.start_ticking()
		}
	}

	mut parts := []ReplacePart{cap: 8}
	stop := source.len
	mut open := -1
	mut close := 0
	for {
		open = unsafe { index_u8_within_nochk(source, `{`, open + 1, stop) }
		if open < 0 {
			try_add_literal(mut parts, source, close, stop)
			break
		}

		if open == 0 || source[open - 1] != `\\` {
			end := unsafe { index_u8_within_nochk(source, `}`, open + 1, stop) }
			if end < 0 {
				return ParseError{
					msg: 'missing } for {'
					at: open
				}
			}

			name_start := unsafe { skip_space_within_nochk(source, open + 1, end) }
			name_end := unsafe {
				skip_trailing_space_within_nochk(source, name_start, end)
			}
			name := source[name_start..name_end]
			if opts.vars.len > 0 && ((opts.exclude && name in opts.vars)
				|| (!opts.exclude && name !in opts.vars)) {
				template.d.log('variable "%s" at %d will be handled as a literal', name,
					open)
				open = end
			} else {
				try_add_literal(mut parts, source, close, open)

				template.d.log('create variable "%s" at %d', name, open)
				open = end
				close = end + 1

				parts << Variable{
					name: name
				}
			}
		} else {
			try_add_literal(mut parts, source, close, open - 1)
			close = open
		}
	}

	template.d.log('template scanned to %d parts', parts.len)
	return parts
}

fn parse_replace_block(source string, parts []ReplacePart, mut appenders []ReplaceAppender) {
	template.d.log('parse %d scanned parts', parts.len)
	template.d.stop_ticking()
	for i := 0; i < parts.len; i++ {
		part := parts[i]
		match part {
			Literal {
				t := source
				s := part.start
				l := part.len
				short_t := template.d.shorten_within(t, s, s + l)
				template.d.log('append literal "%s" from %d, length %d (part %d)', short_t,
					s, l, i)
				appenders << fn [short_t, t, s, l] (mut builder Builder, vars TemplateData) {
					template.d.log('process literal "%s" from %d, length %d', short_t,
						s, l)
					unsafe { builder.write_ptr(t.str + s, l) }
				}
			}
			Variable {
				name := part.name
				template.d.log('append variable "%s" (part %d)', name, i)
				appenders << fn [name] (mut builder Builder, vars TemplateData) {
					val := vars.get_one(name)
					if val.len > 0 {
						short_val := template.d.shorten(val)
						template.d.log('process variable "%s" with "%s"', name, short_val)
						builder.write_string(val)
					} else {
						template.d.log('ignore variable "%s"', name)
					}
				}
			}
		}
	}
	template.d.start_ticking()
	template.d.log('parts parsed to %d appenders', appenders.len)
}
