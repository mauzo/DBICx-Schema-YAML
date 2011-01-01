package DBICx::Schema::YAML;

use strict;
use warnings;

use version; our $VERSION = "0.02";

use YAML::XS            qw/Load/;
use File::Slurp         qw/slurp/;
use Scalar::Util        qw/reftype/;

sub aref ($) {
     ref $_[0] && reftype $_[0] eq "ARRAY"
        ? $_[0] : [ $_[0] ];
}

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

    require DBIx::Class;
    require DBIx::Class::Schema;
    $pkg->inject_base($pkg, "DBIx::Class::Schema");
    Class::C3->reinitialize;

    my $global = $sch->{global};
    for my $call (@$global) {
        my ($meth, $args) = each %$call;
        $args = aref $args;
        $pkg->$meth(@$args);
    }

    my $components  = $sch->{components};
    my $tabs        = $sch->{tables};

    (my $path = $pkg) =~ s!::!/!g;
    local @INC = (sub { 
        my ($s, $pm) = @_;
        my ($name) = $pm =~ m{^$path/(.*)\.pm$}
            or return;
        my $class = "$pkg\::$name";

        {
            no strict "refs";
            push @{"$class\::ISA"}, "DBIx::Class";
        }
        Class::C3->reinitialize;

        $class->load_components(qw/Core/, @$components);
        $class->table("\L$name");
    
        my $defn = $tabs->{$name};
        for my $call (@$defn) {
            my ($meth, $args) = each %$call;
            $args= aref $args;
            $class->$meth(@$args);
        }

        # see if there's a real .pm somewhere
        local @INC = grep !ref || $_ != $_[0], @INC;
        # do doesn't check %INC, so will happily recurse
        eval { do $pm; $@ and die $@; 1; } or die "$pm failed: $@";
        
        open my $PM, "<", \"1;";
        return $PM;
    }, @INC);

    $pkg->load_classes([keys %$tabs]);
}

1;
