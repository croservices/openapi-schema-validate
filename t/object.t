use OpenAPI::Schema::Validate;
use Test;

throws-like
    { OpenAPI::Schema::Validate.new(schema => { minProperties => 2.5 }) },
    X::OpenAPI::Schema::Validate::BadSchema,
    'Having minProperties property be an non-integer is refused (Rat)';
throws-like
    { OpenAPI::Schema::Validate.new(schema => { maxProperties => '4' }) },
    X::OpenAPI::Schema::Validate::BadSchema,
    'Having maxProperties property be an non-integer is refused (Str)';

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'object',
        minProperties => 2,
        maxProperties => 4
    });
    nok $schema.validate({a => 1}), 'Object below minimum properties number rejected';
    ok $schema.validate({a => 1, b => 2}), 'Object of minimum properties number rejected';
    ok $schema.validate({a => 1, b => 2, c => 3, d => 4}), 'Object of maximum properties number accepted';
    nok $schema.validate({a => 1, b => 2, c => 3, d => 4, e => 5}), 'Object over maximum properties number rejected';
    nok $schema.validate('string'), 'String instead of array rejected';
    $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'object',
        required => <a b>
    });
    nok $schema.validate({a => 1}), 'Object without required attribute rejected';
    ok $schema.validate({a => 1, b => 2}), 'Object with all required attributes accepted';
    ok $schema.validate({a => 1, b => 2, c => 3}), 'Object that has additional attributes besides required accepted';
}

done-testing;
