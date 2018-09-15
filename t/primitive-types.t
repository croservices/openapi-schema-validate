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
throws-like
    { OpenAPI::Schema::Validate.new(schema => { type => 'null' }) },
    X::OpenAPI::Schema::Validate::BadSchema,
    'Having type property be null is refused';

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'string'
    });
    ok $schema.validate('hello'), 'Simple string validation accepts a string';
    nok $schema.validate(42), 'Simple string validation rejects an integer';
    nok $schema.validate(Str), 'Simple string validation rejects a type object';
}

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'number'
    });
    ok $schema.validate(42.0), 'Simple number validation accepts a Rat';
    ok $schema.validate(42), 'Simple number validation accepts an Int';
    ok $schema.validate(42.5e2), 'Simple number validation accepts a Num';
    nok $schema.validate('hello'), 'Simple number validation rejects a string';
    nok $schema.validate(Any), 'Simple number validation rejects a type object';

}

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'integer'
    });
    ok $schema.validate(42), 'Simple integer validation accepts an integer';
    nok $schema.validate(42.0), 'Simple integer validation rejects a Rat';
    nok $schema.validate('hello'), 'Simple integer validation rejects a string';
    nok $schema.validate(Any), 'Simple integer validation rejects a type object';
}

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'boolean'
    });
    ok $schema.validate(True), 'Simple boolean validation accepts an boolean';
    nok $schema.validate('hello'), 'Simple boolean validation rejects a string';
    nok $schema.validate(Bool), 'Simple boolean validation rejects a type object';
}

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'array',
        items => { type => 'integer' }
    });
    ok $schema.validate([42]), 'Simple array validation accepts a Positional';
    ok $schema.validate(list), 'Simple array validation accepts an empty list';
    nok $schema.validate('hello'), 'Simple array validation rejects a string';
    nok $schema.validate(Positional), 'Simple array validation rejects a type object';
}

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'object'
    });
    ok $schema.validate({foo => 'bar'}), 'Simple object validation accepts a Hash';
    nok $schema.validate('hello'), 'Simple object validation rejects a string';
    nok $schema.validate(Hash), 'Simple object validation rejects a type object';
}

throws-like { OpenAPI::Schema::Validate.new(schema => { enum => 42 }) },
    X::OpenAPI::Schema::Validate::BadSchema,
    'Having enum property be an integer is refused';

{
    my $schema = OpenAPI::Schema::Validate.new(schema => { enum => (1, 'String', (1, 2), { foo => 'bar' }) });
    ok $schema.validate(1), 'Correct integer is accepted';
    nok $schema.validate(2), 'Incorrect integer is rejected';
    ok $schema.validate('String'), 'Correct string is accepted';
    nok $schema.validate('Strign'), 'Incorrect string is rejected';
    nok $schema.validate((1, 'String').List), 'Equal enum is rejected';
    ok $schema.validate((1, 2).List), 'Correct array is accepted';
    ok $schema.validate((foo => 'bar').Hash), 'Correct object is accepted';
}

done-testing;
