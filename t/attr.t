use lib '../lib';
use DB::OSQ::Model::Row;
use DB::OSQ::Model::Types;
class A does DB::OSQ::Model::Row {
  has $!field is field = {
    type => "xyz",
  };
};

class B does DB::OSQ::Model::Row {
  has $!x is field = {};
  has $!y is :typed is :field = {
    length => 3
  };
  has $!z is field = {
    len => 6
  };
  method z { };
};

my A $a .=new;
my B $b .=new;

$a.field;
$a.field-data.perl.say;

$b.x;
$b.y;
$b.x = 25;
say $b.x;

# vim:syntax=perl6
