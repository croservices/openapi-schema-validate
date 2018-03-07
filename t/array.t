use OpenAPI::Schema::Validate;
use Test;

throws-like
    { OpenAPI::Schema::Validate.new(schema => { minItems => 4.5 }) },
    X::OpenAPI::Schema::Validate::BadSchema,
    'Having minItems property be an non-integer is refused (Rat)';
throws-like
    { OpenAPI::Schema::Validate.new(schema => { maxItems => '4' }) },
    X::OpenAPI::Schema::Validate::BadSchema,
    'Having maxItems property be an non-integer is refused (Str)';

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'array',
        minItems => 2,
        maxItems => 4
    });
    nok $schema.validate([1]), 'Array below minimum length rejected';
    ok $schema.validate([1,2]), 'Array of minimum length rejected';
    ok $schema.validate([1,2,3,4]), 'Array of maximum length accepted';
    nok $schema.validate([1,2,3,4,5]), 'Array over maximum length rejected';
    nok $schema.validate('string'), 'String instead of array rejected';
}

done-testing;
