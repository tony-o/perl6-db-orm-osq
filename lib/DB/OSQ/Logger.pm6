unit module DB::OSQ::Logger;
use DB::OSQ::Enums;

our $debug-level is export = %*ENV<production>
  ?? 'ERROR'
  !! 'INFO';

sub log-indent($hash, :$indent-size = 2, :$indent-level = 1, :$initial-indent = 8, :$no-prefix = False) is export {
  my $r = (' ' x ($no-prefix ?? 0 !! $initial-indent)) ~ ($hash ~~ Array ?? '[' !! '{') ~ "\n";
  for $hash ~~ Array ?? 0..$hash.elems !! $hash.keys -> $k {
    my $val = $hash ~~ Array ?? $hash[$k] !! $hash{$k};
    my $sym = $hash ~~ Array ?? ':' !! ' =>';
    if $val !~~ any(Hash, Array) {
      $r ~= (' ' x $initial-indent + ($indent-size * $indent-level));
      $r ~= "$k$sym {$val.perl}\n";
    } else {
      $r ~= (' ' x $initial-indent + ($indent-size * $indent-level));
      $r ~= "$k$sym ";
      $r ~= log-indent($val, :$indent-size, :indent-level($indent-level+1), :$initial-indent, :no-prefix(True));
      $r ~= "\n";
    }
  }
  $r ~= (' ' x $initial-indent + ($indent-size * ($indent-level-1))) ~ ($hash ~~ Array ?? ']' !! '}');
  $r;
}

sub log-level {
  $debug-level // (%*ENV<production>
    ?? 'ERROR'
    !! 'INFO');
}

sub log-debug(*@lines) is export {
  log('DEBUG', @lines);
}

sub log-info(*@lines) is export {
  log(' INFO', @lines);
}

sub log-warn(*@lines) is export {
  log(' WARN', @lines);
}

sub log-error(*@lines) is export {
  log('ERROR', @lines);
}

sub log($level, *@lines) is export {
  my $key = $level.trim;
  return
    if (DEBUG_LEVEL{log-level}//DEBUG_LEVEL<INFO>) > DEBUG_LEVEL{$key};
  "|$level| $_".say
    for @lines;
}
