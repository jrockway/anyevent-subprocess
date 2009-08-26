package AnyEvent::Subprocess::Role::WithDelegates::Manager;
use strict;
use warnings;

use Carp qw(cluck confess);

use Sub::Exporter -setup => {
    exports => ['register_delegate', 'build_delegate'],
};

my %builder_map;

sub register_delegate {
    my ($name, $builder) = @_;
    cluck "Overwriting existing delegate '$name' with '$builder'"
      if exists $builder_map{$name};

    $builder_map{$name} = $builder;
    return;
}

sub lookup_delegate {
    my ($name) = @_;
    confess "No delegate named '$name' registered"
      unless exists $builder_map{$name};

    return $builder_map{$name};
}

sub build_delegate {
    my ($spec) = @_;

    my $builder;
    my @args;

    if(ref $spec){
        my ($k, $v);
        # perl sucks
        eval { ($k, $v) = %$spec } ||
        eval { ($k, $v) = @$spec } ||
        confess 'Invalid data!';

        $builder = lookup_delegate($k);
        @args = $v;
    }
    else {
        $builder = lookup_delegate($spec);
    }

    if( ref $builder && ref $builder eq 'CODE' ) {
        return $builder->(@args);
    }
    return $builder->new(@args);
}

1;
