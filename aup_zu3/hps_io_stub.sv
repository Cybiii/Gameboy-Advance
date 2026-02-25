//============================================================================
// Stub for hps_io when building for AUP-ZU3 (no ARM HPS). Same interface as
// sys/hps_io.sv so emu compiles; all outputs are safe defaults (no ROM load,
// no OSD, status/buttons zero). Use this instead of sys/hps_io.sv in Vivado.
//============================================================================
module hps_io #(
	parameter CONF_STR = "",
	parameter CONF_STR_BRAM = 0,
	parameter PS2DIV = 0,
	parameter WIDE = 0,
	parameter VDNUM = 1,
	parameter BLKSZ = 2,
	parameter PS2WE = 0,
	parameter STRLEN = 256
)(
	input             clk_sys,
	inout      [48:0] HPS_BUS,

	output reg [31:0] joystick_0 = 0,
	output reg [31:0] joystick_1 = 0,
	output reg [31:0] joystick_2 = 0,
	output reg [31:0] joystick_3 = 0,
	output reg [31:0] joystick_4 = 0,
	output reg [31:0] joystick_5 = 0,

	output reg [15:0] joystick_l_analog_0 = 0,
	output reg [15:0] joystick_l_analog_1 = 0,
	output reg [15:0] joystick_l_analog_2 = 0,
	output reg [15:0] joystick_l_analog_3 = 0,
	output reg [15:0] joystick_l_analog_4 = 0,
	output reg [15:0] joystick_l_analog_5 = 0,

	output reg [15:0] joystick_r_analog_0 = 0,
	output reg [15:0] joystick_r_analog_1 = 0,
	output reg [15:0] joystick_r_analog_2 = 0,
	output reg [15:0] joystick_r_analog_3 = 0,
	output reg [15:0] joystick_r_analog_4 = 0,
	output reg [15:0] joystick_r_analog_5 = 0,

	input      [15:0] joystick_0_rumble,
	input      [15:0] joystick_1_rumble,
	input      [15:0] joystick_2_rumble,
	input      [15:0] joystick_3_rumble,
	input      [15:0] joystick_4_rumble,
	input      [15:0] joystick_5_rumble,

	output reg  [7:0] paddle_0 = 0,
	output reg  [7:0] paddle_1 = 0,
	output reg  [7:0] paddle_2 = 0,
	output reg  [7:0] paddle_3 = 0,
	output reg  [7:0] paddle_4 = 0,
	output reg  [7:0] paddle_5 = 0,

	output reg  [8:0] spinner_0 = 0,
	output reg  [8:0] spinner_1 = 0,
	output reg  [8:0] spinner_2 = 0,
	output reg  [8:0] spinner_3 = 0,
	output reg  [8:0] spinner_4 = 0,
	output reg  [8:0] spinner_5 = 0,

	output            ps2_kbd_clk_out,
	output            ps2_kbd_data_out,
	input             ps2_kbd_clk_in,
	input             ps2_kbd_data_in,
	input       [2:0] ps2_kbd_led_status,
	input       [2:0] ps2_kbd_led_use,
	output            ps2_mouse_clk_out,
	output            ps2_mouse_data_out,
	input             ps2_mouse_clk_in,
	input             ps2_mouse_data_in,
	output reg [10:0] ps2_key = 0,
	output reg [24:0] ps2_mouse = 0,
	output reg [15:0] ps2_mouse_ext = 0,

	output      [1:0] buttons,
	output            forced_scandoubler,
	output            direct_video,
	input             video_rotated,
	input             new_vmode,
	inout      [21:0] gamma_bus,

	output reg [127:0] status = 0,
	input      [127:0] status_in,
	input              status_set,
	input       [15:0] status_menumask,
	input             info_req,
	input       [7:0] info,

	output reg [VDNUM-1:0] img_mounted = 0,
	output reg        img_readonly = 0,
	output reg [63:0] img_size = 0,

	input      [31:0] sd_lba [VDNUM],
	input       [5:0] sd_blk_cnt [VDNUM],
	input      [VDNUM-1:0] sd_rd,
	input      [VDNUM-1:0] sd_wr,
	output reg [VDNUM-1:0] sd_ack = 0,

	output reg [(WIDE ? 12 : 13):0] sd_buff_addr = 0,
	output reg [(WIDE ? 15 : 7):0] sd_buff_dout = 0,
	input      [(WIDE ? 15 : 7):0] sd_buff_din [VDNUM],
	output reg        sd_buff_wr = 0,

	output reg        ioctl_download = 0,
	output reg [15:0] ioctl_index = 0,
	output reg        ioctl_wr = 0,
	output reg [26:0] ioctl_addr = 0,
	output reg [(WIDE ? 15 : 7):0] ioctl_dout = 0,
	output reg        ioctl_upload = 0,
	input             ioctl_upload_req,
	input       [7:0] ioctl_upload_index,
	input      [(WIDE ? 15 : 7):0] ioctl_din,
	output reg        ioctl_rd = 0,
	output reg [31:0] ioctl_file_ext = 0,
	input             ioctl_wait,

	output reg [15:0] sdram_sz = 0,
	output reg [64:0] RTC = 0,
	output reg [32:0] TIMESTAMP = 0,
	output reg  [7:0] uart_mode = 0,
	output reg [31:0] uart_speed = 0,
	inout      [35:0] EXT_BUS
);

	assign buttons = 2'b00;
	assign forced_scandoubler = 1'b0;
	assign direct_video = 1'b0;
	assign ps2_kbd_clk_out = 1'b1;
	assign ps2_kbd_data_out = 1'b1;
	assign ps2_mouse_clk_out = 1'b1;
	assign ps2_mouse_data_out = 1'b1;

	// Drive HPS_BUS bits that the rest of the design may read (no ARM)
	assign HPS_BUS[37]   = 1'b0;       // ioctl_wait
	assign HPS_BUS[36]   = clk_sys;
	assign HPS_BUS[32]   = WIDE ? 1'b1 : 1'b0;
	assign HPS_BUS[15:0] = 16'b0;
	assign HPS_BUS[48:38] = 'Z;
	assign HPS_BUS[31:16] = 'Z;

	assign gamma_bus = 22'bZ;
	assign EXT_BUS = 36'bZ;

endmodule
