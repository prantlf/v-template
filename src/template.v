module template

import strings { Builder, new_builder }
import prantlf.strutil { index_u8_within_nochk, skip_space_within_nochk, skip_trailing_space_within_nochk, starts_with_within_nochk }

struct Literal {
	start int
	len   int
}

struct Variable {
	name string
}

struct Items {
	name string
}

struct Lines {
	name string
}

struct If {
	name string
}

struct Unless {
	name string
}

struct For {
	name string
}

struct Index {
	depth int
}

struct Value {
	depth int
}

struct First {}

struct NotFirst {}

struct Middle {}

struct NotLast {}

struct Last {}

struct End {}

type TemplatePart = End
	| First
	| For
	| If
	| Index
	| Items
	| Last
	| Lines
	| Literal
	| Middle
	| NotFirst
	| NotLast
	| Unless
	| Value
	| Variable

type TemplateAppender = fn (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int)

@[noinit]
pub struct Template {
	source_len int
	appenders  []TemplateAppender
}

pub interface TemplateData {
	has(name string) bool
	get_one(name string) string
	get_more(name string) []string
}

pub fn (t &Template) generate(vars TemplateData) string {
	d.log('generate with %d appenders reserving %d characters', t.appenders.len, t.source_len)
	d.stop_ticking()

	mut builder := new_builder(t.source_len)
	for appender in t.appenders {
		appender(mut builder, vars, [], [], 0)
	}

	res := builder.str()
	d.start_ticking()
	short_res := d.shorten(res)
	d.log('generated "%s" (length %d)', short_res, res.len)
	return res
}

pub fn parse_template(source string) !&Template {
	parts, needs_depth := scan_template(source)!

	mut appenders := []TemplateAppender{cap: parts.len}
	d.log('parse %d scanned parts', parts.len)
	d.stop_ticking()
	parse_template_block(source, parts, 0, parts.len, mut appenders, needs_depth)
	d.start_ticking()
	d.log('parts parsed to %d appenders', appenders.len)

	return &Template{
		source_len: source.len
		appenders: appenders
	}
}

fn scan_template(source string) !([]TemplatePart, bool) {
	short_s := d.shorten(source)
	d.log('scan template "%s" (length %d)', short_s, source.len)
	d.stop_ticking()
	defer {
		d.start_ticking()
	}

	mut parts := []TemplatePart{cap: 8}
	mut needs_depth := false
	stop := source.len
	mut open := -1
	mut close := 0
	mut depth := 0
	for {
		open = unsafe { index_u8_within_nochk(source, `{`, open + 1, stop) }
		if open < 0 {
			try_add_literal(mut parts, source, close, stop)
			break
		}

		if open == 0 || source[open - 1] != `\\` {
			try_add_literal(mut parts, source, close, open)

			close = unsafe { index_u8_within_nochk(source, `}`, open + 1, stop) }
			if close < 0 {
				return ParseError{
					msg: 'missing } for {'
					at: open
				}
			}

			name_start := unsafe { skip_space_within_nochk(source, open + 1, close) }
			name_end := unsafe {
				skip_trailing_space_within_nochk(source, name_start, close)
			}
			mut name := source[name_start..name_end]

			start := open
			open = close
			close++

			space := name.index_u8(` `)
			if space > 0 {
				op := name[..space]
				if op[0] != `#` {
					return ParseError{
						msg: 'operator "${op}" not starting with #'
						at: start
					}
				}
				name_start2 := unsafe { skip_space_within_nochk(name, space + 1, name.len) }
				name = name[name_start2..]
				if name.len == 0 {
					return ParseError{
						msg: 'missing operand for ${op}'
						at: start
					}
				}

				match op {
					'#lines' {
						parts << Lines{
							name: name
						}
					}
					'#items' {
						parts << Items{
							name: name
						}
					}
					'#if' {
						parts << If{
							name: name
						}
						depth++
					}
					'#unless' {
						parts << Unless{
							name: name
						}
						depth++
					}
					'#for' {
						parts << For{
							name: name
						}
						depth++
					}
					else {
						return ParseError{
							msg: 'unrecognised operator ${op} at ${start}'
							at: start
						}
					}
				}
				d.log('create operation "%s" for "%s" at %d', op, name, start)
			} else {
				inner_name, name_depth := get_name_with_depth(name)
				if name_depth > 0 {
					needs_depth = true
					if inner_name != '#index' && inner_name != '#value' {
						kind := if inner_name[0] == `#` {
							'directive ${inner_name}'
						} else {
							'variable "${inner_name}"'
						}
						return ParseError{
							msg: '${kind} does not support outer scope ${name[0..name.len - inner_name.len - 1]} (depth ${name_depth})'
							at: start
						}
					}
				}
				match inner_name {
					'#end' {
						if depth == 0 {
							return ParseError{
								msg: 'extra #end'
								at: start
							}
						}
						depth--
						parts << End{}
					}
					'#first' {
						parts << First{}
						depth++
					}
					'#notfirst' {
						parts << NotFirst{}
						depth++
					}
					'#middle' {
						parts << Middle{}
						depth++
					}
					'#notlast' {
						parts << NotLast{}
						depth++
					}
					'#last' {
						parts << Last{}
						depth++
					}
					'#index' {
						parts << Index{
							depth: name_depth
						}
					}
					'#value' {
						parts << Value{
							depth: name_depth
						}
					}
					else {
						if name[0] == `#` {
							return ParseError{
								msg: 'unrecognised directive ${name} at ${start}'
								at: start
							}
						}
						parts << Variable{
							name: name
						}
					}
				}
				if d.is_enabled() {
					scope := if name_depth > 0 {
						' from scope ${name[0..name.len - inner_name.len - 1]} (depth ${name_depth})'
					} else {
						''
					}
					kind := if inner_name[0] == `#` {
						'directive ${inner_name}'
					} else {
						'variable "${inner_name}"'
					}
					d.log_str('create ${kind} at ${start}${scope}')
				}
			}
		} else {
			try_add_literal(mut parts, source, close, open - 1)
			close = open
		}
	}

	if depth > 0 {
		return ParseError{
			msg: 'missing trailing {#end}'
			at: source.len - 1
		}
	}

	d.start_ticking()
	if d.is_enabled() {
		not := if needs_depth {
			''
		} else {
			'not '
		}
		d.log_str('template scanned to ${parts.len} parts, ${not}supporting values from outer loops')
	}
	return parts, needs_depth
}

fn try_add_literal[T](mut parts []T, source string, start int, stop int) {
	len := stop - start
	if len > 0 {
		short_lit := d.shorten_within(source, start, stop)
		d.log('create literal "%s" at %d, length %d', short_lit, start, len)
		parts << Literal{
			start: start
			len: len
		}
	}
}

fn parse_template_block(source string, parts []TemplatePart, start int, stop int, mut appenders []TemplateAppender, needs_depth bool) {
	for i := start; i < stop; i++ {
		part := parts[i]
		match part {
			Literal {
				t := source
				s := part.start
				l := part.len
				short_t := d.shorten_within(t, s, s + l)
				d.log('append literal "%s", from %d, length %d (part %d)', short_t, s,
					l, i)
				appenders << fn [short_t, t, s, l] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					d.log('process literal with "%s"', short_t)
					unsafe { builder.write_ptr(t.str + s, l) }
				}
			}
			End {
				panic('unexpected end part reached')
			}
			First {
				d.log('append directive #first (part %d)', i)
				sub_appenders, end := parse_sub_block(source, parts, i + 1, stop, needs_depth)
				appenders << fn [sub_appenders] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					idx := idxs[0]
					if idx == 0 {
						d.log_str('process directive #first')
						for appender in sub_appenders {
							appender(mut builder, vars, vals, idxs, len)
						}
					} else {
						d.log('ignore directive #first for index %d', idx)
					}
				}
				i = end
			}
			NotFirst {
				d.log('append directive #notfirst (part %d)', i)
				sub_appenders, end := parse_sub_block(source, parts, i + 1, stop, needs_depth)
				appenders << fn [sub_appenders] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					idx := idxs[0]
					if idx > 0 {
						d.log('process directive #notfirst for index %d', idx)
						for appender in sub_appenders {
							appender(mut builder, vars, vals, idxs, len)
						}
					} else {
						d.log('ignore directive #notfirst for index %d', idx)
					}
				}
				i = end
			}
			Middle {
				d.log('append directive #middle (part %d)', i)
				sub_appenders, end := parse_sub_block(source, parts, i + 1, stop, needs_depth)
				appenders << fn [sub_appenders] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					idx := idxs[0]
					if idx > 0 && idx + 1 != len {
						d.log('process directive #middle for index %d and length %d',
							idx, len)
						for appender in sub_appenders {
							appender(mut builder, vars, vals, idxs, len)
						}
					} else {
						d.log('ignore directive #middle for index %d and length %d', idx,
							len)
					}
				}
				i = end
			}
			NotLast {
				d.log('append directive #notlast (part %d)', i)
				sub_appenders, end := parse_sub_block(source, parts, i + 1, stop, needs_depth)
				appenders << fn [sub_appenders] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					idx := idxs[0]
					if idx >= 0 && idx + 1 < len {
						d.log('process directive #notlast for index %d and length %d',
							idx, len)
						for appender in sub_appenders {
							appender(mut builder, vars, vals, idxs, len)
						}
					} else {
						d.log('ignore directive #notlast for index %d and length %d',
							idx, len)
					}
				}
				i = end
			}
			Last {
				d.log('append directive #last (part %d)', i)
				sub_appenders, end := parse_sub_block(source, parts, i + 1, stop, needs_depth)
				appenders << fn [sub_appenders] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					idx := idxs[0]
					if idx >= 0 && idx + 1 == len {
						d.log('process directive #last for index %d and length %d', idx,
							len)
						for appender in sub_appenders {
							appender(mut builder, vars, vals, idxs, len)
						}
					} else {
						d.log('ignore directive #last for index %d and length %d', idx,
							len)
					}
				}
				i = end
			}
			Index {
				depth := part.depth
				d.log('append directive #index with depth %d (part %d)', depth, i)
				appenders << fn [depth] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					if depth < idxs.len {
						idx := (idxs[depth] + 1).str()
						d.log('process directive #index with %s, depth %d from %d', idx,
							depth, idxs.len)
						builder.write_string(idx)
					} else {
						d.log('ignore directive #index with depth %d from %d', depth,
							idxs.len)
					}
				}
			}
			Value {
				depth := part.depth
				d.log('append directive #value with depth %d (part %d)', depth, i)
				appenders << fn [depth] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					if depth < vals.len {
						val := vals[depth]
						short_val := d.shorten(val)
						d.log('process directive #value with "%s", depth %d from %d',
							short_val, depth, idxs.len)
						builder.write_string(val)
					} else {
						d.log('ignore directive #value with depth %d from %d', depth,
							idxs.len)
					}
				}
			}
			Variable {
				name := part.name
				d.log('append variable "%s" (part %d)', name, i)
				appenders << fn [name] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					val := vars.get_one(name)
					if val.len > 0 {
						short_val := d.shorten(val)
						d.log('process variable "%s" with "%s"', name, short_val)
						builder.write_string(val)
					} else {
						d.log('ignore variable "%s"', name)
					}
				}
			}
			Lines {
				name := part.name
				d.log('append operation #lines for "%s" (part %d)', name, i)
				appenders << fn [name] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					// if lines := get_values(name, vars, vals, idxs) {
					lines := get_values(name, vars, vals, idxs)
					for i, line in lines {
						if i > 0 {
							builder.write_u8(`\n`)
						}
						builder.write_string(line)
					}
				}
			}
			Items {
				name := part.name
				d.log('append operation #items for "%s" (part %d)', name, i)
				appenders << fn [name] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					// if items := get_values(name, vars, vals, idxs) {
					items := get_values(name, vars, vals, idxs)
					for i, item in items {
						if i > 0 {
							builder.write_u8(`,`)
							builder.write_u8(` `)
						}
						builder.write_string(item)
					}
				}
			}
			If {
				name := part.name
				d.log('append block #if for "%s" (part %d)', name, i)
				sub_appenders, end := parse_sub_block(source, parts, i + 1, stop, needs_depth)
				appenders << fn [sub_appenders, name] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					// if val := get_values(name, vars, vals, idxs) {
					val := get_value(name, vars, vals, idxs)
					if val.len > 0 {
						for appender in sub_appenders {
							appender(mut builder, vars, vals, idxs, len)
						}
					}
				}
				i = end
			}
			Unless {
				name := part.name
				d.log('append block #unless for "%s" (part %d)', name, i)
				sub_appenders, end := parse_sub_block(source, parts, i + 1, stop, needs_depth)
				appenders << fn [sub_appenders, name] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					// if get_values(name, vars, vals, idxs) == none {
					val := get_value(name, vars, vals, idxs)
					if val.len == 0 {
						for appender in sub_appenders {
							appender(mut builder, vars, vals, idxs, len)
						}
					}
				}
				i = end
			}
			For {
				name := part.name
				d.log('append block #for for "%s" (part %d)', name, i)
				sub_appenders, end := parse_sub_block(source, parts, i + 1, stop, needs_depth)
				appenders << fn [sub_appenders, name, needs_depth] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					// if items := get_values(name, vars, vals, idxs) {
					items := get_values(name, vars, vals, idxs)
					if items.len > 0 {
						mut inner_vals := unsafe { &[]string(nil) }
						mut inner_idxs := unsafe { &[]int(nil) }
						if needs_depth {
							mut vals_clone := clone_and_shift(vals, 1)
							inner_vals = &vals_clone
							mut idxs_clone := clone_and_shift(idxs, 1)
							inner_idxs = &idxs_clone
						} else {
							inner_vals = &['']
							inner_idxs = &[0]
						}
						for i, item in items {
							for appender in sub_appenders {
								unsafe {
									inner_vals[0] = item
								}
								unsafe {
									inner_idxs[0] = i
								}
								appender(mut builder, vars, *inner_vals, *inner_idxs,
									items.len)
							}
						}
					}
				}
				i = end
			}
		}
	}
}

fn parse_sub_block(source string, parts []TemplatePart, start int, stop int, needs_depth bool) ([]TemplateAppender, int) {
	end := find_end(parts, start, stop)
	d.log('> block consists of %d parts', end - start)
	mut sub_appenders := []TemplateAppender{cap: end - start}
	parse_template_block(source, parts, start, end, mut sub_appenders, needs_depth)
	d.log('< block starting at part %d ended', start - 1)
	return sub_appenders, end
}

fn find_end(parts []TemplatePart, start int, stop int) int {
	mut depth := 0
	for i := start; i < stop; i++ {
		part := parts[i]
		match part {
			End {
				if depth == 0 {
					return i
				}
				depth--
			}
			First, NotFirst, Middle, NotLast, Last, If, Unless, For {
				depth++
			}
			else {}
		}
	}
	panic('unreachable code')
}

fn get_index(idxs []int, depth int) int {
	return if depth < idxs.len {
		idxs[depth]
	} else {
		-1
	}
}

fn get_value(name string, vars TemplateData, vals []string, idxs []int) string {
	inner_name, depth := get_name_with_depth(name)
	return match inner_name {
		'#index' {
			if depth < idxs.len {
				(idxs[depth] + 1).str()
			} else {
				''
			}
		}
		'#value' {
			if depth < vals.len {
				vals[depth]
			} else {
				''
			}
		}
		else {
			vars.get_one(name)
		}
	}
}

fn get_values(name string, vars TemplateData, vals []string, idxs []int) []string {
	inner_name, depth := get_name_with_depth(name)
	return match inner_name {
		'#index' {
			if depth < idxs.len {
				[(idxs[depth] + 1).str()]
			} else {
				[]string{}
			}
		}
		'#value' {
			if depth < vals.len {
				[vals[depth]]
			} else {
				[]string{}
			}
		}
		else {
			vars.get_more(name)
		}
	}
}

fn get_name_with_depth(name string) (string, int) {
	mut depth := 0
	for unsafe { starts_with_within_nochk(name, '../', depth, name.len) } {
		depth += 3
	}
	if depth > 0 {
		inner_name := name[depth..]
		depth /= 3
		return inner_name, depth
	}
	return name, 0
}

// fn get_values(name string, vars map[string][]string, vals []string, idxs []int) ?[]string {
// 	return match name {
// 		'index' {
// 			if idx >= 0 {
// 				[(idx + 1).str()]
// 			} else {
// 				none
// 			}
// 		}
// 		'value' {
// 			if vals.len > 0 {
// 				vals
// 			} else {
// 				none
// 			}
// 		}
// 		else {
// 			if arr := vars[name] {
// 				arr
// 			} else {
// 				none
// 			}
// 		}
// 	}
// }

fn clone_and_shift[T](src []T, n int) []T {
	mut dst := []T{len: src.len + n}
	if src.len > 0 {
		unsafe { vmemmove(&u8(dst.data) + u64(n) * sizeof(T), src.data, u64(src.len) * sizeof(T)) }
	}
	return dst
}
