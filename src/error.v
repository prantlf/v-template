module template

@[noinit]
pub struct ParseError {
	Error
pub:
	msg string
	at  int
}

fn (e ParseError) msg() string {
	return '${e.msg} at ${e.at}'
}
