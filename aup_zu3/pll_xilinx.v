//============================================================================
// Xilinx replacement for Altera PLL used by GBA emu
// Same port names so GBA.sv does not need changes.
// Input: 50 MHz (refclk). Outputs: ~100 MHz (outclk_0), ~50 MHz (outclk_1).
// Target: xczu3eg-sfvc784-2-e
//============================================================================
module pll (
	input  wire refclk,   // 50 MHz
	input  wire rst,
	output wire outclk_0, // 100 MHz -> clk_sys
	output wire outclk_1, // 50 MHz  -> CLK_VIDEO
	output wire locked
);

	wire clkfbout;
	wire clkfbin;
	wire clk0_unbuf, clk1_unbuf;

	MMCME2_ADV #(
		.BANDWIDTH("OPTIMIZED"),
		.CLKFBOUT_MULT_F(20.0),
		.CLKFBOUT_PHASE(0.0),
		.CLKIN1_PERIOD(20.0),   // 50 MHz
		.CLKOUT0_DIVIDE_F(10.0), // 100 MHz
		.CLKOUT1_DIVIDE(20),     // 50 MHz
		.CLKOUT0_DUTY_CYCLE(0.5),
		.CLKOUT1_DUTY_CYCLE(0.5),
		.CLKOUT0_PHASE(0.0),
		.CLKOUT1_PHASE(0.0),
		.DIVCLK_DIVIDE(1),
		.REF_JITTER1(0.010),
		.STARTUP_WAIT("FALSE")
	) mmcm_inst (
		.CLKFBIN(clkfbin),
		.CLKIN1(refclk),
		.CLKIN2(1'b0),
		.CLKINSEL(1'b1),
		.DADDR(7'h0),
		.DCLK(1'b0),
		.DEN(1'b0),
		.DI(16'h0),
		.DWE(1'b0),
		.PSCLK(1'b0),
		.PSEN(1'b0),
		.PSINCDEC(1'b0),
		.PWRDWN(1'b0),
		.RST(rst),
		.CLKFBOUT(clkfbout),
		.CLKOUT0(clk0_unbuf),
		.CLKOUT1(clk1_unbuf),
		.CLKOUT2(),
		.CLKOUT3(),
		.CLKOUT4(),
		.CLKOUT5(),
		.DO(),
		.DRDY(),
		.LOCKED(locked),
		.CLKFBSTOPPED(),
		.CLKINSTOPPED(),
		.PSDONE()
	);

	BUFG u_bufg_fb (.I(clkfbout), .O(clkfbin));
	BUFG u_bufg_0  (.I(clk0_unbuf), .O(outclk_0));
	BUFG u_bufg_1  (.I(clk1_unbuf), .O(outclk_1));

endmodule
