unit role DB::OSQ;

use DBIish;
use DB::OSQ::Model;
use DB::OSQ::Logger;
use DB::OSQ::Enums;
use DBDish::Connection;

has $!db;
has $!driver;
has $.log-level;
has $!prototype;
has %!models;
has $!root;
has $!can-load = False;

submethod BUILD (:$!db, :$!driver, :$!prototype = False, :$!log-level) {
  $DB::OSQ::Logger::log-level = (%*ENV<production>
    ?? DEBUG_LEVEL<WARN>
    !! DEBUG_LEVEL<INFO>
  ) unless $!log-level.defined;

  $DB::OSQ::Logger::log-level = $!log-level
    if $!log-level.defined;  
  say $DB::OSQ::Logger::log-level;
}

multi method connect(:$driver, :%options) {
  log-debug "Connecting with $driver:\n{log-indent(%options<db>) }";
  try {
    $!db       = DBIish.connect($driver, |%options<db>) or die $!;
    $!driver   = $driver;
    $!can-load = True;
    self.load-models;
    CATCH {
      default {
        log-error ~$_.native-message.trim;
      }
    }
  }
}

multi method connect(DBDish::Connection :$!db) {
  $!driver = $!db.driver-name.split('::')[1];
  self.load-models;
}

method load-models($prefix?) {
  log-error 'Please connect prior to loading', die 'Please connect prior to loading' unless $!can-load;
  my $base     = $prefix.defined ?? $prefix !! $?CALLERS::CLASS.^name;
  my @possible = try { "lib/{$base.subst('::', '/')}/Model".IO.dir.grep(* ~~ :f && *.extension eq any('pm6', 'pl6')); } // [];
  for @possible -> $f {
    next unless $f.index("lib/$base") !~~ Nil;
    my $mod-name = $f.path.substr($f.index("lib/$base")+4, *-4);
    $mod-name .=subst(/(\/|\\)/, '::', :g);
    log-debug "Attempting to load: $mod-name";
    try {
      require ::($mod-name);
      %!models{$mod-name.split('::')[*-1]} = ::($mod-name).new(:$!driver);
      CATCH {
        default {
          warn $_.payload;
          log-warn "Unable to load $mod-name",
                   (' ' x 10)~$_.payload.lines.map({' ' x 10}).join("\n"),
          ;
        }
      }
    };
  }
}

method model(Str $model-name, Str :$module?) {
  log-error 'Please connect prior to loading', die 'Please connect prior to loading' unless $!can-load;
  if %!models{$model-name}.defined {
    log-debug("Using model $model-name from cache");
    return %!models{$model-name};
  }
  my $prefix = $?OUTER::CLASS.^name;
  my $model  = $module.defined
    ?? $module
    !! "$prefix\::Model\::$model-name";
  log-debug "Attempting to load: $model";
  try require ::("$model");
  if ::("$model") ~~ Failure && !$!prototype {
    log-debug $!prototype;
    log-error "Unable to load $model and protytping is off";
  } else {
    log-debug "Caching model $model-name";
    try {
      %!models{$model-name} = DB::OSQ::Model[$model-name, True].new(:$!driver, :$!db)
        if $!prototype && ::("$model") ~~ Failure;
      %!models{$model-name} = ::("$model").new
        unless ::("$model") ~~ Failure;
    };
  }
}
