unit role DB::OSQ::Search::Convenience[$model];

use DB::OSQ::Search;

method search(%params, %options?) {
  DB::OSQ::Search.new(:model($model), :%params, :%options);
}

