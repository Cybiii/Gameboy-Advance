# Program AUP-ZU3 with the GBA bitstream (EECS 151 lab-style: source target.tcl).
# Run from aup_zu3/build/impl: vivado -mode batch -source ../../scripts/program_fpga.tcl
# Board must be powered and connected via USB-C JTAG.

source ../target.tcl
set bitstream [file join $ABS_TOP build gba_zu3.runs impl_1 ${TOP}.bit]
if { ! [file exists $bitstream] } {
    puts "ERROR: Bitstream not found. Run 'make impl' first."
    puts "  Expected: $bitstream"
    exit 1
}

open_hw_manager
connect_hw_server
set targets [get_hw_targets *]
if { [llength $targets] == 0 } {
    puts "ERROR: No hardware targets. Is the board connected and powered?"
    close_hw_manager
    exit 1
}
open_hw_target [lindex $targets 0]
set devs [get_hw_devices xczu3_*]
if { [llength $devs] == 0 } {
    puts "ERROR: No ZU3 device found. Check cable and power."
    close_hw_target
    close_hw_manager
    exit 1
}
set dev [lindex $devs 0]
set_property PROGRAM.FILE $bitstream $dev
program_hw_devices $dev
close_hw_target
close_hw_manager
puts "Done. FPGA programmed with $bitstream"
