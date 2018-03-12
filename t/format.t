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

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'string',
        format => 'ipv4'
    });
    ok $schema.validate('127.0.0.1'), 'Valid IPv4 accepted';
    nok $schema.validate('127.0.0'), 'Partial IPv4 rejected';
    nok $schema.validate('632.23.53.12'), 'Invalid IPv4 rejected';
    $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'string',
        format => 'ipv6'
    });
    ok $schema.validate('1080:0:0:0:8:800:200C:417A'), 'Valid IPv6 accepted';
}

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'string',
        format => 'uri'
    });
    ok $schema.validate('foo://example.com:8042'), 'Valid URI accepted';
    nok $schema.validate('foo'), 'Invalid URI rejected';
}

{
    my $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'string',
        format => 'json-pointer'
    });
    ok $schema.validate('/foo/bar'), 'Valid JSON Pointer accepted';
    nok $schema.validate('foo'), 'Invalid JSON Pointer rejected';
    $schema = OpenAPI::Schema::Validate.new(schema => {
        type => 'string',
        format => 'relative-json-pointer'
    });
    ok $schema.validate('1/foo/bar'), 'Valid relative JSON Pointer accepted';
    nok $schema.validate('foo'), 'Invalid relative JSON Pointer rejected';
}

done-testing;
