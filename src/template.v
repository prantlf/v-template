module template

import strings { Builder, new_builder }
import prantlf.strutil { contains_at, index_u8_within, skip_space, skip_trailing_space }

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

struct First {
	depth int
}

struct NotFirst {
	depth int
}

struct Middle {
	depth int
}

struct NotLast {
	depth int
}

struct Last {
	depth int
}

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

[noinit]
pub struct Template {
	source_len int
	appenders    []TemplateAppender
}

pub interface TemplateData {
	has(name string) bool
	get_one(name string) string
	get_more(name string) []string
}

pub fn (t &Template) generate(vars TemplateData) string {
	mut builder := new_builder(t.source_len)
	for appender in t.appenders {
		appender(mut builder, vars, [], [], 0)
	}
	return builder.str()
}

pub fn parse_template(source string) !&Template {
	parts, needs_depth := scan_template(source)!

	mut appenders := []TemplateAppender{cap: parts.len}
	parse_template_block(source, parts, 0, parts.len, mut appenders, needs_depth)

	return &Template{
		source_len: source.len
		appenders: appenders
	}
}

fn scan_template(source string) !([]TemplatePart, bool) {
	mut parts := []TemplatePart{cap: 8}
	mut needs_depth := false
	stop := source.len
	mut open := -1
	mut close := 0
	mut depth := 0
	for {
		open = index_u8_within(source, `{`, open + 1, stop)
		if open < 0 {
			try_add_literal(mut parts, close, stop)
			break
		}

		if open == 0 || source[open - 1] != `\\` {
			try_add_literal(mut parts, close, open)

			close = index_u8_within(source, `}`, open + 1, stop)
			if close < 0 {
				return error('missing } for { at ${open}')
			}

			name_start := skip_space(source, open + 1, close)
			name_end := skip_trailing_space(source, name_start, close)
			mut name := source[name_start..name_end]

			start := open
			open = close
			close++

			space := name.index_u8(` `)
			if space > 0 {
				op := name[..space]
				name_start2 := skip_space(name, space + 1, name.len)
				name = name[name_start2..]
				if name.len == 0 {
					return error('missing operand for {${op}} at ${start}')
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
						return error('unrecognised operator {${op}} at ${start}')
					}
				}
			} else {
				inner_name, name_depth := get_name_with_depth(name)
				if name_depth > 0 {
					needs_depth = true
				}
				match inner_name {
					'#end' {
						if depth == 0 {
							return error('extra {end} at ${start}')
						}
						depth--
						parts << End{}
					}
					'#first' {
						parts << First{
							depth: name_depth
						}
						depth++
					}
					'#notfirst' {
						parts << NotFirst{
							depth: name_depth
						}
						depth++
					}
					'#middle' {
						parts << Middle{
							depth: name_depth
						}
						depth++
					}
					'#notlast' {
						parts << NotLast{
							depth: name_depth
						}
						depth++
					}
					'#last' {
						parts << Last{
							depth: name_depth
						}
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
							return error('unrecognised directive {${name}} at ${start}')
						}
						parts << Variable{
							name: name
						}
					}
				}
			}
		} else {
			try_add_literal(mut parts, close, open - 1)
			close = open
		}
	}

	if depth > 0 {
		return error('missing trailing {#end}')
	}

	return parts, needs_depth
}

fn try_add_literal[T](mut parts []T, start int, stop int) {
	len := stop - start
	if len > 0 {
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
				appenders << fn [t, s, l] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					if l > 0 {
						unsafe { builder.write_ptr(t.str + s, l) }
					}
				}
			}
			End {
				panic('unexpected end part reached')
			}
			First {
				depth := part.depth
				sub_appenders, end := parse_sub_block(source, parts, i + 1, stop, needs_depth)
				appenders << fn [sub_appenders, depth] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					idx := get_index(idxs, depth)
					if idx == 0 {
						for appender in sub_appenders {
							appender(mut builder, vars, vals, idxs, len)
						}
					}
				}
				i = end
			}
			NotFirst {
				depth := part.depth
				sub_appenders, end := parse_sub_block(source, parts, i + 1, stop, needs_depth)
				appenders << fn [sub_appenders, depth] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					idx := get_index(idxs, depth)
					if idx > 0 {
						for appender in sub_appenders {
							appender(mut builder, vars, vals, idxs, len)
						}
					}
				}
				i = end
			}
			Middle {
				depth := part.depth
				sub_appenders, end := parse_sub_block(source, parts, i + 1, stop, needs_depth)
				appenders << fn [sub_appenders, depth] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					idx := get_index(idxs, depth)
					if idx > 0 && idx + 1 != len {
						for appender in sub_appenders {
							appender(mut builder, vars, vals, idxs, len)
						}
					}
				}
				i = end
			}
			NotLast {
				depth := part.depth
				sub_appenders, end := parse_sub_block(source, parts, i + 1, stop, needs_depth)
				appenders << fn [sub_appenders, depth] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					idx := get_index(idxs, depth)
					if idx >= 0 && idx + 1 < len {
						for appender in sub_appenders {
							appender(mut builder, vars, vals, idxs, len)
						}
					}
				}
				i = end
			}
			Last {
				depth := part.depth
				sub_appenders, end := parse_sub_block(source, parts, i + 1, stop, needs_depth)
				appenders << fn [sub_appenders, depth] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					idx := get_index(idxs, depth)
					if idx >= 0 && idx + 1 == len {
						for appender in sub_appenders {
							appender(mut builder, vars, vals, idxs, len)
						}
					}
				}
				i = end
			}
			Index {
				depth := part.depth
				appenders << fn [depth] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					if depth < idxs.len {
						builder.write_string((idxs[depth] + 1).str())
					}
				}
			}
			Value {
				depth := part.depth
				appenders << fn [depth] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					if depth < vals.len {
						builder.write_string(vals[depth])
					}
				}
			}
			Variable {
				name := part.name
				appenders << fn [name] (mut builder Builder, vars TemplateData, vals []string, idxs []int, len int) {
					val := vars.get_one(name)
					if val.len > 0 {
						builder.write_string(val)
					}
				}
			}
			Lines {
				name := part.name
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
	mut sub_appenders := []TemplateAppender{cap: end - start - 1}
	parse_template_block(source, parts, start, end, mut sub_appenders, needs_depth)
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
	for contains_at(name, '../', depth) {
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
