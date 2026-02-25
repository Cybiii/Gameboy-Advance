# Run implementation and bitstream. Synthesis must have completed.
open_project [file join [pwd] "gba_zu3.xpr"]
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if { [get_property PROGRESS [get_runs impl_1]] != "100%" } { error "Implementation failed" }
close_project
