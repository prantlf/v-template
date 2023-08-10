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

fn test_has() {
	vars := {
		'test': ['42']
	}
	assert vars.has('dummy') == false
	assert vars.has('test') == true
}

fn test_get_one() {
	vars := {
		'test': ['42']
	}
	assert vars.get_one('dummy') == ''
	assert vars.get_one('test') == '42'
}

fn test_get_more() {
	vars := {
		'test': ['42']
	}
	assert vars.get_more('dummy') == []
	assert vars.get_more('test') == ['42']
}
