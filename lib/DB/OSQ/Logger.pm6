unit module DB::OSQ::Logger;
use DB::OSQ::Enums;

our $log-level is export = %*ENV<production>
  ?? 'ERROR'
  !! 'INFO';

try require ::('Terminal::ANSIColor');

sub colorizer($text, $fmt) {
  return $text if ::('Terminal::ANSIColor') ~~ Failure;
  ::('Terminal::ANSIColor::EXPORT::DEFAULT::&colored').($text, $fmt);
}

sub color($level) {
  if ::('Terminal::ANSIColor') !~~ Failure {
    my $color = 'green';
    given $level {
      when 'ERROR' { $color = 'red bold' };
      when ' INFO' { $color = 'white' };
      when ' WARN' { $color = 'yellow' };
    };
    return 
        colorizer('[', 'white bold')
      ~ colorizer($level, $color)
      ~ colorizer(']', 'white bold');
  }
  return "$level|";
}

sub log-indent($hash, :$indent-size = 2, :$indent-level = 1, :$initial-indent = 8, :$no-prefix = False) is export {
  my $r = colorizer((' ' x ($no-prefix ?? 0 !! $initial-indent)) ~ ($hash ~~ Array ?? '[' !! '{'), 'white bold') ~ "\n";
  for $hash ~~ Array ?? 0..$hash.elems !! $hash.keys -> $k {
    my $val = $hash ~~ Array ?? $hash[$k] !! $hash{$k};
    my $sym = colorizer($hash ~~ Array ?? ':' !! ' =>', 'magenta bold');
    if $val !~~ any(Hash, Array) {
      $r ~= (' ' x $initial-indent + ($indent-size * $indent-level));
      $r ~= "{colorizer($k,'magenta')}$sym {$val.perl}\n";
    } else {
      $r ~= (' ' x $initial-indent + ($indent-size * $indent-level));
      $r ~= "{colorizer($k,'magenta')}$sym ";
      $r ~= log-indent($val, :$indent-size, :indent-level($indent-level+1), :$initial-indent, :no-prefix(True));
      $r ~= "\n";
    }
  }
  $r ~= colorizer((' ' x $initial-indent + ($indent-size * ($indent-level-1))) ~ ($hash ~~ Array ?? ']' !! '}'), 'white bold');
  $r;
}

sub log-level {
  $log-level // (%*ENV<production>
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
  "{color $level} $_".say
    for @lines;
}
