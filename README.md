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
