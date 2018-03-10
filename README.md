# OpenAPI::Schema::Validate

Validates a value or data structure (of hashes and arrays) against an OpenAPI
schema definition.

## Synopsis

    use OpenAPI::Schema::Validate;

    # A schema should have been deserialized into a hash at the top level.
    # It will have been if you use this with OpenAPI::Model.
    my $schema = OpenAPI::Schema::Validate.new(
        schema => from-json '{ "type": "string" }'
    );

    # Validate it and use the result as a boolean.
    say so $schema.validate("foo");     # True
    say so $schema.validate(42);        # False
    say so $schema.validate(Str);       # False

    # Validate it in sink context; Failure throws if there's a validation
    # error; catch it and us the `reason` property for diagnostics.
    for "foo", 42, Str -> $test {
        $schema.validate($est);
        say "$test.perl() is valid";
        CATCH {
            when X::OpenAPI::Schema::Validate::Failed {
                say "$test.perl() is not valid at $_.path(): $_.reason()";
            }
        }
    }

## Methods

### validate($value, :$read, :$write)

Performs validation of the passed value. Returns `True` if the validation is
successful, and a `Failure` if it is unsuccessful. This allows use in both a
boolean context, or a sink context in which case the failiure will be sunk and
an exception of type `X::OpenAPI::Schema::Validate::Failed` thrown.

OpenAPI schemas may contain the `readOnly` and `writeOnly` properties. These
are used for properties that may only show up in responses and requets
respectively. Thus, pass `:read` when validating a response, and `:write` when
validating a request, in order to allow the appropriate properties to pass (or
fail) validation. If neither of `:read` and `:write` are passed then both
`readOnly` and `writeOnly` will always fail.
