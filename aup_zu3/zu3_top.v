//============================================================================
// Top-level for AUP-ZU3 (xczu3eg-sfvc784-2-e). Instantiates GBA emu;
// board 100 MHz -> 50 MHz for CLK_50M; reset from button; LEDs from emu.
// Use with: pll_xilinx.v, hps_io_stub.sv, ddram_stub.sv; do not use rtl/pll,
// sys/hps_io.sv, or rtl/ddram.sv. Include aup_zu3/build_id.v for GBA.sv.
//============================================================================
module zu3_top (
	// Board clock: 100 MHz differential (set pin in zu3.xdc)
	input  wire CLK_100_P,
	input  wire CLK_100_N,

	// Buttons [3:0] and switches [7:0] (optional; RESET = ~BUTTONS[0])
	input  wire [3:0] BUTTONS,
	input  wire [7:0] SWITCHES,

	// LEDs [7:0] - e.g. LED[0] = LED_USER
	output wire [7:0] LEDS,

	// SDRAM (emu drives these; no SDRAM on AUP-ZU3 - leave unconstrained or stub)
	output wire        SDRAM_CLK,
	output wire        SDRAM_CKE,
	output wire [12:0] SDRAM_A,
	output wire  [1:0] SDRAM_BA,
	inout  wire [15:0] SDRAM_DQ,
	output wire        SDRAM_DQML,
	output wire        SDRAM_DQMH,
	output wire        SDRAM_nCS,
	output wire        SDRAM_nCAS,
	output wire        SDRAM_nRAS,
	output wire        SDRAM_nWE
);

	wire clk_100;
	wire clk_50;
	wire locked;

	// Differential clock buffer
	IBUFDS u_clk_ibuf (
		.I (CLK_100_P),
		.IB(CLK_100_N),
		.O (clk_100)
	);

	// 100 MHz -> 50 MHz for CLK_50M
	reg clk_50_r = 0;
	always @(posedge clk_100) clk_50_r <= ~clk_50_r;
	BUFG u_bufg_50 (.I(clk_50_r), .O(clk_50));

	// Reset: active high in emu; use one button
	wire reset = ~BUTTONS[0];

	// HPS_BUS inout between top and emu
	wire [48:0] HPS_BUS;
	wire  [3:0] adc_bus;
	assign adc_bus = 4'bZ;

	// Unused video/audio leave open; connect LED_USER to first LED
	wire        emu_LED_USER;
	wire [1:0]  emu_LED_POWER, emu_LED_DISK, emu_BUTTONS;
	wire        emu_CLK_VIDEO, emu_CE_PIXEL;
	wire [12:0] emu_VIDEO_ARX, emu_VIDEO_ARY;
	wire  [7:0] emu_VGA_R, emu_VGA_G, emu_VGA_B;
	wire        emu_VGA_HS, emu_VGA_VS, emu_VGA_DE, emu_VGA_F1;
	wire [1:0]  emu_VGA_SL;
	wire        emu_VGA_SCALER, emu_VGA_DISABLE;
	wire [11:0] emu_HDMI_WIDTH, emu_HDMI_HEIGHT;
	wire        emu_HDMI_FREEZE, emu_HDMI_BLACKOUT, emu_HDMI_BOB_DEINT;
	wire        emu_FB_EN;
	wire  [4:0] emu_FB_FORMAT;
	wire [11:0] emu_FB_WIDTH, emu_FB_HEIGHT;
	wire [31:0] emu_FB_BASE;
	wire [13:0] emu_FB_STRIDE;
	wire        emu_FB_VBL, emu_FB_LL, emu_FB_FORCE_BLANK;
	wire [15:0] emu_AUDIO_L, emu_AUDIO_R;
	wire        emu_AUDIO_S;
	wire  [1:0] emu_AUDIO_MIX;
	wire        emu_DDRAM_CLK;
	wire        emu_DDRAM_BUSY;
	wire  [7:0] emu_DDRAM_BURSTCNT;
	wire [28:0] emu_DDRAM_ADDR;
	wire [63:0] emu_DDRAM_DOUT, emu_DDRAM_DIN;
	wire        emu_DDRAM_DOUT_READY, emu_DDRAM_RD, emu_DDRAM_WE;
	wire  [7:0] emu_DDRAM_BE;

	emu emu_inst (
		.CLK_50M          (clk_50),
		.RESET            (reset),
		.HPS_BUS          (HPS_BUS),

		.CLK_VIDEO        (emu_CLK_VIDEO),
		.CE_PIXEL         (emu_CE_PIXEL),
		.VIDEO_ARX        (emu_VIDEO_ARX),
		.VIDEO_ARY        (emu_VIDEO_ARY),

		.VGA_R            (emu_VGA_R),
		.VGA_G            (emu_VGA_G),
		.VGA_B            (emu_VGA_B),
		.VGA_HS           (emu_VGA_HS),
		.VGA_VS           (emu_VGA_VS),
		.VGA_DE           (emu_VGA_DE),
		.VGA_F1           (emu_VGA_F1),
		.VGA_SL           (emu_VGA_SL),
		.VGA_SCALER       (emu_VGA_SCALER),
		.VGA_DISABLE      (emu_VGA_DISABLE),

		.HDMI_WIDTH       (12'b0),
		.HDMI_HEIGHT      (12'b0),
		.HDMI_FREEZE      (emu_HDMI_FREEZE),
		.HDMI_BLACKOUT    (emu_HDMI_BLACKOUT),
		.HDMI_BOB_DEINT   (emu_HDMI_BOB_DEINT),

		.FB_EN            (emu_FB_EN),
		.FB_FORMAT        (emu_FB_FORMAT),
		.FB_WIDTH         (emu_FB_WIDTH),
		.FB_HEIGHT        (emu_FB_HEIGHT),
		.FB_BASE          (emu_FB_BASE),
		.FB_STRIDE        (emu_FB_STRIDE),
		.FB_VBL           (emu_FB_VBL),
		.FB_LL            (emu_FB_LL),
		.FB_FORCE_BLANK   (emu_FB_FORCE_BLANK),

		.LED_USER         (emu_LED_USER),
		.LED_POWER        (emu_LED_POWER),
		.LED_DISK         (emu_LED_DISK),
		.BUTTONS          (emu_BUTTONS),

		.CLK_AUDIO        (clk_50),
		.AUDIO_L          (emu_AUDIO_L),
		.AUDIO_R          (emu_AUDIO_R),
		.AUDIO_S          (emu_AUDIO_S),
		.AUDIO_MIX        (emu_AUDIO_MIX),

		.DDRAM_CLK        (emu_DDRAM_CLK),
		.DDRAM_BUSY       (emu_DDRAM_BUSY),
		.DDRAM_BURSTCNT   (emu_DDRAM_BURSTCNT),
		.DDRAM_ADDR       (emu_DDRAM_ADDR),
		.DDRAM_DOUT       (emu_DDRAM_DOUT),
		.DDRAM_DOUT_READY (emu_DDRAM_DOUT_READY),
		.DDRAM_RD         (emu_DDRAM_RD),
		.DDRAM_DIN        (emu_DDRAM_DIN),
		.DDRAM_BE         (emu_DDRAM_BE),
		.DDRAM_WE         (emu_DDRAM_WE),

		.SDRAM_CLK        (SDRAM_CLK),
		.SDRAM_CKE        (SDRAM_CKE),
		.SDRAM_A          (SDRAM_A),
		.SDRAM_BA         (SDRAM_BA),
		.SDRAM_DQ         (SDRAM_DQ),
		.SDRAM_DQML       (SDRAM_DQML),
		.SDRAM_DQMH       (SDRAM_DQMH),
		.SDRAM_nCS        (SDRAM_nCS),
		.SDRAM_nCAS       (SDRAM_nCAS),
		.SDRAM_nRAS       (SDRAM_nRAS),
		.SDRAM_nWE        (SDRAM_nWE),

		.ADC_BUS          (adc_bus),

		.SD_SCK           (),
		.SD_MOSI          (),
		.SD_MISO          (1'b0),
		.SD_CS            (),
		.SD_CD            (1'b0),

		.UART_CTS         (1'b0),
		.UART_RTS         (),
		.UART_RXD         (1'b0),
		.UART_TXD         (),
		.UART_DTR         (),
		.UART_DSR         (1'b0),
		.USER_IN          (7'b0),
		.USER_OUT         (),
		.OSD_STATUS       (1'b0)
	);

	// LEDs: first = LED_USER, rest from switches or off
	assign LEDS = { 6'b0, SWITCHES[1], emu_LED_USER };

endmodule
