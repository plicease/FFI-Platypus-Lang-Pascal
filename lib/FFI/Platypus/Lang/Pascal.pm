package FFI::Platypus::Lang::Pascal;

use strict;
use warnings;
use Carp qw( croak );
use FFI::Platypus;

our $VERSION = '0.01';

=head1 NAME

FFI::Platypus::Lang::Pascal - Documentation and tools for using Platypus with
the Free Pascal programming language

=head1 SYNOPSIS

# TODO

=head1 DESCRIPTION

This modules provides native types and demangling for the Free Pascal
Programming language when used with L<FFI::Platypus>.

=head1 CAVEATS

I've been experimenting with Free Pascal 2.6.0 while working on this module.

=head2 name mangling

TODO

=head1 METHODS

Generally you will not use this class directly, instead interacting with
the L<FFI::Platypus> instance.  However, the public methods used by
Platypus are documented here.

=head2 native_type_map

 my $hashref = FFI::Platypus::Lang::Pascal->native_type_map;

This returns a hash reference containing the native aliases for the
Free Pascal programming languages.  That is the keys are native C++
types and the values are libffi native types.

Types are in camel case.  For example use C<ShortInt>, not C<Shortint>
or C<SHORTINT>.

=cut

sub native_type_map
{
  {
    # Integer Types
    'Byte'     => 'uint8',
    'ShortInt' => 'sint8',
    'SmallInt' => 'sin16',
    'Word'     => 'uint16',
    'Integer'  => 'sint16',  # sint32 in Delphi or ObjFPC mode
    'Cardinal' => 'uint32',
    'LongInt'  => 'sint32',
    'LongWord' => 'uint32',
    'Int64'    => 'sint64',
    'QWord'    => 'uint64',

    # Boolean Types    
    'Boolean'  => 'sint8',
    'ByteBool' => 'sint8',
    'WordBool' => 'sint16',
    'LongBool' => 'sint32',
    
    # Floating Point Types
    # http://www.freepascal.org/docs-html/ref/refsu6.html#x28-310003.1.2
    # Real     => either 'float' or 'double'
    'Single'   => 'float',
    'Double'   => 'double',
    # Extended (size = 10
    # Comp
    # Currency
  },
}

=head2 mangler

 my $mangler = FFI::Platypus::Lang::Pascal->mangler($ffi->libs);
 # prints ADD_ADD$SMALLINT$SMALLINT$$SMALLINT
 print $mangler->("add(smallint,smallint):smallint");

Returns a subroutine reference that will "mangle" C++ names.

=cut

sub mangler
{
  my($class, @libs) = @_;
  
  my %mangle;
  
  foreach my $libpath (@libs)
  {
    require Parse::nm;
    Parse::nm->run(
      files => $libpath,
      filters => [ {
        action => sub {
          my $c_symbol = $_[0];
          $c_symbol =~ s{^_}{};
          return if $c_symbol =~ /^THREADVARLIST_/;
          return unless $c_symbol =~ /^[A-Z0-9_]+(\$[A-Z0-9_]+)*(\$\$[A-Z0-9_]+)?$/;
          print "c_symbol = $c_symbol\n";
          my $symbol = $c_symbol;
          my $ret = '';
          $ret = $1 if $symbol =~ s/\$\$([A-Z_]+)$//;
          my($name, @args) = split /\$/, $symbol;
          $symbol = "${name}(" . join(',', @args) . ')';
          $symbol .= ":$ret" if $ret;
          push @{ $mangle{$name} }, [ $symbol, $c_symbol ];
        },
      } ],
    );
  }
  
  use YAML ();
  print YAML::Dump(\%mangle);
  
  sub {
    my $symbol = $_[0];

    if($symbol =~ /^(.+)\((.*)\)$/)
    {
      my $name = uc $1;
      my @args = map { uc $_ } split ',', $2;
      $name =~ s{\.}{_};
      return join '$', $name, @args;
    }
    elsif($symbol =~ /^(.+)\((.*)\):(.*)$/)
    {
      my $name = uc $1;
      my @args = map { uc $_ } split ',', $2;
      my $ret = uc $3;
      $name =~ s{\.}{_};
      return join '$', $name, @args, "\$$ret";
    }
    
    my $name = uc $symbol;
    $name =~ s/\./_/;

    if($mangle{$name})
    {
      if(@{ $mangle{$name} } == 1)
      {
        return $mangle{$name}->[0]->[1];
      }
      else
      {
        croak(
          "$symbol is ambiguous.  Please specify one of: " .
          join(', ', map { $_->[0] } @{ $mangle{$name} })
        );
      }
    }
    $symbol;
  };
}

1;

=head1 EXAMPLES

See the above L</SYNOPSIS> or the C<examples> directory that came with 
this distribution.

=head1 SUPPORT

If something does not work as advertised, or the way that you think it 
should, or if you have a feature request, please open an issue on this 
project's GitHub issue tracker:

L<https://github.com/plicease/FFI-Platypus-Lang-Pascal/issues>

This project's GitHub issue tracker listed above is not Write-Only.  If
you want to contribute then feel free to browse through the existing
issues and see if there is something you feel you might be good at and
take a whack at the problem.  I frequently open issues myself that I
hope will be accomplished by someone in the future but do not have time
to immediately implement myself.

Another good area to help out in is documentation.  I try to make sure
that there is good document coverage, that is there should be
documentation describing all the public features and warnings about
common pitfalls, but an outsider's or alternate view point on such
things would be welcome; if you see something confusing or lacks
sufficient detail I encourage documentation only pull requests to
improve things.

=head1 CONTRIBUTING

If you have implemented a new feature or fixed a bug then you may make a 
pull reequest on this project's GitHub repository:

L<https://github.com/plicease/FFI-Platypus-Lang-Pascal/issues>

Caution: if you do this too frequently I may nominate you as the new 
maintainer.  Extreme caution: if you like that sort of thing.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=item L<Module::Build::FFI::Pascal>

Bundle Free Pascal with your FFI / Perl extension.

=back

=head1 AUTHOR

Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

