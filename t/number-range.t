use OpenAPI::Schema::Validate;
use Test;

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'integer',
        multipleOf => 5
    });
    ok $schema.validate(25), '25 is a multiple of 5';
    nok $schema.validate(6), '6 is not a multiple of 5';
}

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'number',
        maximum => 5
    });
    nok $schema.validate(10), '10 is more than 5';
    ok $schema.validate(5), '5 is accepted as exclusive is set to False by default';
    $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'number',
        maximum => 5,
        exclusiveMaximum => True
    });
    nok $schema.validate(5), '5 is rejected as exclusiveMaximum is set';
    nok $schema.validate('string'), 'string is rejected';
}

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'number',
        minimum => 5
    });
    nok $schema.validate(1), '1 is less than 5';
    ok $schema.validate(5), '5 is accepted as exclusive is set to False by default';
    $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'number',
        minimum => 5,
        exclusiveMinimum => True
    });
    nok $schema.validate(5), '5 is rejected as exclusiveMinimum is set';
    nok $schema.validate('string'), 'string is rejected';
}

done-testing;
