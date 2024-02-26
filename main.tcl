set argc 2
set argv [list "--origin_dir" "../"]
source ../barker_correlator.tcl
#vivado creates additional runs for whatever reason
delete_runs "synth_1"
delete_runs "impl_2"
