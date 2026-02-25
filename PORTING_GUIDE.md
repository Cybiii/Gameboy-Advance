# Porting GBA_MiSTer to Vivado / AUP-ZU3 (xczu3eg-sfvc784-2-e)

This guide describes how to build and run the GBA core on the **AUP-ZU3** board (AMD Zynq UltraScale+ **XCZU3EG-2-SFVC784E**) using **Vivado** instead of Quartus.

---

## 1. What the port provides

- **Vivado project** (Tcl + Makefile) targeting part **xczu3eg-sfvc784-2-e**.
- **ZU3 top** (`aup_zu3/zu3_top.v`) that wraps the existing `emu` (GBA.sv) and connects board I/O.
- **Replacements for MiSTer/Altera-only blocks** (used only when building for ZU3):
  - **PLL**: Xilinx-compatible clocking (board 100 MHz → 50 MHz for `CLK_50M`, and 50→100 MHz for `clk_sys`) in `aup_zu3/pll_xilinx.v`.
  - **hps_io**: Stub in `aup_zu3/hps_io_stub.sv` (same ports, no ARM; default status/buttons so the design builds and resets).
  - **ddram**: Stub in `aup_zu3/ddram_stub.sv` (same channel interface; returns zeros / no real DDR). Lets the design synthesize; for real gameplay you need a real memory backend (e.g. BRAM or PS DDR).
- **Constraints** in `aup_zu3/zu3.xdc` (LEDs, buttons, switches; 100 MHz clock pin must be set from your board schematic).
- **build_id**: `aup_zu3/build_id.v` so `GBA.sv` compiles without Quartus.

---

## 2. Prerequisites

- **Vivado** (2020.2 or newer; Standard or ML Edition).
- **AUP-ZU3** part: `xczu3eg-sfvc784-2-e`.
- Board 100 MHz reference clock wired to a known PL pin (see board docs/schematic); set in `zu3.xdc`.

---

## 3. Source layout for Vivado

When building for ZU3, Vivado must see:

1. **Top**: `aup_zu3/zu3_top.v` (top-level; instantiates `emu` and board I/O).
2. **GBA core + emu**: `GBA.sv`, and all sources referenced by `GBA.sv` and the core:
   - From **rtl**: all files in `rtl/gba.qip` and `rtl/mem.qip` (VHDL), plus `rtl/sdram.sv`, `rtl/ddram.sv` → **replaced by** `aup_zu3/ddram_stub.sv` (do **not** add `rtl/ddram.sv`).
   - From **sys**: only what `emu` uses: `sys/hps_io.sv` → **replaced by** `aup_zu3/hps_io_stub.sv` (do **not** add `sys/hps_io.sv`), plus `sys/video_mixer.sv`, `sys/video_freak.sv`, and any other sys modules that GBA.sv or the video path pull in.
3. **PLL**: Do **not** add `rtl/pll.v` or `rtl/pll/pll_0002.v`. Add **only** `aup_zu3/pll_xilinx.v` (same module name `pll`, so `GBA.sv` does not change).
4. **build_id**: Add `aup_zu3/build_id.v` and ensure the `GBA.sv` include path can see it (or copy into project root). `build_id.v` should define `BUILD_DATE` (e.g. ``define BUILD_DATE "250218"``).
5. **Constraints**: `aup_zu3/zu3.xdc`.

You can either:
- Use the **Makefile + Tcl** in `aup_zu3/` to add sources and run synth/impl, or  
- Create a Vivado project manually and add the same files, with the replacements above.

---

## 4. Clock and reset

- **Board**: 100 MHz (single-ended or differential; pin from schematic).
- **zu3_top**:
  - Buffers the board clock (e.g. `IBUFDS` if differential, or `IBUF` if single-ended) and produces `clk_100`.
  - Divides to 50 MHz (e.g. reg toggle) → `clk_50`.
  - Feeds `emu.CLK_50M = clk_50`, `emu.RESET = ~btn_reset_n` (or similar).
- **Inside emu**: `pll` (now `pll_xilinx.v`) gets `refclk = CLK_50M` (50 MHz) and outputs:
  - `outclk_0` ≈ 100 MHz → `clk_sys`
  - `outclk_1` ≈ 50 MHz → `CLK_VIDEO` (or similar)
  So the core still sees the same clock relationship as on MiSTer.

---

## 5. Memory (SDRAM / DDR)

- **Current MiSTer**: ROM and WRam come from either `sdram` (external SDRAM) or `ddram` (DE10-Nano DDR3 via HPS).
- **AUP-ZU3**: The 8 GB DDR4 is typically on the **PS** (ARM), not the PL. There is no drop-in “ddram” for ZU3.
- **For synthesis only**: Use `ddram_stub.sv` so that all channel requests complete with zero data. The design will build and boot but will not run a real game until you add a real memory source.
- **For real gameplay** you will need one of:
  - **PL SDRAM**: If the board has an SDRAM chip on the PL, use the existing `rtl/sdram.sv` and add the correct pins to `zu3.xdc`; do **not** use `ddram_stub` for the channels that feed ROM/WRam (or use a mux).
  - **BRAM**: Implement a BRAM-based backend that satisfies the same channel interface as `ddram` (and optionally load a small ROM at build time or via a loader).
  - **PS DDR via AXI**: A more advanced option is to add an AXI master in the PL that talks to the PS’s DDR and adapts it to the ddram channel interface.

---

## 6. Video and audio

- **Video**: `emu` drives VGA/HDMI-style outputs. On AUP-ZU3 you can leave them unconnected for a first pass, or route them to Mini DisplayPort / PMOD if you have a design for that.
- **Audio**: Same idea; can be left unconnected or wired later to the board’s I2S codec.

---

## 7. Build steps (high level)

1. Generate **build_id.v** (e.g. run `make build_id` in `aup_zu3/` or copy the provided one).
2. Set the **100 MHz clock pin** (and optionally differential pair) in `zu3.xdc` to match your board.
3. In Vivado (or via Makefile):
   - Create project for part **xczu3eg-sfvc784-2-e**.
   - Add all RTL sources as above, **using** `pll_xilinx.v`, `hps_io_stub.sv`, and `ddram_stub.sv`, and **excluding** the Altera/MiSTer-specific originals.
   - Set top module to **zu3_top**.
   - Add **zu3.xdc**.
   - Run **Synthesis** → **Implementation** → **Generate Bitstream**.
4. Program the FPGA with the generated bitstream (e.g. **Program Device** in Vivado, or `make program` if wired in the Makefile).

---

## 8. Typical issues

- **Missing build_id.v**: Ensure `build_id.v` is in the include path and defines `BUILD_DATE`.
- **PLL not found**: Do not add `rtl/pll.v`; use only `aup_zu3/pll_xilinx.v`.
- **hps_io / video_calc**: Use `hps_io_stub.sv` and do not add `sys/hps_io.sv` (the real one pulls in video_calc and ARM protocol).
- **DDRAM_BUSY**: The stub ties it low so the “DDR” path always appears idle.
- **SDRAM**: If you are not using external SDRAM, ensure `sdram_en` in the core is 0 so only the ddram path is used (stub will then serve zeros). If you add real SDRAM later, add the correct pins to the XDC and use `rtl/sdram.sv`.

---

## 9. Part number summary

| Item        | Value                    |
|------------|---------------------------|
| FPGA       | Xilinx Zynq UltraScale+   |
| Part       | **xczu3eg-sfvc784-2-e**  |
| Board      | RealDigital AUP-ZU3       |
| Package    | SFVC784                   |
| Speed grade| -2                        |

Use this part in the Vivado project and in any Tcl scripts (e.g. `set part "xczu3eg-sfvc784-2-e"`).

---

## 10. Quick start (aup_zu3 folder)

Files added under **aup_zu3/**:

| File | Purpose |
|------|--------|
| **zu3_top.v** | Top-level: 100 MHz clock, buttons/switches/LEDs, instantiates `emu` |
| **pll_xilinx.v** | Xilinx PLL replacement (same ports as `pll`; 50 MHz → 100/50 MHz) |
| **hps_io_stub.sv** | Stub for `hps_io` (no ARM; default status/buttons) |
| **ddram_stub.sv** | Stub for `ddram` (returns zeros; no real DDR) |
| **build_id.v** | Defines `BUILD_DATE` for GBA.sv |
| **zu3.xdc** | Constraints for LEDs, buttons, switches; **set 100 MHz clock pins from schematic** |
| **scripts/create_project.tcl** | Creates Vivado project and adds sources |
| **Makefile** | `make project`, `make synth`, `make impl` |

**Steps:**

1. **Set the 100 MHz clock pins** in `aup_zu3/zu3.xdc` (see comments there; use the board schematic or Reference Manual).
2. From the repo root:
   - `make -C aup_zu3 project` — create the project.
   - `make -C aup_zu3 synth` — run synthesis (then fix any missing file or define).
   - `make -C aup_zu3 impl` — run implementation and bitstream.
3. Program the FPGA with the generated `.bit` file (e.g. via Vivado Hardware Manager).

If the project fails to create (e.g. missing sys files), open `aup_zu3/scripts/create_project.tcl` and add any required `sys` or `rtl` files that are reported missing.
