struct Data {
	description string   = '42'
	issues      []string = ['#87', '#101']
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

fn test_has() {
	vars := Data{}
	assert vars.has('dummy') == false
	assert vars.has('description') == true
}

fn test_get_one_1() {
	vars := Data{}
	assert vars.get_one('dummy') == ''
	assert vars.get_one('description') == '42'
}

fn test_get_one_2() {
	vars := Data{}
	assert vars.get_one('dummy') == ''
	assert vars.get_one('issues') == '#87'
}

fn test_get_more_1() {
	vars := Data{}
	assert vars.get_more('dummy') == []
	assert vars.get_more('description') == ['42']
}

fn test_get_more_2() {
	vars := Data{}
	assert vars.get_more('dummy') == []
	assert vars.get_more('issues') == ['#87', '#101']
}
