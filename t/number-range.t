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

done-testing;
