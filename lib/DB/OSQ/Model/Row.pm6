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
    return %opts<check>($value, :%opts, :$model);
  } else {
    my $r = True;
    for %opts<check>.kv -> $idx, $val {
      $r &&= $val($value, :%opts, :$model);
      unless $r {
        log-debug "%opts<type> failed check $idx for value $original-value";
        return $r;
      }
    }
  }
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
          $fd{$name}
        },
        STORE => method ($x) {
          log-debug "Checking {$pkg}.$name assignment of {Nil ~~ $x ?? '' !! $x~'.'}{$x.WHAT.^name}";
          my $c      = $($x);
          my $result = try dispatch-check($c, :opts(%proto));
          log-debug "Value after check: {$c.perl}.{$c.WHAT.^name}";
          log-debug "           result: {$result ?? 'pass' !! 'fail'}";
          $fd{$name} = $c
            if $result;
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
