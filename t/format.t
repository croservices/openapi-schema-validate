use OpenAPI::Schema::Validate;
use Test;

throws-like
    { OpenAPI::Schema::Validate.new(schema => { type => 'integer', format => 'int128' }) },
    X::OpenAPI::Schema::Validate::BadSchema,
    'Non-existent format is a bad schema';

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'integer',
        format => 'int32'
    });
    ok $schema.validate(5), 'Integer within range of format accepted';
    nok $schema.validate(21474836470), 'Integer below lower bound of range rejected';
    nok $schema.validate(-21474836470), 'Integer exceeding upper bound of range rejected';
}

done-testing;
