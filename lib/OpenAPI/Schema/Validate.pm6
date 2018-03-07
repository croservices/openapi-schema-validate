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
            unless $value ~~ Rat && $value.defined {
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
                    push @checks, ArrayCheck.new(:$path);
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

        with %schema<minLength> {
            when Int {
                push @checks, MinLengthCheck.new(:$path, :min($_));
            }
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                    :$path, :reason("The minLength property must be an integer");
            }
        }

        with %schema<maxLength> {
            when Int {
                push @checks, MaxLengthCheck.new(:$path, :max($_));
            }
            default {
                die X::OpenAPI::Schema::Validate::BadSchema.new:
                    :$path, :reason("The maxLength property must be an integer");
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
