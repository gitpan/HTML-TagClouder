# $Id: /local/perl/HTML-TagClouder/trunk/lib/HTML/TagClouder.pm 11406 2007-05-23T10:17:09.023599Z daisuke  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package HTML::TagClouder;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Class::C3;
use Class::Inspector;
use UNIVERSAL::isa;
use UNIVERSAL::require;
use overload 
    '""' => \&render,
    fallback => 1
;
INIT { Class::C3::initialize() }
use HTML::TagClouder::Tag;

our $VERSION = 0.01;

__PACKAGE__->mk_accessors($_) for 
    qw(renderer collection processor is_processed)
;

sub new
{
    my $class = shift;
    my $self  = bless {}, $class;
    $self->setup(@_);

    return $self;
}

sub setup
{
    my $self = shift;
    my %args = @_;
    $self->is_processed(0);

    my $render_class = $self->_load_module( $args{render_class} || 'HTML::TagClouder::Render::TT');
    $self->renderer( $render_class->new(%{ $args{render_class_args} || {} }, cloud => $self) );

    my $collection_class = $self->_load_module( $args{collection_class} || 'HTML::TagClouder::Collection::Simple' );
    $self->collection( $collection_class->new(%{ $args{collection_class_args} || {} }, cloud => $self) );

    my $processor_class = $self->_load_module( $args{processor_class} || 'HTML::TagClouder::Processor::Simple' );
    $self->processor( $processor_class->new(%{ $args{processor_class} || {} }) );

}

sub _load_module
{
    my $self = shift;
    my $class = shift;
    if (! Class::Inspector->loaded( $class )) {
        $class->require or die "Could not require $class: $@";
    }
    return $class;
}

sub process
{
    my $self = shift;
    $self->processor->process( $self );
    $self->is_processed(1);
}

sub render
{
    my $self = shift;

    if (! $self->is_processed) {
        $self->process;
    }

    $self->renderer()->render($self);
}

sub add
{
    my $self = shift;
    my $tag;
    if (ref $_[0] && $_[0]->isa('HTML::TagClouder::Tag')) {
        $tag = shift;
    } else {
        my ($label, $uri, $count, $timestamp) = @_;
        $tag = HTML::TagClouder::Tag->new(
            label => $label,
            count => $count,
            uri   => $uri,
            timestamp => $timestamp || now()
        );
    }
    $self->collection->add($tag);
}

1;

__END__

=head1 NAME

HTML::TagClouder - Yet Another TagCloud Generator

=head1 SYNOPSIS

  use HTML::TagClouder;

  # All arguments are optional!
  my $cloud = HTML::TagClouder->new(
    collection_class      => 'HTML::TagClouder::Collection::Simple',
    collection_class_args => { ... },
    processor_class       => 'HTML::TagClouder::Collection::Processor::Simple',
    processor_class_args  => { ... }, 
    render_class          => 'HTML::TagClouder::Render::TT',
    render_class_args     => {
      tt_args => {
        INCLUDE_PATH => '/path/to/templates'
      }
    }
  );
  $cloud->add(HTML::TagClouder::Tag->new($label, $uri, $count, $timestamp));
  $cloud->add($label, $uri, $count, $timestamp);

  $cloud->render;

  # or in your template
  [% cloud %]

=head1 DESCRIPTION

*WARNING* Alpha software! I mean it!

HTML::TagClouder is just another take on generating Tagclouds. I built it for
particular purpose, and so it may not do everything that you want either,
but it's supposed to be designed with flexibility in mind, especially the
presentation layer.

The basic concept is that there's a build-up phase via ->add, then there's the
data process phase right before rendering, and finally the rendering. These
should be separate, and configurable.

=head1 CAVEATS

The interface allows a timestamp argument, but it does nothing at this moment.
I don't plan on using it for a while, so if you want it, patches welcome.

The above also means that currently there's no way to change the color of the
tags. Of course, you can always create your own subclasses that does so.

=head1 METHODS

=head2 new %args

new() constructs a new HTML::TagClouder instance, and may take the following 
parameters. If a parameter is omitted, some sane default will be provided.

=over 4

=item collection_class

The HTML::TagClouder::Collection class name that will hold the tags while
the cloud is being built

=item collection_class_args

A hashref of arguments to be passed to the collection class' constructor.

=item processor_class

The HTML::TagClouder::Processor class name that will be used to normalize
the tags. This is responsible for calculating various attributes that will
be used when rendering the tag cloud

=item processor_class_args

A hashref of arguments to be passed to the processor class' constructor.

=item render_class

The HTML::TagClouder::Render class name that will be used to render the
tag cloud for presentation

=item render_class_args

A hashref of arguments to be passed to the render class' constructor.

=back

=head2 setup

Sets up the object.

=head2 add $tag

=head2 add $label, $uri, $count, $timestamp

Adds a new tag. Accepts either the parameters passed to HTML::TagClouder::Tag
constructor, or a HTML::TagClouder::Tag instance

=head2 process

Processes the tags. This method will be automatically called from render()

=head2 render

Renders the tag cloud and returns the html.

=head1 SEE ALSO

L<HTML::TagCloud::Extended|HTML::TagCloud::Extended>, L<HTML::TagCloud>

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut