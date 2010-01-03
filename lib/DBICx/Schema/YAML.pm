package DBICx::Schema::YAML;

use strict;
use warnings;

use YAML::Tiny  qw/Load/;
use File::Slurp qw/slurp/;

sub import {
    my $from = shift;
    my $to = caller;
    no strict "refs";
    *{"$to\::load_yaml_schema"} = \&{"$from\::load_yaml_schema"};
}

sub load_yaml_schema {
    my $pkg = shift;
    my $sch = Load scalar slurp do {
        no strict "refs";
        \*{"$pkg\::DATA"}
    };
    my $res = "$pkg\::Result";
    (my $pm = $pkg) =~ s!::!/!g;

    require DBIx::Class;
    require DBIx::Class::Schema;
    {
        no strict "refs";
        push @{"$pkg\::ISA"}, "DBIx::Class::Schema";
    }

    for my $tab (@$sch) {
        keys %$tab;
        my ($name, $defn) = each %$tab;
        my $class = "$res\::$name";
        {
            no strict "refs";
            $INC{"$pm/Result/$name.pm"} = __FILE__;
            push @{"$class\::ISA"}, "DBIx::Class";
        }
    }

    for my $tab (@$sch) {
        keys %$tab;
        my ($name, $defn) = each %$tab;
        my $class = "$res\::$name";

        $class->load_components("Core");
        $class->table("\L$name");
        
        for my $call (@$defn) {
            my ($meth, $args) = each %$call;
            ref $args or $args = [$args];
            $class->$meth(@$args);
        }

        Class::C3->reinitialize;
        $pkg->register_class($name, $class);
    }

}

1;