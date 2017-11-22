use lib '../lib';
use lib 'lib';
use D;

my D $db-p .=new(prototype => True, debug-level => 'DEBUG' );
$db-p.connect(
  driver => 'Pg',
  options => {
    db => {
      database => 'tonyo',
    },
  },
);

$db-p.model('xyz');

my $search = $db-p.model('xyz').search({ hello => 1 }, {
  columns => (qw<txt id>),
  sort    => [
    txt => 'desc',
    id  => 'asc',
  ],
});

use Data::Dump;
say 'first '~Dump $search.first;
say 'next  '~Dump $search.next;
say 'count '~ $search.count;
say 'first '~Dump $search.first;
say 'next  '~Dump $search.next;
say 'all   '~Dump $search.all;
#$search.delete;
say 'first '~Dump $search.first;

my $n-s = $search.sort(qw<id> => 'desc');

say 'rsort-id '~Dump $n-s.first;
