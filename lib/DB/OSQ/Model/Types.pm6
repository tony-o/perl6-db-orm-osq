unit module DB::OSQ::Model::Types;

multi sub trait_mod:<is>(Attribute $at, :$typed!) is export {
  $typed.perl.say;
}

sub check(Str:U, %value) is export {
  %value.say;
}
