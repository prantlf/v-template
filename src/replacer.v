module template

import strings { Builder, new_builder }
import prantlf.debug { new_debug }

type ReplacePart = Literal | Variable

type ReplaceAppender = fn (mut builder Builder, vars TemplateData)

[noinit]
pub struct Replacer {
	source_len int
	appenders    []ReplaceAppender
}

pub struct ReplacerOpts {
	vars    []string
	exclude bool
}

pub fn (t &Replacer) replace(vars TemplateData) string {
	mut builder := new_builder(t.source_len)
	for appender in t.appenders {
		appender(mut builder, vars)
	}
	return builder.str()
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
	mut parts := []ReplacePart{cap: 8}
	stop := source.len
	mut open := -1
	mut close := 0
	for {
		open = index_u8_within(source, `{`, open + 1, stop)
		if open < 0 {
			try_add_literal(mut parts, close, stop)
			break
		}

		if open == 0 || source[open - 1] != `\\` {
			end := index_u8_within(source, `}`, open + 1, stop)
			if end < 0 {
				return error('missing } for { at ${open}')
			}

			name_start := skip_space(source, open + 1, end)
			name_end := skip_trailing_space(source, name_start, end)
			name := source[name_start..name_end]
			if opts.vars.len > 0 && ((opts.exclude && name in opts.vars)
				|| (!opts.exclude && name !in opts.vars)) {
				open = end
			} else {
				try_add_literal(mut parts, close, open)

				open = end
				close = end + 1

				parts << Variable{
					name: name
				}
			}
		} else {
			try_add_literal(mut parts, close, open - 1)
			close = open
		}
	}

	return parts
}

fn parse_replace_block(source string, parts []ReplacePart, mut appenders []ReplaceAppender) {
	for i := 0; i < parts.len; i++ {
		part := parts[i]
		match part {
			Literal {
				t := source
				s := part.start
				l := part.len
				appenders << fn [t, s, l] (mut builder Builder, vars TemplateData) {
					if l > 0 {
						unsafe { builder.write_ptr(t.str + s, l) }
					}
				}
			}
			Variable {
				name := part.name
				appenders << fn [name] (mut builder Builder, vars TemplateData) {
					val := vars.get_one(name)
					if val.len > 0 {
						builder.write_string(val)
					}
				}
			}
		}
	}
}
