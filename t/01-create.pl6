use lib '../lib';
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

my $model  = $db-p.model('Hello');

my $search = $model.search({ hello => 1 }, {
  columns => (qw<txt id>),
  sort    => [
    txt => 'desc',
    id  => 'asc',
  ],
});

#say $search.all;

my $x = $model.create({
  x => 1,
  y => 2,
});

$x.prefix-x.say;
