module template

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

fn test_empty() {
	t := parse_template('')!
	out := t.generate(map[string][]string{})
	assert out == ''
}

fn test_text() {
	t := parse_template('text')!
	out := t.generate(map[string][]string{})
	assert out == 'text'
}

fn test_escaped() {
	t := parse_template('\\{text}')!
	out := t.generate(map[string][]string{})
	assert out == '{text}'
}

fn test_escaped_with_before() {
	t := parse_template(' \\{')!
	out := t.generate(map[string][]string{})
	assert out == ' {'
}

fn test_escaped_with_after() {
	t := parse_template('\\{ ')!
	out := t.generate(map[string][]string{})
	assert out == '{ '
}

fn test_two_escaped() {
	t := parse_template('\\{\\{')!
	out := t.generate(map[string][]string{})
	assert out == '{{'
}

fn test_missing() {
	t := parse_template('{text}')!
	out := t.generate(map[string][]string{})
	assert out == ''
}

fn test_value() {
	t := parse_template('{text}')!
	vars := {
		'text': ['test']
	}
	out := t.generate(vars)
	assert out == 'test'
}

fn test_firstvalue() {
	t := parse_template('{text}')!
	vars := {
		'text': ['test1', 'test2']
	}
	out := t.generate(vars)
	assert out == 'test1'
}

fn test_lines_1() {
	t := parse_template('{#lines text}')!
	vars := {
		'text': ['test']
	}
	out := t.generate(vars)
	assert out == 'test'
}

fn test_lines_2() {
	t := parse_template('{#lines text}')!
	vars := {
		'text': ['test1', 'test2']
	}
	out := t.generate(vars)
	assert out == 'test1
test2'
}

fn test_items_1() {
	t := parse_template('{#items text}')!
	vars := {
		'text': ['test']
	}
	out := t.generate(vars)
	assert out == 'test'
}

fn test_items_2() {
	t := parse_template('{#items text}')!
	vars := {
		'text': ['test1', 'test2']
	}
	out := t.generate(vars)
	assert out == 'test1, test2'
}

fn test_if_false() {
	t := parse_template('{#if text}true{#end}')!
	out := t.generate(map[string][]string{})
	assert out == ''
}

fn test_if_true() {
	t := parse_template('{#if text}true{#end}')!
	vars := {
		'text': ['test']
	}
	out := t.generate(vars)
	assert out == 'true'
}

fn test_unless_false() {
	t := parse_template('{#unless text}true{#end}')!
	out := t.generate(map[string][]string{})
	assert out == 'true'
}

fn test_unless_true() {
	t := parse_template('{#unless text}true{#end}')!
	vars := {
		'text': ['test']
	}
	out := t.generate(vars)
	assert out == ''
}

fn test_for_none() {
	t := parse_template('{#for text}one{#end}')!
	out := t.generate(map[string][]string{})
	assert out == ''
}

fn test_for_one() {
	t := parse_template('{#for text}one{#end}')!
	vars := {
		'text': ['test']
	}
	out := t.generate(vars)
	assert out == 'one'
}

fn test_for_builtins_1() {
	t := parse_template('{#for text}{#middle}, {#end}{#notfirst}{#last} and {#end}{#end}{#index}:{#value}{#end}')!
	vars := {
		'text': ['test1', 'test2', 'test3']
	}
	out := t.generate(vars)
	assert out == '1:test1, 2:test2 and 3:test3'
}

fn test_for_builtins_2() {
	t := parse_template('{#for text}{#first}f{#end}{#notlast}n{#end}{#end}')!
	vars := {
		'text': ['test1', 'test2', 'test3']
	}
	out := t.generate(vars)
	assert out == 'fnn'
}

fn test_if_with_for() {
	t := parse_template('{#if text}[{#for text}{#notfirst}), [{#end}{#value}](http://{#value}{#end}){#end}')!
	vars := {
		'text': ['test1', 'test2']
	}
	out := t.generate(vars)
	assert out == '[test1](http://test1), [test2](http://test2)'
}

fn test_nested_for() {
	t := parse_template('{#for level1}{#for level2}{../#index}{../#value}{#index}{#value}{#end}{#end}')!
	vars := {
		'level1': ['a', 'b']
		'level2': ['c', 'd']
	}
	out := t.generate(vars)
	assert out == '1a1c1a2d2b1c2b2d'
}
