#!/usr/bin/env -S v -prod run

import benchmark { start }
import strings { Builder, new_builder }
import prantlf.strutil { index_u8_within_nochk }
import prantlf.template { parse_replacer, parse_template }

fn (m map[string][]string) has(name string) bool {
	return name in m
}

fn (m map[string][]string) get_one(name string) string {
	val := m[name]
	return if val.len > 0 {
		val[0]
	} else {
		''
	}
}

fn (m map[string][]string) get_more(name string) []string {
	return m[name]
}

// fn (m map[string][]string) get_one_opt(name string) ?string {
// 	val := m[name]
// 	return if val.len > 0 {
// 		val[0]
// 	} else {
// 		none
// 	}
// }

// fn (m map[string][]string) get_more_opt(name string) ?[]string {
// 	return if name in m {
// 		m[name]
// 	} else {
// 		none
// 	}
// }

fn replace(tpl string, vars map[string][]string) !string {
	mut out := tpl
	for name, val in vars {
		out = out.replace('{${name}}', val[0])
	}
	return out
}

fn fill(tpl string, vars map[string][]string) !string {
	mut open := tpl.index_u8(`{`)
	if open < 0 {
		return tpl
	}

	stop := tpl.len
	mut builder := new_builder(stop * 2)
	mut close := 0
	for {
		if open == 0 || tpl[open - 1] != `\\` {
			unsafe { builder.write_ptr(tpl.str + close, open - close) }
			close = unsafe { index_u8_within_nochk(tpl, `}`, open + 1, stop) }
			if close < 0 {
				return error('missing closing brace after ${open}')
			}
			mut name := tpl[open + 1..close]
			open = close
			close++

			space := name.index_u8(` `)
			if space > 0 {
				op := name[..space]
				name = name[space + 1..]
				if !eval_var(mut builder, op, name, vars) {
					match op {
						'if' {
							end := find_end(tpl, '{fi}', open, stop)!
							if val := vars[name] {
								fill_block(mut builder, tpl, close, end, val[0], -1, -1,
									vars)!
							}
							open = end + 3
							close = open + 1
						}
						'for' {
							end := find_end(tpl, '{rof}', open, stop)!
							if vals := vars[name] {
								for i, val in vals {
									fill_block(mut builder, tpl, close, end, val, i, vals.len,
										vars)!
								}
							}
							open = end + 4
							close = open + 1
						}
						else {
							return error('unrecognised operator "${op}"')
						}
					}
				}
			} else {
				if val := vars[name] {
					builder.write_string(val[0])
				}
			}
		} else {
			unsafe { builder.write_ptr(tpl.str + close, open - close - 1) }
			builder.write_u8(`{`)
			close = open + 1
		}

		open = unsafe { index_u8_within_nochk(tpl, `{`, open + 1, stop) }
		if open < 0 {
			unsafe { builder.write_ptr(tpl.str + close, stop - close) }
			break
		}
	}

	return builder.str()
}

fn fill_block(mut builder Builder, tpl string, start int, stop int, value string, index int, length int, vars map[string][]string) ! {
	mut open := unsafe { index_u8_within_nochk(tpl, `{`, start, stop) }
	if open < 0 {
		unsafe { builder.write_ptr(tpl.str + start, stop - start) }
		return
	}

	mut close := start
	for {
		if tpl[open - 1] != `\\` {
			unsafe { builder.write_ptr(tpl.str + close, open - close) }
			close = unsafe { index_u8_within_nochk(tpl, `}`, open + 1, stop) }
			if close < 0 {
				return error('missing closing brace after ${open}')
			}
			mut name := tpl[open + 1..close]
			open = close
			close++

			space := name.index_u8(` `)
			if space > 0 {
				op := name[..space]
				name = name[space + 1..]
				if !eval_var(mut builder, op, name, vars) {
					match op {
						'if' {
							end := find_end(tpl, '{fi}', open, stop)!
							if val := vars[name] {
								fill_block(mut builder, tpl, close, end, val[0], -1, -1,
									vars)!
							}
							open = end + 3
							close = open + 1
						}
						'for' {
							end := find_end(tpl, '{rof}', open, stop)!
							if vals := vars[name] {
								for i, val in vals {
									fill_block(mut builder, tpl, close, end, val, i, vals.len,
										vars)!
								}
							}
							open = end + 4
							close = open + 1
						}
						else {
							return error('unrecognised operator "${op}"')
						}
					}
				}
			} else {
				match name {
					'first' {
						end := find_end(tpl, '{tsrif}', open, stop)!
						if index == 0 {
							fill_block(mut builder, tpl, close, end, value, index, length,
								vars)!
						}
						open = end + 5
						close = open + 1
					}
					'notfirst' {
						end := find_end(tpl, '{tsrifton}', open, stop)!
						if index > 0 {
							fill_block(mut builder, tpl, close, end, value, index, length,
								vars)!
						}
						open = end + 9
						close = open + 1
					}
					'middle' {
						end := find_end(tpl, '{elddim}', open, stop)!
						if index > 0 && index + 1 < length {
							fill_block(mut builder, tpl, close, end, value, index, length,
								vars)!
						}
						open = end + 7
						close = open + 1
					}
					'notlast' {
						end := find_end(tpl, '{tsalton}', open, stop)!
						if index + 1 < length {
							fill_block(mut builder, tpl, close, end, value, index, length,
								vars)!
						}
						open = end + 8
						close = open + 1
					}
					'last' {
						end := find_end(tpl, '{tsal}', open, stop)!
						if index + 1 == length {
							fill_block(mut builder, tpl, close, end, value, index, length,
								vars)!
						}
						open = end + 5
						close = open + 1
					}
					'index' {
						builder.write_string('${index + 1}')
					}
					'value' {
						builder.write_string(value)
					}
					else {
						if val := vars[name] {
							builder.write_string(val[0])
						}
					}
				}
			}
		} else {
			unsafe { builder.write_ptr(tpl.str + close, open - close - 1) }
			builder.write_u8(`{`)
			close = open + 1
		}

		open = unsafe { index_u8_within_nochk(tpl, `{`, open + 1, stop) }
		if open < 0 {
			unsafe { builder.write_ptr(tpl.str + close, stop - close) }
			break
		}
	}
}

fn eval_var(mut builder Builder, op string, name string, vars map[string][]string) bool {
	match op {
		'lines' {
			if lines := vars[name] {
				for i, line in lines {
					if i > 0 {
						builder.write_u8(`\n`)
					}
					builder.write_string(line)
				}
			}
		}
		'items' {
			if items := vars[name] {
				for i, item in items {
					if i > 0 {
						builder.write_u8(`,`)
						builder.write_u8(` `)
					}
					builder.write_string(item)
				}
			}
		}
		else {
			return false
		}
	}
	return true
}

fn find_end(tpl string, op string, start int, stop int) !int {
	mut end := start
	for {
		end = tpl.index_after(op, end + 1)
		if end < 0 || end >= stop {
			return error('missing closing ${op} after ${end}')
		}
		if tpl[end - 1] != `\\` {
			break
		}
	}
	return end
}

const repeat_count = 10000000

const repeat_count2 = 1000000

s1 := 'test'
t1 := parse_template(s1)!
r1 := parse_replacer(s1)!
m1 := map[string][]string{}

s2 := '{text}'
t2 := parse_template(s2)!
r2 := parse_replacer(s2)!
m2 := {
	'text': ['test']
}

s31 := '{for text} {value}{rof}'
s32 := '{#for text} {#value}{#end}'
t3 := parse_template(s32)!
m3 := {
	'text': ['test1', 'test2']
}

s4 := '{heading} [{version}]({repo_url}/compare/{tag_prefix}{prev_version}...{tag_prefix}{version}) ({date})'
t4 := parse_template(s4)!
r4 := parse_replacer(s4)!
m4 := {
	'heading':      ['##']
	'date':         ['2023-04-27']
	'prev_version': ['14.0.2']
	'version':      ['14.0.3']
	'tag_prefix':   ['v']
	'repo_url':     ['https://github.com/prantlf/jsonlint']
}

s51 := '* {description} ([{short_hash}]({repo_url}/commit/{hash})){if issues}
  fixes [{for issues}{middle}), [{elddim}{notfirst}{last}) and [{tsal}{tsrifton}#{value}]({repo_url}/issues/{value}{rof}){fi}'
s52 := '* {description} ([{short_hash}]({repo_url}/commit/{hash})){#if issues}
  fixes [{#for issues}{#middle}), [{#end}{#notfirst}{#last}) and [{#end}{#end}#{#value}]({repo_url}/issues/{#value}{#end}){#end}'
t5 := parse_template(s52)!
m5 := {
	'description': ['Ensure error location by custom parsing']
	'short_hash':  ['9757213']
	'hash':        ['9757213eda5de9684099024d0c4f59e4d4f59c97']
	'repo_url':    ['https://github.com/prantlf/jsonlint']
	'issues':      ['87', '95', '101']
}

mut b := start()

for _ in 0 .. repeat_count {
	replace(s1, m1)!
}
b.measure('literal replaced')

for _ in 0 .. repeat_count {
	fill(s1, m1)!
}
b.measure('literal interpreted')

for _ in 0 .. repeat_count {
	t1.generate(m1)
}
b.measure('literal compiled template')

for _ in 0 .. repeat_count {
	r1.replace(m1)
}
b.measure('literal compiled replacer')

for _ in 0 .. repeat_count {
	replace(s2, m2)!
}
b.measure('variable replaced')

for _ in 0 .. repeat_count {
	fill(s2, m2)!
}
b.measure('variable interpreted')

for _ in 0 .. repeat_count {
	t2.generate(m2)
}
b.measure('variable compiled template')

for _ in 0 .. repeat_count {
	r2.replace(m2)
}
b.measure('variable compiled replacer')

for _ in 0 .. repeat_count2 {
	fill(s31, m3)!
}
b.measure('loop interpreted')

for _ in 0 .. repeat_count2 {
	t3.generate(m3)
}
b.measure('loop compiled template')

for _ in 0 .. repeat_count2 {
	replace(s4, m4)!
}
b.measure('version replaced')

for _ in 0 .. repeat_count2 {
	fill(s4, m4)!
}
b.measure('version interpreted')

for _ in 0 .. repeat_count2 {
	t4.generate(m4)
}
b.measure('version compiled template')

for _ in 0 .. repeat_count2 {
	r4.replace(m4)
}
b.measure('version compiled replacer')

for _ in 0 .. repeat_count2 {
	fill(s51, m5)!
}
b.measure('commit interpreted')

for _ in 0 .. repeat_count2 {
	t5.generate(m5)
}
b.measure('commit compiled template')
