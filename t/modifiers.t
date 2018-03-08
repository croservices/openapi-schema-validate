use OpenAPI::Schema::Validate;
use Test;

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        allOf => [
            { type => 'object' },
            { required => ['type'] }
        ]
    });
    ok $schema.validate({ type => 'one' }), 'Object that satisfies all checks accepted';
    throws-like { $schema.validate({ typee => 'one' }) },
    X::OpenAPI::Schema::Validate::Failed, message => /'allOf/1'/,
    'Throws when one of checks is failed in allOf';
}

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        anyOf => [
            { type => 'object' },
            { type => 'string' }
        ]
    });
    ok $schema.validate({}), 'anyOf of object and string accepted object';
    ok $schema.validate('string'), 'anyOf of object and string accepted string';
    nok $schema.validate(1), 'anyOf of object and string rejected integer';
}

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        oneOf => [
            { type => 'string'  },
            { type => 'string'  },
            { type => 'integer' }
        ]
    });
    ok $schema.validate(1), 'oneOf accepted single-matched integer';
    nok $schema.validate('string'), 'oneOf rejected string matched twice';
}

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        not => {
            type => 'string'
        }
    });
    nok $schema.validate('hello'), 'not string rejected string';
    ok $schema.validate(1), 'not string accepted integer';
    ok $schema.validate({}), 'not string accepted object';
}

done-testing;
