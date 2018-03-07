use OpenAPI::Schema::Validate;
use Test;

throws-like
    { OpenAPI::Schema::Validate.new(schema => { type => 42 }) },
    X::OpenAPI::Schema::Validate::BadSchema,
    'Having type property be an integer is refused';
throws-like
    { OpenAPI::Schema::Validate.new(schema => { type => 'zombie' }) },
    X::OpenAPI::Schema::Validate::BadSchema,
    'Having type property be an invalid type is refused';

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'string'
    });
    ok $schema.validate('hello'), 'Simple string validation accepts a string';
    nok $schema.validate(42), 'Simple string validation rejects an integer';
    nok $schema.validate(Any), 'Simple string validation rejects a type object';
}

done-testing;
