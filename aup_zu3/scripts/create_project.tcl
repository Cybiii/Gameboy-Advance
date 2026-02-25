#============================================================================
# Create Vivado project for GBA on AUP-ZU3 (xczu3eg-sfvc784-2-e)
# Run from repo root: vivado -mode batch -source aup_zu3/scripts/create_project.tcl
# Or from aup_zu3: vivado -mode batch -source scripts/create_project.tcl
#============================================================================
set part "xczu3eg-sfvc784-2-e"
set top  "zu3_top"

# Resolve repo root (script may be run from repo root or from aup_zu3)
set script_dir [file normalize [file dirname [info script]]]
if { [string match "*aup_zu3*" $script_dir] } {
	set repo_root [file normalize [file join $script_dir ".." ".."]]
} else {
	set repo_root [file normalize [file join $script_dir ".."]]
}
set aup_dir [file join $repo_root "aup_zu3"]
set rtl_dir [file join $repo_root "rtl"]
set sys_dir [file join $repo_root "sys"]

create_project -force gba_zu3 [file join $aup_dir "build"] -part $part
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]

# So GBA.sv can find build_id.v
set_property include_dirs [list $aup_dir] [current_fileset]
set_property verilog_define {MISTER_FB=1} [current_fileset]

#---- Top and AUP-ZU3 sources (replacements + top) ----
add_files -norecurse [list \
	[file join $aup_dir "zu3_top.v"] \
	[file join $aup_dir "pll_xilinx.v"] \
	[file join $aup_dir "hps_io_stub.sv"] \
	[file join $aup_dir "ddram_stub.sv"] \
	[file join $aup_dir "build_id.v"] \
]
add_files -norecurse [file join $repo_root "GBA.sv"]

#---- RTL (VHDL + SV); exclude Altera PLL and ddram (we use stubs) ----
foreach f [glob -nocomplain [file join $rtl_dir "*.vhd"]] {
	add_files -norecurse $f
}
# VHDL entities referenced as MEM.* must be compiled into library MEM
foreach f [list SyncRam.vhd SyncRamDual.vhd SyncRamDualByteEnable.vhd SyncRamDualNotPow2.vhd SyncFifo.vhd] {
	set fpath [file join $rtl_dir $f]
	if { [file exists $fpath] } {
		set_property library MEM [get_files -of_objects [current_fileset] $fpath]
	}
}
foreach f [glob -nocomplain [file join $rtl_dir "*.sv"]] {
	if { [string match "*ddram*" $f] } { continue }
	add_files -norecurse $f
}
foreach f [glob -nocomplain [file join $rtl_dir "*.v"]] {
	if { [string match "*pll*" $f] } { continue }
	add_files -norecurse $f
}
# Do not add rtl/pll/ subdir - we use aup_zu3/pll_xilinx.v

#---- Sys (exclude hps_io and Altera-specific) ----
set sys_exclude { hps_io.sv pll_hdmi pll_audio pll_cfg pll_hdmi_adj.vhd ascal.vhd }
foreach f [glob -nocomplain [file join $sys_dir "*.v"] [file join $sys_dir "*.sv"] [file join $sys_dir "*.vhd"]] {
	set tail [file tail $f]
	set skip 0
	foreach ex $sys_exclude {
		if { [string match "*$ex*" $tail] } { set skip 1; break }
	}
	if { !$skip } { add_files -norecurse $f }
}
foreach f [glob -nocomplain [file join $sys_dir "pll_hdmi" "*.v"] [file join $sys_dir "pll_audio" "*.v"] [file join $sys_dir "pll_cfg" "*.v"]] {
	# Skip Altera PLLs
}

#---- Constraints ----
add_files -fileset constrs_1 -norecurse [file join $aup_dir "zu3.xdc"]

#---- Set top (top is a fileset property, not project) ----
set_property top $top [current_fileset]
set_property top_file [file join $aup_dir "zu3_top.v"] [current_fileset]

puts "Project created. Part: $part, Top: $top"
puts "Next: run synthesis (synth or run_example flow)."
puts "Remember to set the 100 MHz clock pins in zu3.xdc from your board schematic."
