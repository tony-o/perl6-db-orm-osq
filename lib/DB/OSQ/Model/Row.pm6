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

submethod TWEAK {
  # create the getter/dsetters
  for @(%fields{self.^name}) -> $attr {
    my $name = $attr.name.substr(2);
    if Mu !~~ self.HOW.lookup(self, $name).WHAT {
      log-warn "Skipping binding on {self.^name}\.$name - method already exists in package";
      next;
    }
    my $proto = $attr.get_value(self);
    if !$proto<type> {
      log-warn "Skipping getter/setter for {self.^name}.$name due to missing <type>";
      next;
    }
    log-info "Binding getter/setter for {self.^name}.$name";
    self.HOW.add_method(self, $name, my method {
      my $fd := %!field-data;
      Proxy.new(
        FETCH => method {
          $fd{$name}
        },
        STORE => method ($x) {
          $fd{$name} = $x
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
