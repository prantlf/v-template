# template

Simple and fast string templating library.

* Compiles to an array of generator functions for [faster string generation](bench/README.md).
* [Abstracted input data](#abstractions) to support not only string maps.

## Synopsis

Generating a string using a map `string` to `string`. See the implementation of `TemplateData` in [abstractions] below:

```go
import prantlf.template { parse_template }

source := '## [{version}]({repo_url}/compare/v{prev_version}...v{version}) ({date})'
template := parse_template(source)!

vars := {
  'date': '2023-04-27'
  'prev_version': '14.0.2'
  'version': '14.0.3'
  'repo_url': 'https://github.com/prantlf/jsonlint'
}
output := template.generate(vars)
```

Output:

    ## [14.0.3](https://github.com/prantlf/jsonlint/compare/v14.0.2...v14.0.3) (2023-04-27)

Generating a string using a map `string` to `[]string`. See the implementation of `TemplateData` in [abstractions] below:

```go
import prantlf.template { parse_template }

source := '* {description} ([{short_hash}]({repo_url}/commit/{hash})){if issues}
  fixes [{for issues}{notfirst}), [{end}#{value}]({repo_url}/issues/{value}{end}){end}'
template := parse_template(source)!

vars := {
  'description': ['Ensure error location by custom parsing']
  'short_hash': ['9757213']
  'hash': ['9757213eda5de9684099024d0c4f59e4d4f59c97']
  'repo_url': ['https://github.com/prantlf/jsonlint']
  'issues': ['87', '101']
}
output := template.generate(vars)
```

Output (obvious parts shortened by `...` to fit the screen width):

    * Ensure error location by custom parsing ([9757213](https://github.com/prantlf/jsonlint/commit/9...7))
      fixes [#87](https://github.com/prantlf/jsonlint/issues/87), [#101](https://github.com/p...s/101)

## Installation

You can install this package either from [VPM] or from GitHub:

```txt
v install prantlf.template
v install --git https://github.com/prantlf/v-template
```

## Syntax

The `{` (opening brace) is a special character, which starts a directive. If you want to treat a `{` as an ordinary character, escape it by prefixing it with `\` (backslash): `\{`.

If not escaped, the leading `{` (opening brace) with a following `}` (closing brace) is expected to encapsulate a directive. ` ` (spaces) may be present after the leading `{` and before the trailing `}`. The directive can be either a single word, ot two words delimited by one or more ` `.

### Literal

A sequence of ordinary characters will be just copied to the output.

    template: "# Changes"
    vars:     {}
    output:   "# Changes"

### Variable

A value directive `{<variable>}`. A name of a variable enclosed in `{` (opening brace) and `}` (closing brace) will be copied to the input if the variable exists, otherwise it will be treated as if the value was an empty string.

    template: "# {title}"
    vars:     { title: 'Changes' }
    output:   "# Changes"

Variable name must not start with `#` (hash), which is reserved character for the directives to start with.

### Items

A value directive `{#items <variable>}`. An array from the variable will be copied to the output as a string with the values joined with `, `. If the array contains no or just a single value, the result will be the same as if a [single-value variable](#variable) was processed.

    template: "Issues: {#items issues}"
    vars:     { issues: ['#87', '#101'] }
    output:   "Issues: #87, #101"

Instead of a variable name, directives `#value` or `#index` including the optional depth prefix may be used too.

### Lines

A value directive `{#lines <variable>}`. An array from the variable will be copied to the output as a string with the values joined with `\n` (line break). If the array contains no or just a single value, the result will be the same as if a [single-value variable](#variable) was processed.

    template: "{#lines issues}"
    vars:     { issues: ['#87', '#101'] }
    output:   "#87\n#101"

Instead of a variable name, directives `#value` or `#index` including the optional depth prefix may be used too.

### If

An block directive `{#if <variable>}...{#end}`. If the variable exists (and is not empty in case of an array) the part of the template between `{#if <variable>}` and `{#end}` will be processed, otherwise it will be skipped as if it was empty.

    template: "{#if issue}Issue: {issue}{#end}"
    vars:     { issue: '#87' }
    output:   "Issue: #87"

Instead of a variable name, directives `#value` or `#index` including the optional depth prefix may be used too.

### Unless

An block directive `{#unless <variable>}...{#end}`. If the variable exists (and is not empty in case of an array) the part of the template between `{#unless <variable>}` and `{#end}` will be skipped as if it was empty, otherwise it will be processed.

    template: "{#unless issue}no issue attached{#end}"
    vars:     { issue: '#87' }
    output:   ""

Instead of a variable name, directives `#value` or `#index` including the optional depth prefix may be used too.

### For

An block directive `{#for <variable>}...{#end}`. If the variable exists, the part of the template between `{#for <variable>}` and `{#end}` will be processed repeatedly for each item in the array if value is an array, or once for the single value if not.

    template: "{#for issues}.{#end}"
    vars:     { issues: ['#87', '#101'] }
    output:   ".."

Instead of a variable name, directives `#value` or `#index` including the optional depth prefix may be used too.

### Index

A value directive `{#index}`, which is valid within the `for` directive. It contains a 1-based index of the current loop iteration.

    template: "Counter:{#for issues} {#index}{#end}"
    vars:     { issues: ['#87', '#101'] }
    output:   "Counter: 1 2"

If `for` directives are nested, the current index from the outer loop can be accessed by prefixing it with `../`, for example: `{../#index}`. The prefix `../` can be chained for deeply nested loops.

### Value

A value directive `{#value}`, which is valid within the `for` directive. It contains a value of the array item with which the current loop iteration is performed.

    template: "Issues:{#for issues} {#value}{#end}"
    vars:     { issues: ['#87', '#101'] }
    output:   "Issues: #87 #101"

If `for` directives are nested, the current value from the outer loop can be accessed by prefixing it with `../`, for example: `{../#value}`. The prefix `../` can be chained for deeply nested loops.

### First

An block directive `{#first}...{#end}`, which is valid within the `for` directive. If the loop iteration is the first one, the part of the template between `{#first}` and `{#end}` will be processed, otherwise not.

    template: "Issues:{#for issues} {#first}*{#end}{#value}{#first}*{#end}{#end}"
    vars:     { issues: ['#87', '#101'] }
    output:   "Issues: *#87* #101"

If `for` directives are nested, this directive can be executed in the context of the outer loop by prefixing it with `../`, for example: `{../#index}`. The prefix `../` can be chained for deeply nested loops.

### NotFirst

An block directive `{#notfirst}...{#end}`, which is valid within the `for` directive. If the loop iteration is not the first one, the part of the template between `{#notfirst}` and `{#end}` will be processed, otherwise not.

    template: "Issues: {#for issues}{#notfirst}, {#end}{#value}{#end}"
    vars:     { issues: ['#87', '#101'] }
    output:   "Issues: #87, #101"

If `for` directives are nested, this directive can be executed in the context of the outer loop by prefixing it with `../`, for example: `{../#index}`. The prefix `../` can be chained for deeply nested loops.

### Middle

An block directive `{#middle}...{#end}`, which is valid within the `for` directive. If the loop iteration is neither the first one nor the last one, the part of the template between `{#middle}` and `{#end}` will be processed, otherwise not.

    template: "Issues: {#for issues}{#middle}, {#end}{#notfirst}{#last} and {#end}{#end}{#index}{#value}{#end}"
    vars:     { issues: ['#87', '#95', '#101'] }
    output:   "Issues: #87, #95 and #101"

If `for` directives are nested, this directive can be executed in the context of the outer loop by prefixing it with `../`, for example: `{../#index}`. The prefix `../` can be chained for deeply nested loops.

### NotLast

An block directive `{#notlast}...{#end}`, which is valid within the `for` directive. If the loop iteration is not the last one, the part of the template between `{#notlast}` and `{#end}` will be processed, otherwise not.

    template: "Issues: {#for issues}{#value}{#notlast}, {#end}{#end}"
    vars:     { issues: ['#87', '#101'] }
    output:   "Issues: #87, #101"

If `for` directives are nested, this directive can be executed in the context of the outer loop by prefixing it with `../`, for example: `{../#index}`. The prefix `../` can be chained for deeply nested loops.

### Last

An block directive `{#last}...{#end}`, which is valid within the `for` directive. If the loop iteration is the last one, the part of the template between `{#last}` and `{#end}` will be processed, otherwise not.

    template: "Issues:{#for issues} {#last}*{#end}{#value}{#last}*{#end}{#end}"
    vars:     { issues: ['#87', '#101'] }
    output:   "Issues: #87 *#101*"

If `for` directives are nested, this directive can be executed in the context of the outer loop by prefixing it with `../`, for example: `{../#index}`. The prefix `../` can be chained for deeply nested loops.

### End

An trailing directive - `{#end}` - to end block directives `if`, `unless`, `for`, `first`, `notfirst`, `middle`, `notlast` and `last`. See the directives above for examples.

## API

The following functions and types are exported:

### parse_template(source string) !Template

Parses a template string and returns a `Template` instance.

```go
import prantlf.template { parse_template }

template := parse_template('# {title}')!
```

### Template.generate(vars TemplateData) string

Generates a string from the template using the `vars` represented by a `TemplateData` implementation.

```go
import prantlf.template { parse_template }

template := parse_template('# {title}')!
output := template.generate({
  'title': 'Overview'
})
// output: # Overview
```

### parse_replacer(source string) !Replacer

Parses a template with a reduced syntax - only variables are supported. Returns a `Replacer` instance.

```go
import prantlf.template { parse_replacer }

template := parse_replacer('# {title}')!
```

### parse_replacer_opt(source string, opts &ReplacerOpts) !Replacer

Parses a template with a reduced syntax - only variables are supported. Returns a `Replacer` instance. Allows restricting the variable names for the replaceable placeholders using `ReplacerOpts`:

| Field     | Type       | Default | Description                                |
|:----------|:-----------|:--------|:-------------------------------------------|
| `vars`    | `[]string` | `[]`    | list of variable names                     |
| `exclude` | `bool`     | `false` | if the listed variables should be excluded |

If the `vars` array isn't empty, only the listed variables will be considered for replacing. Other variable placeholders will be considered just text literals:

```go
import prantlf.template { parse_replacer }

template := parse_replacer('# {title} ({date})', ReplacerOpts{
  vars: ['title']
})!
output := template.replace({
  'title': 'Overview'
})
// output: # Overview ({date})
```

If the `exclude` flag is set, the variable list will be treated the other way round - the listed variables will be considered just text literals and the others will be replaceable:

```go
import prantlf.template { ReplacerOpts, parse_replacer_opt }

template := parse_replacer_opt('# {title} ({date})', ReplacerOpts{
  vars: ['date']
  exclude: true
})!
output := template.replace({
  'title': 'Overview'
})
// output: # Overview ({date})
```

### Replacer.replace(vars TemplateData) string

Replaces variable placeholders in a template using the `vars` represented by a `TemplateData` implementation.

```go
import prantlf.template { parse_template }

template := parse_replacer('# {title}')!
output := template.replace({
  'title': 'Overview'
})
// output: # Overview
```

See the implementation of `TemplateData` for a map `string` to `string` in [abstractions] below.

## Abstractions

Instead of accepting a string map only, any data can be accepted, as long is it implements the `TemplateData` interface:

```go
interface TemplateData {
  has(name string) bool
  get_one(name string) string
  get_more(name string) []string
}
```

For [example](src/string_map_test.v), a map `string` to `string`:

```go
fn (m map[string]string) has(name string) bool {
  return name in m
}

fn (m map[string]string) get_one(name string) string {
  return m[name]
}

fn (m map[string]string) get_more(name string) []string {
  return if name in m {
    [m[name]]
  } else {
    []
  }
}
```

For [example](src/string_array_map_test.v), a map `string` to `[]string`:

```go
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
```

For [example](src/two_maps_test.v), a struct `MapData` with separate maps `string` to `string` and `string` to `[]string`:

```go
struct MapData {
  singles map[string]string
  arrays map[string][]string
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
```

For [example](src/struct_test.v), a struct `Data` with fields of types `string` and `[]string` instead of a map:

```go
struct Data {
	description string
	issues []string
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
```

## Contributing

In lieu of a formal styleguide, take care to maintain the existing coding style. Lint and test your code.

## License

Copyright (c) 2023-2025 Ferdinand Prantl

Licensed under the MIT license.

[VPM]: https://vpm.vlang.io/packages/prantlf.template
[abstractions]: #abstractions
