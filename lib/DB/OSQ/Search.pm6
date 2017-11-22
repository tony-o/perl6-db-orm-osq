unit class DB::OSQ::Search;

use DB::OSQ::Logger;

has $!model;
has %!quote;
has $!cursor;
has %!params;
has @!vals;
has $!sql;
has @!sort;
has $!index;
has $!sth;
has %!data;
has %!options;

submethod BUILD (:$!model, :%!params, :@!sort, :$!index = False, :%!options) {
  my $quote = $!model.quote
    if $!model.^can('quote');  
  if $quote ~~ Hash {
    %!quote<identifier> = $quote<identifier> // ($!model.driver eq 'mysql' ?? '`' !! '"');
    %!quote<value>      = $quote<value>      // ($!model.driver eq 'mysql' ?? '`' !! '\'');
  } else {
    %!quote<identifier> = $quote // ($!model.driver eq 'mysql' ?? '`' !! '"');
    %!quote<value>      = $quote // ($!model.driver eq 'mysql' ?? '`' !! '\'');
  }
  $!cursor = 0;
  self!gen-sql;
}

method !fquote($str, $type) {
  my $quote = $str.starts-with(%!quote{$type}) ?? '' !! %!quote{$type};
  $quote ~ $str ~ $quote;
}

method !gen-sql(Bool :$force = False, Bool :$update-self = False, :$index = False, :$cursor = 0, :$no-sort = False) {
  log-debug 'Searching with model '~$!model.WHAT.^name~' (prototype: '~$!model.prototype~')';
  if !$!sql.defined || $force {
    my $sql = '';
    my @val;
    for %!params.keys.sort({ $^b eq '-join' && $^a ne '-join' ?? More !! $^a eq '-join' ?? Less !! $^a cmp $^b }) -> $key {
      my %ret = self!to-sql($key, %!params);
      if %ret<sql> ne '' && $sql eq '' && $key ne '-join' {
        $sql ~= 'WHERE ';
      } elsif %ret<sql> ne '' && $key ne '-join' {
        $sql ~= 'AND ';
      }
      $sql ~= %ret<sql>;
      @val.push($_) for @(%ret<val>);
    }
    $sql  = " FROM {self!fquote($!model.table-name, 'identifier')} $sql ";
    $sql ~= 'ORDER BY ' if %!options<sort>.elems > 0 && !so $no-sort;
    for @(%!options<sort>) -> $pair {
      last if so $no-sort;
      $sql ~= "{self!fquote($pair.key, 'identifier')} {$pair.value}, " if $pair ~~ Pair;
      $sql ~= "{self!fquote($pair, 'identifier')}, " if $pair !~~ Pair;
    }
    $sql ~~ s/ ',' \s* $ / / if %!options<sort>.elems > 0 && !so $no-sort;
    if so $!index || so $index {
      $sql ~= self!pg-cursor($cursor) if $!model.driver eq 'Pg';
      $sql ~= self!mysql-cursor($cursor) if $!model.driver eq 'mysql';
      $sql ~= self!sqlite-cursor($cursor) if $!model.driver eq 'SQLite';
    }
    if $update-self {
      @!vals   = @val;
      $!sql    = $sql.trim;
    }
    return {
      sql => $sql.trim,
      val => @val,
    };
  }
}

method !field-list {
  log-debug 'using * for fields', return '*'
    unless %!options<columns>;
  log-debug 'generating field list';
  %!options<columns>.map({
    my $f = $_.split('.');
    $f.map({ self!fquote($_, 'identifier') }).join('.'); 
  }).join(', ');
}

method search(%params) {
  #TODO: merge params, return new ::Search  
}

method delete {
  if !%!data<delete> {
    my $sql   = self!gen-sql(index => False,);
    $sql<sql> = "DELETE {$sql<sql>}";
    log-debug "Preparing: '$sql<sql>' ({$sql<val>})";
    %!data<delete> = {
      sth => $!model.db.prepare($sql<sql>),
      sql => $sql<sql>,
      val => $sql<val>,
    };
  }
  %!data<delete><sth>.execute(%!data<delete><val>);
}

method all {
  if !%!data<all> {
    my $sql   = self!gen-sql(index => False,);
    $sql<sql> = "SELECT {self!field-list} {$sql<sql>}";
    log-debug "Preparing: '$sql<sql>' ({$sql<val>})";
    %!data<all> = {
      sth => $!model.db.prepare($sql<sql>),
      sql => $sql<sql>,
      val => $sql<val>,
      cnt => -1,
    };
  }
  %!data<all><sth>.execute($%!data<all><val>);
  #TODO: compose rows
  my @rows;
  while my $x = %!data<all><sth>.fetchrow_hashref {
    @rows.push($x);
  }
  return @rows;
}

method count {
  if !%!data<count> {
    my $sql   = self!gen-sql(index => False, no-sort => True);
    $sql<sql> = "SELECT COUNT(*) c {$sql<sql>}";
    log-debug "Preparing: '$sql<sql>' ({$sql<val>})";
    %!data<count> = {
      sth => $!model.db.prepare($sql<sql>),
      sql => $sql<sql>,
      val => $sql<val>,
      cnt => -1,
    };
    try {
      %!data<count><sth>.execute($sql<val>);
      my $href = %!data<count><sth>.fetchrow_hashref<c>;
      %!data<count><cnt> = $href;
      CATCH { default { log-error $_; } }
    };
  }
  %!data<count><cnt>;
}

method first {
  %!data<next><cur> = 0 if %!data<next>;
  $.next;
}

method next {
  if !%!data<next> {
    my $sql   = self!gen-sql(force => True, index => True, cursor => 0);
    $sql<sql> = "SELECT {self!field-list} $sql<sql>";
    log-debug "Preparing: '$sql<sql>' ({$sql<val>.join(', ')})";
    %!data<next> = {
      sth => $!model.db.prepare($sql<sql>),
      sql => $sql<sql>,
      val => $sql<val>,
      cur => 0,
    };
  } else {
    log-debug 'increasing cursor';
    %!data<next><cur>++;
    my $sql = self!gen-sql(force => True, index => True, cursor => %!data<next><cur>);
    $sql<sql> = "SELECT {self!field-list} $sql<sql>";
    %!data<next><sth> = $!model.db.prepare($sql<sql>);
  }
  %!data<next><sth>.execute(%!data<next><val>);
  my $row = %!data<next><sth>.fetchrow_hashref;
#TODO: BUILD ROW
  $row; 
}

method !compose($row) {
  $row ||= Nil;
}

method sort(*@sort) {
  my %options = %!options;
  %options<sort> = @sort;
  DB::OSQ::Search.new(:$!model, :%!params, :%options);
}

method !to-sql($key, %params, :$in-join = Nil) {
  my $str = '';
  my @val;
  if $key.lc eq '-and' || $key.lc eq '-or' {
    my $ao = $key.lc eq '-and' ?? 'AND ' !! 'OR ';
    $str ~= '(';
    for @(%params{$key}) -> $next {
      if $next.value ~~ Hash|Array {
        my %t = self!to-sql($next.key, $next, :$in-join);
        $str ~= %t<sql> ~ " $ao";
        @val.push($_) for @(%t<val>);
      } elsif $next ~~ Pair {
        my %t = self!to-sql($next.key, %($next), :$in-join);
        $str ~= %t<sql> ~ " $ao";
        @val.push($_) for @(%t<val>);
      } elsif $next ~~ Hash {
        my %t = self!to-sql($next, %params{$key}, :$in-join);
        $str ~= %t<sql> ~ " $ao";
        @val.push($_) for @(%t<val>);
      }
    }
    $str ~~ s/[ 'OR ' | 'AND ']$/)/;
  } elsif $key.lc eq '-join' {
    $str ~= ' join ' ~ %params{$key}<-table>;
    $str ~= ' on ';
    for @(%params{$key}<-on>) -> $next {
      my %t = self!to-sql($next.key, $next, in-join => %params{$key}<-table>);
      $str ~= %t<sql>;
      @val.push($_) for @(%t<val>);
    }
  } elsif %params{$key} ~~ Array {
    $str ~= '(';
    for @(%params{$key}) -> $v {
      $str ~= "{self!fquote($key, 'identifier')} = ? OR ";
      @val.push($v);
    }
    $str ~~ s/'OR ' $/)/;
  } else {
    if $key.lc eq '-raw' {
      if %params{$key} ~~ Pair {
        $str ~= %params{$key}.key;
        if %params{$key} ~~ Array {
          @val.push($_) for @(%params{$key}.value);
        } else {
          @val.push(%params{$key}.value);
        }
      } else {
        $str ~= %params{$key};
      }
    } elsif %params{$key} ~~ Pair && %params{$key}.key.lc eq ('-gt', '-lt', '-eq', '-like').any {
      my $op = %params{$key}.key.lc;
      $op = $op eq '-gt' ?? '>' !! $op eq '-lt' ?? '<' !! $op eq '-like' ?? 'like' !! '=';
      $str ~= "{($in-join ?? self!fquote($in-join, 'identifier') ~ '.' !! '') ~ self!fquote($key, 'identifier')}";
      $str ~= " $op ";
      $str ~= "{$in-join ?? self!fquote($!model.table-name, 'identifier') ~ '.' ~ self!fquote(%params{$key}.value, 'identifier') !! '?'}";
      @val.push(%params{$key}.value) unless $in-join;
    } else {
      $str ~= "{($in-join ?? self!fquote($in-join, 'identifier') ~ '.' !! '') ~ self!fquote($key, 'identifier')}";
      $str ~= " = ";
      $str ~= "{$in-join ?? self!fquote($!model.table-name, 'identifier') ~ '.' ~ self!fquote(%params{$key}, 'identifier') !! '?'}";
      @val.push(%params{$key}) unless $in-join;
    }
  }

  %(
    sql => $str,
    val => @val,
  );
}

method !pg-cursor($offset, $count = 1)  {
  "LIMIT $count OFFSET $offset";
}

method !mysql-cursor($offset, $count = 1) {
  "LIMIT $offset, $count";
}

method !sqlite-cursor($offset, $count = 1) {
  "LIMIT $offset, $count";
}

method raw-sql {
  $!sql;
}

method raw-val {
  @!vals;
}

