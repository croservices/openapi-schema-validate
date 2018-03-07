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
throws-like
    { OpenAPI::Schema::Validate.new(schema => { uniqueItems => 'yes' }) },
    X::OpenAPI::Schema::Validate::BadSchema,
    'Having uniqueItems property be an non-boolean is refused (Str)';

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

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'array',
        uniqueItems => False
    });
    ok $schema.validate([1, 1]), 'Array with duplicates accepted';
    $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'array',
        uniqueItems => True
    });
    ok $schema.validate([1, 2]), 'Array of integers without duplicates accepted';
    ok $schema.validate([1.5, 1.6]), 'Array of numbers without duplicates accepted';
    ok $schema.validate(['Lines', 'Heights']), 'Array of strings without duplicates accepted';
    ok $schema.validate([{a => 1, b => 2}, {c => 1, a => 1}]), 'Array of objects without duplicates accepted';
    nok $schema.validate([{a => 1, b => 2}, {a => 1, b => 2}]), 'Array of objects with duplicates rejected';
}

done-testing;
