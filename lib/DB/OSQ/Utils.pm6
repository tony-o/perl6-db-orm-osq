unit module DB::OSQ::Utils;

sub merge(*@_) is export {
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
