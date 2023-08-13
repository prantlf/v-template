module template

fn test_error() {
	err := ParseError{
		msg: 'failed'
		at: 1
	}
	assert err.msg() == 'failed at 1'
}
