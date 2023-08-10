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

fn test_has_1() {
	vars := MapData{
		singles: {
			'test': '42'
		}
	}
	assert vars.has('dummy') == false
	assert vars.has('test') == true
}

fn test_has_2() {
	vars := MapData{
		arrays: {
			'test': ['42']
		}
	}
	assert vars.has('dummy') == false
	assert vars.has('test') == true
}

fn test_get_one_1() {
	vars := MapData{
		singles: {
			'test': '42'
		}
	}
	assert vars.get_one('dummy') == ''
	assert vars.get_one('test') == '42'
}

fn test_get_one_2() {
	vars := MapData{
		arrays: {
			'test': ['42']
		}
	}
	assert vars.get_one('dummy') == ''
	assert vars.get_one('test') == '42'
}

fn test_get_more_1() {
	vars := MapData{
		singles: {
			'test': '42'
		}
	}
	assert vars.get_more('dummy') == []
	assert vars.get_more('test') == ['42']
}

fn test_get_more_2() {
	vars := MapData{
		arrays: {
			'test': ['42']
		}
	}
	assert vars.get_more('dummy') == []
	assert vars.get_more('test') == ['42']
}
