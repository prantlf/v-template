#!/usr/bin/env -S v -prod run

import benchmark { start }
import prantlf.template

// fn (m map[string]string) has(name string) bool {
//   return name in m
// }

// fn (m map[string]string) get_one(name string) string {
//   return m[name]
// }

// fn (m map[string]string) get_more(name string) []string {
//   return if name in m {
//     [m[name]]
//   } else {
//     []
//   }
// }

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

struct MapData {
	singles map[string]string
	arrays  map[string][]string
}

fn (d &MapData) has(name string) bool {
	return name in d.singles || name in d.arrays
}

fn (d &MapData) get_one(name string) string {
	return if name in d.singles {
		d.singles[name]
	} else {
		val := d.arrays[name]
		if val.len > 0 {
			val[0]
		} else {
			''
		}
	}
}

fn (d &MapData) get_more(name string) []string {
	return if name in d.arrays {
		d.arrays[name]
	} else if name in d.singles {
		[d.singles[name]]
	} else {
		[]string{}
	}
}

struct Data {
	description     string   = 'Ensure error location by custom parsing'
	short_hash      string   = '9757213'
	hash            string   = '9757213eda5de9684099024d0c4f59e4d4f59c97'
	repo_url        string   = 'https://github.com/prantlf/jsonlint'
	issues          []string = ['87', '95', '101']
	breaking_change []string = [
	"* Although you shouldn't notice any change on the behaviour of the command line, something unexpected might've changed.",
	'* The default environment recognises only JSON Schema drafts 06 and 07 automatically.',
	'* Dropped support for Node.js 12. The minimum supported version is Node.js 14.',
	'* If you used the property "exzerpt" from the parsing error object, you have to change it to "excerpt".',
]
}

fn (d &Data) has(name string) bool {
	return has_field(d, name)
}

fn (d &Data) get_one(name string) string {
	return get_one_field(d, name)
}

fn (d &Data) get_more(name string) []string {
	return get_more_field(d, name)
}

fn has_field[T](data &T, name string) bool {
	$for field in T.fields {
		if field.name == name {
			return true
		}
	}
	return false
}

fn get_one_field[T](data &T, name string) string {
	$for field in T.fields {
		if field.name == name {
			$if field.is_array {
				val := data.$(field.name)
				return if val.len > 0 {
					val[0]
				} else {
					''
				}
			} $else $if field.typ is string {
				return data.$(field.name)
			}
		}
	}
	return ''
}

fn get_more_field[T](data &T, name string) []string {
	$for field in T.fields {
		if field.name == name {
			$if field.is_array {
				return data.$(field.name)
			} $else $if field.typ is string {
				return [data.$(field.name)]
			}
		}
	}
	return []
}

const repeat_count = 1000000

// string_map := {
// 	'description': 'Ensure error location by custom parsing'
// 	'short_hash':  '9757213'
// 	'hash':        '9757213eda5de9684099024d0c4f59e4d4f59c97'
// 	'repo_url':    'https://github.com/prantlf/jsonlint'
// }

string_array_map := {
	'description':     ['Ensure error location by custom parsing']
	'short_hash':      ['9757213']
	'hash':            ['9757213eda5de9684099024d0c4f59e4d4f59c97']
	'repo_url':        ['https://github.com/prantlf/jsonlint']
	'issues':          ['87', '95', '101']
	'BREAKING_CHANGE': [
		"* Although you shouldn't notice any change on the behaviour of the command line, something unexpected might've changed.",
		'* The default environment recognises only JSON Schema drafts 06 and 07 automatically.',
		'* Dropped support for Node.js 12. The minimum supported version is Node.js 14.',
		'* If you used the property "exzerpt" from the parsing error object, you have to change it to "excerpt".',
	]
}

two_map := MapData{
	singles: {
		'description': 'Ensure error location by custom parsing'
		'short_hash':  '9757213'
		'hash':        '9757213eda5de9684099024d0c4f59e4d4f59c97'
		'repo_url':    'https://github.com/prantlf/jsonlint'
	}
	arrays:  {
		'issues':          ['87', '95', '101']
		'BREAKING_CHANGE': [
			"* Although you shouldn't notice any change on the behaviour of the command line, something unexpected might've changed.",
			'* The default environment recognises only JSON Schema drafts 06 and 07 automatically.',
			'* Dropped support for Node.js 12. The minimum supported version is Node.js 14.',
			'* If you used the property "exzerpt" from the parsing error object, you have to change it to "excerpt".',
		]
	}
}

struct_data := Data{}

assert string_array_map.has('description')
assert two_map.has('description')
assert struct_data.has('description')
assert string_array_map.get_one('description') == '42'
assert two_map.get_one('description') == '42'
assert struct_data.get_one('description') == '42'
assert string_array_map.get_one('issues') == '87'
assert two_map.get_one('issues') == '87'
assert struct_data.get_one('issues') == '87'
assert string_array_map.get_more('description') == ['42']
assert two_map.get_more('description') == ['42']
assert struct_data.get_more('description') == ['42']
assert string_array_map.get_more('issues') == ['87', '95', '101']
assert two_map.get_more('issues') == ['87', '95', '101']
assert struct_data.get_more('issues') == ['87', '95', '101']

mut f := []bool{cap: repeat_count * 4}
mut s := []string{cap: repeat_count * 7}

mut b := start()

// for _ in 0 .. repeat_count {
// 	string_map.has('description')
// 	string_map.has('short_hash')
// 	string_map.has('hash')
// 	string_map.has('repo_url')
// }
// b.measure('string map has one')

f.clear()
for _ in 0 .. repeat_count {
	f << string_array_map.has('description')
	f << string_array_map.has('short_hash')
	f << string_array_map.has('hash')
	f << string_array_map.has('repo_url')
}
b.measure('string-array map has one')

f.clear()
for _ in 0 .. repeat_count {
	f << two_map.has('description')
	f << two_map.has('short_hash')
	f << two_map.has('hash')
	f << two_map.has('repo_url')
}
b.measure('two map has one')

f.clear()
for _ in 0 .. repeat_count {
	f << struct_data.has('description')
	f << struct_data.has('short_hash')
	f << struct_data.has('hash')
	f << struct_data.has('repo_url')
}
b.measure('struct has one')

f.clear()
for _ in 0 .. repeat_count {
	f << string_array_map.has('issues')
	f << string_array_map.has('BREAKING_CHANGE')
}
b.measure('string-array map has more')

f.clear()
for _ in 0 .. repeat_count {
	f << two_map.has('issues')
	f << two_map.has('BREAKING_CHANGE')
}
b.measure('two map has more')

f.clear()
for _ in 0 .. repeat_count {
	f << struct_data.has('issues')
	f << struct_data.has('breaking_change')
}
b.measure('struct has more')

// for _ in 0 .. repeat_count {
// 	string_map.get_one('description')
// 	string_map.get_one('short_hash')
// 	string_map.get_one('hash')
// 	string_map.get_one('repo_url')
// }
// b.measure('string map get one')

s.clear()
for _ in 0 .. repeat_count {
	s << string_array_map.get_one('description')
	s << string_array_map.get_one('short_hash')
	s << string_array_map.get_one('hash')
	s << string_array_map.get_one('repo_url')
}
b.measure('string-array map get one from one')

s.clear()
for _ in 0 .. repeat_count {
	s << two_map.get_one('description')
	s << two_map.get_one('short_hash')
	s << two_map.get_one('hash')
	s << two_map.get_one('repo_url')
}
b.measure('two map get one from one')

s.clear()
for _ in 0 .. repeat_count {
	s << struct_data.get_one('description')
	s << struct_data.get_one('short_hash')
	s << struct_data.get_one('hash')
	s << struct_data.get_one('repo_url')
}
b.measure('struct get one from one')

s.clear()
for _ in 0 .. repeat_count {
	s << string_array_map.get_one('issues')
	s << string_array_map.get_one('breaking_change')
}
b.measure('string-array map get one from more')

s.clear()
for _ in 0 .. repeat_count {
	s << two_map.get_one('issues')
	s << two_map.get_one('breaking_change')
}
b.measure('two map get one from more')

s.clear()
for _ in 0 .. repeat_count {
	s << struct_data.get_one('issues')
	s << struct_data.get_one('breaking_change')
}
b.measure('struct get one from more')

s.clear()
for _ in 0 .. repeat_count {
	s << string_array_map.get_more('description')
	s << string_array_map.get_more('short_hash')
	s << string_array_map.get_more('hash')
	s << string_array_map.get_more('repo_url')
}
b.measure('string-array map get more from one')

s.clear()
for _ in 0 .. repeat_count {
	s << two_map.get_more('description')
	s << two_map.get_more('short_hash')
	s << two_map.get_more('hash')
	s << two_map.get_more('repo_url')
}
b.measure('two map get more from one')

s.clear()
for _ in 0 .. repeat_count {
	s << struct_data.get_more('description')
	s << struct_data.get_more('short_hash')
	s << struct_data.get_more('hash')
	s << struct_data.get_more('repo_url')
}
b.measure('struct get more from one')

s.clear()
for _ in 0 .. repeat_count {
	s << string_array_map.get_more('issues')
	s << string_array_map.get_one('BREAKING_CHANGE')
}
b.measure('string-array map get more from more')

s.clear()
for _ in 0 .. repeat_count {
	s << two_map.get_more('issues')
	s << two_map.get_one('BREAKING_CHANGE')
}
b.measure('two map get more from more')

s.clear()
for _ in 0 .. repeat_count {
	s << struct_data.get_more('issues')
	s << struct_data.get_one('breaking_change')
}
b.measure('struct get more from more')
