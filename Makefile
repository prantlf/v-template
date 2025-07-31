all: check test

check:
	v fmt -w .
	v vet .

test:
	v test .
