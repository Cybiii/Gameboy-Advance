library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SyncRamDualByteEnable is
   generic 
   (
      is_simu     : std_logic;
      is_cyclone5 : std_logic := '0';
      BYTE_WIDTH  : natural := 8;
      ADDR_WIDTH  : natural := 6;
      BYTES       : natural := 4
   );
   port 
   (
      clk        : in std_logic;
      
      addr_a     : in natural range 0 to 2**ADDR_WIDTH - 1;
      datain_a0  : in std_logic_vector((BYTE_WIDTH-1) downto 0);
      datain_a1  : in std_logic_vector((BYTE_WIDTH-1) downto 0);
      datain_a2  : in std_logic_vector((BYTE_WIDTH-1) downto 0);
      datain_a3  : in std_logic_vector((BYTE_WIDTH-1) downto 0);
      dataout_a  : out std_logic_vector((BYTES*BYTE_WIDTH-1) downto 0);
      we_a       : in std_logic := '1';
      be_a       : in  std_logic_vector (BYTES - 1 downto 0);
		            
      addr_b     : in natural range 0 to 2**ADDR_WIDTH - 1;
      datain_b0  : in std_logic_vector((BYTE_WIDTH-1) downto 0);
      datain_b1  : in std_logic_vector((BYTE_WIDTH-1) downto 0);
      datain_b2  : in std_logic_vector((BYTE_WIDTH-1) downto 0);
      datain_b3  : in std_logic_vector((BYTE_WIDTH-1) downto 0);
      dataout_b  : out std_logic_vector((BYTES*BYTE_WIDTH-1) downto 0);
      we_b       : in std_logic := '1';
      be_b       : in  std_logic_vector (BYTES - 1 downto 0)
   );
end;

architecture rtl of SyncRamDualByteEnable is
	-- Flat 1D array so Vivado infers block RAM (avoids "RAM from Record/Structs")
	subtype word_t is std_logic_vector(BYTES*BYTE_WIDTH - 1 downto 0);
	type ram_t is array (0 to 2 ** ADDR_WIDTH - 1) of word_t;

	signal ram : ram_t := (others => (others => '0'));
	attribute ram_style : string;
	attribute ram_style of ram : signal is "block";

	signal q1_local : word_t;
	signal q2_local : word_t;
begin

   -- Synthesis: single process, one write per cycle (port A priority), so Vivado infers block RAM
   gsynth : if is_simu = '0' generate
   begin
      unpack: for i in 0 to BYTES - 1 generate
         dataout_a(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i) <= q1_local(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i);
         dataout_b(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i) <= q2_local(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i);
      end generate unpack;

      process(clk)
         variable va, vb : word_t;
      begin
         if rising_edge(clk) then
            va := ram(addr_a);
            vb := ram(addr_b);
            q1_local <= va;
            q2_local <= vb;
            -- One write per cycle (port A has priority when both write)
            if we_a = '1' then
               if be_a(0) = '1' then va(BYTE_WIDTH*1 - 1 downto BYTE_WIDTH*0) := datain_a0; end if;
               if be_a(1) = '1' then va(BYTE_WIDTH*2 - 1 downto BYTE_WIDTH*1) := datain_a1; end if;
               if be_a(2) = '1' then va(BYTE_WIDTH*3 - 1 downto BYTE_WIDTH*2) := datain_a2; end if;
               if be_a(3) = '1' then va(BYTE_WIDTH*4 - 1 downto BYTE_WIDTH*3) := datain_a3; end if;
               ram(addr_a) <= va;
            elsif we_b = '1' then
               if be_b(0) = '1' then vb(BYTE_WIDTH*1 - 1 downto BYTE_WIDTH*0) := datain_b0; end if;
               if be_b(1) = '1' then vb(BYTE_WIDTH*2 - 1 downto BYTE_WIDTH*1) := datain_b1; end if;
               if be_b(2) = '1' then vb(BYTE_WIDTH*3 - 1 downto BYTE_WIDTH*2) := datain_b2; end if;
               if be_b(3) = '1' then vb(BYTE_WIDTH*4 - 1 downto BYTE_WIDTH*3) := datain_b3; end if;
               ram(addr_b) <= vb;
            end if;
         end if;
      end process;
   end generate;

   gsimu : if is_simu = '1' generate
   begin
      unpack: for i in 0 to BYTES - 1 generate
         dataout_a(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i) <= q1_local(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i);
         dataout_b(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i) <= q2_local(BYTE_WIDTH*(i+1) - 1 downto BYTE_WIDTH*i);
      end generate unpack;

      process(clk)
         variable va, vb : word_t;
      begin
         if rising_edge(clk) then
            va := ram(addr_a);
            vb := ram(addr_b);
            q1_local <= va;
            q2_local <= vb;
            if we_a = '1' then
               if be_a(0) = '1' then va(BYTE_WIDTH*1 - 1 downto BYTE_WIDTH*0) := datain_a0; end if;
               if be_a(1) = '1' then va(BYTE_WIDTH*2 - 1 downto BYTE_WIDTH*1) := datain_a1; end if;
               if be_a(2) = '1' then va(BYTE_WIDTH*3 - 1 downto BYTE_WIDTH*2) := datain_a2; end if;
               if be_a(3) = '1' then va(BYTE_WIDTH*4 - 1 downto BYTE_WIDTH*3) := datain_a3; end if;
               ram(addr_a) <= va;
            elsif we_b = '1' then
               if be_b(0) = '1' then vb(BYTE_WIDTH*1 - 1 downto BYTE_WIDTH*0) := datain_b0; end if;
               if be_b(1) = '1' then vb(BYTE_WIDTH*2 - 1 downto BYTE_WIDTH*1) := datain_b1; end if;
               if be_b(2) = '1' then vb(BYTE_WIDTH*3 - 1 downto BYTE_WIDTH*2) := datain_b2; end if;
               if be_b(3) = '1' then vb(BYTE_WIDTH*4 - 1 downto BYTE_WIDTH*3) := datain_b3; end if;
               ram(addr_b) <= vb;
            end if;
         end if;
      end process;
   end generate;
  
end rtl;