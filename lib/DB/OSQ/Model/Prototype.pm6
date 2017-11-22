unit role DB::OSQ::Model::Prototype;

my $static-types = { 
  Pg => {
    In => {
      'double precision'  => Num,
      'integer'           => Int,
      'varchar'           => Str,
      'character varying' => Str,
      'text'              => Str,
    },
    Out => {
      Num => 'float',
      Int => 'integer',
      Str => 'varchar',
    },
    Degrade => @(
      Int => Int, 
      Num => Num, 
      Str => Str,
    )
  },
  mysql => {
    In => {
      'double precision'  => Num,
      'int'           => Int,
      'varchar'           => Str,
      'character varying' => Str,
      'text'              => Str,
    },
    Out => {
      Num => 'float',
      Int => 'int',
      Str => 'varchar',
    },
    Degrade => @(
      Int => Int, 
      Num => Num, 
      Str => Str,
    )
  },
  SQLite => {
    In => {
      'float'   => Num,
      'integer' => Int,
      'varchar' => Str,
      'text'    => Str,
    },
    Out => {
      Num => 'float',
      Int => 'integer',
      Str => 'varchar',
    },
    Degrade => @(
      Int => Int,
      Num => Num,
      Str => Str,
    )

  },
};

method bind($st is rw) {
  $st = $static-types;
}
