use DB::OSQ::Model::Row;
use DB::OSQ::Model::Types;
unit class D::Model::Hello::Row does DB::OSQ::Model::Row;

has $!x is field = defaults :t<string>;

method prefix-x {
  'prefix'~$.x;
}
