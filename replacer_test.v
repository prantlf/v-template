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

fn test_empty() {
	t := parse_replacer('')!
	out := t.replace(map[string][]string{})
	assert out == ''
}

fn test_text() {
	t := parse_replacer('text')!
	out := t.replace(map[string][]string{})
	assert out == 'text'
}

fn test_escaped() {
	t := parse_replacer('\\{text}')!
	out := t.replace(map[string][]string{})
	assert out == '{text}'
}

fn test_escaped_with_before() {
	t := parse_replacer(' \\{')!
	out := t.replace(map[string][]string{})
	assert out == ' {'
}

fn test_escaped_with_after() {
	t := parse_replacer('\\{ ')!
	out := t.replace(map[string][]string{})
	assert out == '{ '
}

fn test_two_escaped() {
	t := parse_replacer('\\{\\{')!
	out := t.replace(map[string][]string{})
	assert out == '{{'
}

fn test_missing() {
	t := parse_replacer('{text}')!
	out := t.replace(map[string][]string{})
	assert out == ''
}

fn test_value() {
	t := parse_replacer('{text}')!
	vars := {
		'text': ['test']
	}
	out := t.replace(vars)
	assert out == 'test'
}

fn test_firstvalue() {
	t := parse_replacer('{text}')!
	vars := {
		'text': ['test1', 'test2']
	}
	out := t.replace(vars)
	assert out == 'test1'
}

fn test_value_opt() {
	t := parse_replacer_opt('{text}', ReplacerOpts{})!
	vars := {
		'text': ['test']
	}
	out := t.replace(vars)
	assert out == 'test'
}

fn test_excluded_var() {
	t := parse_replacer_opt('{text}', ReplacerOpts{
		vars:    ['text']
		exclude: true
	})!
	vars := {
		'text': ['test']
	}
	out := t.replace(vars)
	assert out == '{text}'
}

fn test_not_excluded_var() {
	t := parse_replacer_opt('{text}', ReplacerOpts{
		vars:    ['text2']
		exclude: true
	})!
	vars := {
		'text': ['test']
	}
	out := t.replace(vars)
	assert out == 'test'
}

fn test_included_var() {
	t := parse_replacer_opt('{text}', ReplacerOpts{
		vars: ['text']
	})!
	vars := {
		'text': ['test']
	}
	out := t.replace(vars)
	assert out == 'test'
}

fn test_not_included_var() {
	t := parse_replacer_opt('{text}', ReplacerOpts{
		vars: ['text2']
	})!
	vars := {
		'text': ['test']
	}
	out := t.replace(vars)
	assert out == '{text}'
}
