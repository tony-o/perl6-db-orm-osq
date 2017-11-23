unit role DB::OSQ::Model[Str $table-name, Bool $prototype = False];

use DB::OSQ::Model::Prototype;
use DB::OSQ::Logger;
use DB::OSQ::Search::Convenience;

has %options;
has $!driver;
has $!db;
has $!table-name;
has %!data;
has @!changed;
has $.id is rw = -1;
has @.fields;
has $.quote;
has $!static-types;
has $!model-class;
has $!row-class;

submethod BUILD (:$!driver, :$!db, :$!quote, :$skip-create = False) {
  $!table-name = $table-name;
  self does DB::OSQ::Search::Convenience[self];
  if $prototype {
    self does DB::OSQ::Model::Prototype;
    self.bind($!static-types);
    log-debug
      'Applying DB::OSQ::Model::Prototype',
      'Prototyping with driver: '~$!driver,
    ;
    log-debug "Loaded model prototype [table $!table-name]";
  } else {
    $!model-class = $?OUTERS::CLASS;
    my $c-str = "{$!model-class.^name}\:\:Row";
    try require ::($c-str);
    if ::($c-str) ~~ Failure {
      log-error "Half loaded {$!model-class.^name} - could not find associated $c-str",
                '  expect the unexpected';
    } else {
      $!row-class = ::("{$!model-class.^name}::Row");
      log-debug "Loaded model {$!model-class.^name} [table $!table-name]";
    }
  }
  self.auto-quote($!quote, :$!driver)
    unless $!quote.defined;
}

method prototype {
  $prototype;
}

method auto-quote($quote is rw, :$driver) {
  $quote = {
    identifier => '`',
    value      => '"',
  } if $driver eq 'mysql';
  $quote = {
    identifier => '"',
    value      => '\'',
  } unless $driver eq 'mysql';
}

multi method create { $!row-class.new; }

multi method create(%values) {
  my $new = $!row-class.new;
  $new.set-field(%values, :pkg($!row-class.^name));
  $new;
}

method driver     { $!driver; }
method table-name { $!table-name; }
method db         { $!db; }
