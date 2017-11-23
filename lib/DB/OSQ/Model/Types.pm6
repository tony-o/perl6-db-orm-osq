unit module DB::OSQ::Model::Types;
use DB::OSQ::Utils;

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
  integer => %(
    type    => 'integer',
    db-type => 'integer',
    check   => {
      'intable' => sub ($v is rw, :$model?, :%opts) { $v.=Int; },
    },
  ),
;

sub defaults(*@_, :$t) is export {
  merge %def{$t}, |@_;
}
