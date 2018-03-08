class X::OpenAPI::Schema::Validate::BadSchema is Exception {
    has $.path;
    has $.reason;
    method message() {
        "Schema invalid at $!path: $!reason"
    }
}
class X::OpenAPI::Schema::Validate::Failed is Exception {
    has $.path;
    has $.reason;
    method message() {
        "Validation failed for $!path: $!reason"
    }
}

my subset StrictPositiveInt of Int where * > 0;

class OpenAPI::Schema::Validate {
    # We'll turn a schema into a tree of Check objects that enforce the
    # various bits of validation.
    my role Check {
        # Path is used for error reporting.
        has $.path;

        # Does the checking; throws if there's a problem.
        method check($value --> Nil) { ... }
    }

    # Check implement the various properties. Per the RFC draft:
    #   Validation keywords typically operate independent of each other,
    #   without affecting each other.
    # Thus we implement them in that way for now, though it does lead to
    # some duplicate type checks.

    my class AllCheck does Check {
        has @.checks;
        method check($value --> Nil) {
            .check($value) for @!checks;
        }
    }

    my class StringCheck does Check {
        method check($value --> Nil) {
            unless $value ~~ Str && $value.defined {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason('Not a string');
            }
        }
    }

    my class NumberCheck does Check {
        method check($value --> Nil) {
            unless $value ~~ Real && $value.defined {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason('Not a number');
            }
        }
    }

    my class IntegerCheck does Check {
        method check($value --> Nil) {
            unless $value ~~ Int && $value.defined {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason('Not an integer');
            }
        }
    }

    my class BooleanCheck does Check {
        method check($value --> Nil) {
            unless $value ~~ Bool && $value.defined {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason('Not a boolean');
            }
        }
    }

    my class ArrayCheck does Check {
        method check($value --> Nil) {
            unless $value ~~ Positional && $value.defined {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason('Not an array');
            }
        }
    }

    my class ObjectCheck does Check {
        method check($value --> Nil) {
            unless $value ~~ Associative && $value.defined {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason('Not an object');
            }
        }
    }

    my class MultipleOfCheck does Check {
        has UInt $.multi;
        method check($value --> Nil) {
            if $value ~~ Real {
                unless $value %% $!multi {
                    die X::OpenAPI::Schema::Validate::Failed.new:
                        :$!path, :reason("Number is not multiple of $!multi");
                }
            }
        }
    }

    my class MinLengthCheck does Check {
        has Int $.min;
        method check($value --> Nil) {
            if $value ~~ Str && $value.defined && $value.codes < $!min {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason("String less than $!min codepoints");
            }
        }
    }

    my class MaxLengthCheck does Check {
        has Int $.max;
        method check($value --> Nil) {
            if $value ~~ Str && $value.defined && $value.codes > $!max {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason("String more than $!max codepoints");
            }
        }
    }

    my class MaximumCheck does Check {
        has Int $.max;
        has Bool $.exclusive;
        method check($value --> Nil) {
            if $value ~~ Real && (!$!exclusive && $value > $!max || $!exclusive && $value >= $!max) {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason("Number is more than $!max");
            }
        }
    }

    my class MinimumCheck does Check {
        has Int $.min;
        has Bool $.exclusive;
        method check($value --> Nil) {
            if $value ~~ Real && (!$!exclusive && $value < $!min || $!exclusive && $value <= $!min) {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason("Number is less than $!min");
            }
        }
    }

    my class MinItemsCheck does Check {
        has Int $.min;
        method check($value --> Nil) {
            if $value ~~ Positional && $value.elems < $!min {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason("Array has less than $!min elements");
            }
        }
    }

    my class MaxItemsCheck does Check {
        has Int $.max;
        method check($value --> Nil) {
            if $value ~~ Positional && $value.elems > $!max {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason("Array has less than $!max elements");
            }
        }
    }

    my class UniqueItemsCheck does Check {
        method check($value --> Nil) {
            if $value ~~ Positional && $value.elems != $value.unique(with => &[eqv]).elems {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason("Array has duplicated values");
            }
        }
    }

    my class ItemsCheck does Check {
        has Check $.items-check;
        method check($value --> Nil) {
            if $value ~~ Positional {
                $value.map({ $!items-check.check($_) });
            }
        }
    }

    my class MinPropertiesCheck does Check {
        has Int $.min;
        method check($value --> Nil) {
            if $value ~~ Associative && $value.values < $!min {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason("Object has less than $!min properties");
            }
        }
    }

    my class MaxPropertiesCheck does Check {
        has Int $.max;
        method check($value --> Nil) {
            if $value ~~ Associative && $value.values > $!max {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason("Object has more than $!max properties");
            }
        }
    }

    my class RequiredCheck does Check {
        has Str @.prop;
        method check($value --> Nil) {
            if $value ~~ Associative && not [&&] $value{@!prop}.map(*.defined) {
                die X::OpenAPI::Schema::Validate::Failed.new:
                    :$!path, :reason("Object does not have required property");
            }
        }
    }

    has Check $!check;

    submethod BUILD(:%schema! --> Nil) {
        $!check = check-for('root', %schema);
    }

    sub check-for($path, %schema) {
        my @checks;

        with %schema<type> {
            when Str {
                when 'string' {
                    push @checks, StringCheck.new(:$path);
                }
                when 'number' {
                    push @checks, NumberCheck.new(:$path);
                }
                when 'integer' {
                    push @checks, IntegerCheck.new(:$path);
                }
                when 'boolean' {
                    push @checks, BooleanCheck.new(:$path);
                }
                when 'array' {
                    with %schema<items> {
                        push @checks, ArrayCheck.new(:$path);
                    } else {
                        die X::OpenAPI::Schema::Validate::BadSchema.new:
                            :$path, :reason("Property items must be specified for array type");
                    }
                }
                when 'object' {
                    push @checks, ObjectCheck.new(:$path);
                }
                default {
                    die X::OpenAPI::Schema::Validate::BadSchema.new:
                        :$path, :reason("Unrecognized type '$_'");
                }
            }
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                    :$path, :reason("The type property must be a string");
            }
        }

        with %schema<multipleOf> {
            when StrictPositiveInt {
                push @checks, MultipleOfCheck.new(:$path, multi => $_);
            }
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                    :$path, :reason("The multipleOf property must be a non-negative integer");
            }
        }

        with %schema<maximum> {
            when Int {
                push @checks, MaximumCheck.new(:$path, max => $_,
                    exclusive => %schema<exclusiveMaximum> // False);
            }
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                    :$path, :reason("The maximum property must be an integer");
            }
        }

        with %schema<exclusiveMaximum> {
            when $_ !~~ Bool {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                     :$path, :reason("The exclusiveMaximum property must be a boolean");
            }
        }

        with %schema<minimum> {
            when Int {
                push @checks, MinimumCheck.new(:$path, min => $_,
                    exclusive => %schema<exclusiveMinimum> // False);
            }
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                     :$path, :reason("The minimum property must be an integer");
            }
        }

        with %schema<exclusiveMinimum> {
            when $_ !~~ Bool {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                     :$path, :reason("The exclusiveMinimum property must be a boolean");
            }
        }

        with %schema<minLength> {
            when UInt {
                push @checks, MinLengthCheck.new(:$path, :min($_));
            }
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                    :$path, :reason("The minLength property must be a non-negative integer");
            }
        }

        with %schema<maxLength> {
            when UInt {
                push @checks, MaxLengthCheck.new(:$path, :max($_));
            }
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                    :$path, :reason("The maxLength property must be a non-negative integer");
            }
        }

        with %schema<minItems> {
            when UInt {
                push @checks, MinItemsCheck.new(:$path, :min($_));
            }
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                    :$path, :reason("The minItems property must be a non-negative integer");
            }
        }

        with %schema<maxItems> {
            when UInt {
                push @checks, MaxItemsCheck.new(:$path, :max($_));
            }
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                    :$path, :reason("The maxItems property must be a non-negative integer");
            }
        }

        with %schema<uniqueItems> {
            when $_ === True {
                push @checks, UniqueItemsCheck.new(:$path);
            }
            when  $_ === False {}
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                    :$path, :reason("The uniqueItems property must be a boolean");
            }
        }

        with %schema<items> {
            when Associative {
                my $items-check = check-for($path ~ '/items', %$_);
                push @checks, ItemsCheck.new(:$path, :$items-check);
            }
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                    :$path, :reason("The items property must be an object");
            }
        }

        with %schema<minProperties> {
            when UInt {
                push @checks, MinPropertiesCheck.new(:$path, :min($_));
            }
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                    :$path, :reason("The minProperties property must be a non-negative integer");
            }
        }

        with %schema<maxProperties> {
            when UInt {
                push @checks, MaxPropertiesCheck.new(:$path, :max($_));
            }
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                    :$path, :reason("The maxProperties property must be a non-negative integer");
            }
        }

        with %schema<required> {
            when Positional && [&&] .map(* ~~ Str) && .elems == .unique.elems {
                push @checks, RequiredCheck.new(:$path, prop => @$_);
            }
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                    :$path, :reason("The required property must be a Positional of unique Str");
            }
        }

        return @checks == 1 ?? @checks[0] !! AllCheck.new(:@checks);
    }

    method validate($value --> True) {
        $!check.check($value);
        CATCH {
            when X::OpenAPI::Schema::Validate::Failed {
                fail $_;
            }
        }
    }
}
