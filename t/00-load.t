use lib 't/lib';
use lib 'lib';
use D;
use Data::Dump;

my D $db-p .=new(prototype => True, log-level => 'DEBUG' );
$db-p.connect(
  driver => 'Pg',
  options => {
    db => {
      database => 'tonyo',
    },
  },
);

say Dump $db-p.model(qw<xyz>);

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
