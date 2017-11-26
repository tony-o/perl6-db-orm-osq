use lib '../lib';
use DB::OSQ::Logger;
use DB::OSQ::Model::Row;
use DB::OSQ::Model::Types;
$DB::OSQ::Logger::log-level = 'DEBUG';
class A does DB::OSQ::Model::Row {
  has $!field is field = {
    type => "xyz",
  };
};

class B does DB::OSQ::Model::Row {
  has $!x is field = 
    defaults :t<string>, {
      nullable => True,  
    };
  has $!y is field =
    defaults :t<string>, {
      length => 3,
    };
  has $!z is field = {
    len => 6
  };
  method z { };
};

my A $a .=new;
my B $b .=new;

try $a.field;
try $a.field-data.perl.say;

try $b.x;
try $b.y;
try $b.y = 25;
try say $b.y;
try $b.y = Nil;
try $b.x = Nil;

# vim:syntax=perl6
