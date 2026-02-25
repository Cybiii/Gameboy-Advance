# Run synthesis. Open project first (e.g. from create_project.tcl).
open_project [file join [pwd] "gba_zu3.xpr"]
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if { [get_property PROGRESS [get_runs synth_1]] != "100%" } { error "Synthesis failed" }
# Generate utilization report (LUT/FF/BRAM etc.)
open_run synth_1
report_utilization -file utilization_synth.rpt -hierarchical -hierarchical_depth 2
puts "Utilization report written to: [file join [pwd] utilization_synth.rpt]"
close_project
