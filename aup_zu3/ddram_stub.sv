//============================================================================
// Stub for ddram when building for AUP-ZU3 (no DE10-Nano HPS DDR). Same
// interface as rtl/ddram.sv; all read data is zero, writes ignored. Use this
// instead of rtl/ddram.sv in Vivado so the design synthesizes. For real
// gameplay you need a real memory backend (BRAM, PS DDR, or SDRAM).
//============================================================================
module ddram (
	input         DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	input  [27:1] ch1_addr,
	output [63:0] ch1_dout,
	input  [15:0] ch1_din,
	input         ch1_req,
	input         ch1_rnw,
	output        ch1_ready,

	input  [27:1] ch2_addr,
	output [31:0] ch2_dout,
	input  [31:0] ch2_din,
	input         ch2_req,
	input         ch2_rnw,
	output        ch2_ready,

	input  [25:1] ch3_addr,
	output [15:0] ch3_dout,
	input  [15:0] ch3_din,
	input         ch3_req,
	input         ch3_rnw,
	output        ch3_ready,

	input  [27:1] ch4_addr,
	output [63:0] ch4_dout,
	input  [63:0] ch4_din,
	input         ch4_req,
	input         ch4_rnw,
	input  [7:0]  ch4_be,
	output        ch4_ready,

	input  [27:1] ch5_addr,
	input  [63:0] ch5_din,
	input         ch5_req,
	output        ch5_ready
);

	assign DDRAM_BURSTCNT = 8'b0;
	assign DDRAM_ADDR     = 29'b0;
	assign DDRAM_RD       = 1'b0;
	assign DDRAM_DIN      = 64'b0;
	assign DDRAM_BE       = 8'b0;
	assign DDRAM_WE       = 1'b0;

	assign ch1_dout = 64'b0;
	assign ch2_dout = 32'b0;
	assign ch3_dout = 16'b0;
	assign ch4_dout = 64'b0;

	// Acknowledge requests after a short delay so state machines don't hang
	reg [2:0] ch1_dly = 0, ch2_dly = 0, ch3_dly = 0, ch4_dly = 0, ch5_dly = 0;
	always @(posedge DDRAM_CLK) begin
		ch1_dly <= { ch1_dly[1:0], ch1_req };
		ch2_dly <= { ch2_dly[1:0], ch2_req };
		ch3_dly <= { ch3_dly[1:0], ch3_req };
		ch4_dly <= { ch4_dly[1:0], ch4_req };
		ch5_dly <= { ch5_dly[1:0], ch5_req };
	end
	assign ch1_ready = ch1_dly[2];
	assign ch2_ready = ch2_dly[2];
	assign ch3_ready = ch3_dly[2];
	assign ch4_ready = ch4_dly[2];
	assign ch5_ready = ch5_dly[2];

endmodule
