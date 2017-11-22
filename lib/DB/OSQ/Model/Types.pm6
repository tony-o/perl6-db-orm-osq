unit module DB::OSQ::Model::Types;

my %def = 
  string => %( 
    type    => 'string',
    db-type => 'varchar',
    length  => 8,
    check   => {
      'strable' => sub ($value is rw, :$model?, :%opts) { $value.=Str; },
      'min-len' => sub ($value is rw, :$model?, :%opts) { $value.chars >= (%opts<length><min>//0); },
      'max-len' => sub ($value is rw, :$model?, :%opts) { $value.chars <= (%opts<length><max>//%opts<length>//10000); },
    },
  ),
;
sub merge(*@_) {
  my %r;
  for @_ -> %x {
    for %x.keys -> $k {
      if %x{$k} !~~ Hash {
        %r{$k} = %x{$k};
        next;
      }
      %r{$k} = merge (%r{$k}//{}), %x{$k};
    }
  }
  %r;
}

sub defaults(*@_, :$t) is export {
  merge %def{$t}, |@_;
}
