unit role DB::OSQ::Model::Row;
use DB::OSQ::Logger;
use DB::OSQ::Model::Types;
my %fields;

has Bool $!changed;

has %!field-data;
has %!field-definitions;

multi sub trait_mod:<is>(Attribute $a, :$field!) is export {
  %fields{$a.package.^name}.push($a);
}

sub dispatch-check($value is rw, :%opts, :$model?) returns Bool {
  my $original-value = $($value);
  log-debug "Dispatch check called for value {$value.WHAT.^name}";
  log-debug 'Found Nil value and passing because nullable'
    if Any ~~ $value.WHAT && %opts<nullable>;
  return True if Any ~~ $value.WHAT && %opts<nullable>;
  if %opts<check> ~~ Callable {
    return %opts<check>($value, :%opts, :$model) ?? 'check' !! Nil;
  } else {
    my $r = True;
    for %opts<check>.kv -> $idx, $val {
      $r &&= $val($value, :%opts, :$model);
      unless $r {
        log-debug "%opts<type> failed check $idx for value $original-value";
        return $idx;
      }
      log-debug "  :value($value) after validation $idx";
    }
  }
  Nil;
}

multi method set-field($key, $v, :$pkg = $OUTERS::PACKAGE.^name//$?PACKAGE.^name) {
  my $value = $($v);
  log-warn 'test';
  log-error "Refusing assignment of {$pkg}.$key"
    unless %!field-definitions{$key}:exists;
  return 'no field' unless %!field-definitions{$key}:exists;
  log-debug "Checking {$pkg}.$key assignment of {Nil ~~ $value ?? '' !! $value~'.'}{$value.WHAT.^name}";
  my $result = try dispatch-check($value, :opts(%!field-definitions{$key}));
  log-debug "Value after check: {$value.perl}.{$value.WHAT.^name}";
  log-debug "           result: {Nil ~~ $result ?? '(Nil)' !! $result.perl}";
  %!field-data{$key} = $value
    unless $result;
  $result;
}

multi method set-field(%kvs, :$pkg = $OUTERS::PACKAGE.^name//$?PACKAGE.^name) {
  my %errors;
  my $r;
  for %kvs.kv -> $k, $v {
    $r = self.set-field($k, $v, :$pkg);
    %errors{$k} = $r
      if $r;
  }
  log-debug 'errors '~log-indent(%errors, :no-prefix);
  log-debug 'field-data '~log-indent(%!field-data, :no-prefix);
  %errors;
}

submethod TWEAK {
  # create the getter/dsetters
  for @(%fields{self.^name}) -> $attr {
    my $name = $attr.name.substr(2);
    my $pkg  = self.^name;
    if Mu !~~ self.HOW.lookup(self, $name).WHAT {
      log-warn "Skipping binding on {$pkg}\.$name - method already exists in package";
      next;
    }
    my %proto = $attr.get_value(self);
    %!field-definitions{$name} = %proto;
    log-debug "Found proto for $name\n"~log-indent(%proto);
    if !%proto<type> {
      log-warn "Skipping getter/setter for {$pkg}.$name due to missing <type>";
      next;
    }
    log-debug "Binding getter/setter for {$pkg}.$name";
    self.HOW.add_method(self, $name, my method {
      my $fd := %!field-data;
      Proxy.new(
        FETCH => method {
          $fd{$name}//Nil;
        },
        STORE => method ($x) {
          self.set-field($name, $x, :$pkg);
        },
      );
    });
  }
}

method field-data {
  %!field-data;
}

method field-definitions {
  %!field-definitions;
}

method changed {
  $!changed;
}
