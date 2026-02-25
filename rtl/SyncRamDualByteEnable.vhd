library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
   -- Xilinx UG901: True dual-port BRAM with byte-wide write enable, NO_CHANGE mode.
   -- Shared variable so both ports can read/write; two processes for BRAM inference.
   constant SIZE : integer := 2**ADDR_WIDTH;
   subtype word_t is std_logic_vector(BYTES*BYTE_WIDTH - 1 downto 0);
   type ram_type is array (0 to SIZE - 1) of word_t;

   shared variable RAM : ram_type := (0 to SIZE - 1 => (others => '0'));

   signal reg_a, reg_b : word_t := (others => '0');

   -- Byte enable = we and be (per byte)
   signal wea_vec : std_logic_vector(BYTES - 1 downto 0);
   signal web_vec : std_logic_vector(BYTES - 1 downto 0);

begin
   wea_vec <= (BYTES - 1 downto 0 => we_a) and be_a;
   web_vec <= (BYTES - 1 downto 0 => we_b) and be_b;

   gsynth : if is_simu = '0' generate
   begin
      ------- Port A (NO_CHANGE: output only updated when not writing) -------
      process(clk)
      begin
         if rising_edge(clk) then
            if (wea_vec = (BYTES - 1 downto 0 => '0')) then
               reg_a <= RAM(addr_a);
            end if;

            -- Byte-wide write enable on Port A (assumes BYTES = 4)
            if wea_vec(0) = '1' then
               RAM(addr_a)(BYTE_WIDTH*1 - 1 downto BYTE_WIDTH*0) := datain_a0;
            end if;
            if wea_vec(1) = '1' then
               RAM(addr_a)(BYTE_WIDTH*2 - 1 downto BYTE_WIDTH*1) := datain_a1;
            end if;
            if wea_vec(2) = '1' then
               RAM(addr_a)(BYTE_WIDTH*3 - 1 downto BYTE_WIDTH*2) := datain_a2;
            end if;
            if wea_vec(3) = '1' then
               RAM(addr_a)(BYTE_WIDTH*4 - 1 downto BYTE_WIDTH*3) := datain_a3;
            end if;
         end if;
      end process;

      ------- Port B -------
      process(clk)
      begin
         if rising_edge(clk) then
            if (web_vec = (BYTES - 1 downto 0 => '0')) then
               reg_b <= RAM(addr_b);
            end if;

            -- Byte-wide write enable on Port B (assumes BYTES = 4)
            if web_vec(0) = '1' then
               RAM(addr_b)(BYTE_WIDTH*1 - 1 downto BYTE_WIDTH*0) := datain_b0;
            end if;
            if web_vec(1) = '1' then
               RAM(addr_b)(BYTE_WIDTH*2 - 1 downto BYTE_WIDTH*1) := datain_b1;
            end if;
            if web_vec(2) = '1' then
               RAM(addr_b)(BYTE_WIDTH*3 - 1 downto BYTE_WIDTH*2) := datain_b2;
            end if;
            if web_vec(3) = '1' then
               RAM(addr_b)(BYTE_WIDTH*4 - 1 downto BYTE_WIDTH*3) := datain_b3;
            end if;
         end if;
      end process;

      dataout_a <= reg_a;
      dataout_b <= reg_b;
   end generate;

   -- Simulation: same RTL so behavior matches synthesis
   gsimu : if is_simu = '1' generate
   begin
      process(clk)
      begin
         if rising_edge(clk) then
            if (wea_vec = (BYTES - 1 downto 0 => '0')) then
               reg_a <= RAM(addr_a);
            end if;

            if wea_vec(0) = '1' then
               RAM(addr_a)(BYTE_WIDTH*1 - 1 downto BYTE_WIDTH*0) := datain_a0;
            end if;
            if wea_vec(1) = '1' then
               RAM(addr_a)(BYTE_WIDTH*2 - 1 downto BYTE_WIDTH*1) := datain_a1;
            end if;
            if wea_vec(2) = '1' then
               RAM(addr_a)(BYTE_WIDTH*3 - 1 downto BYTE_WIDTH*2) := datain_a2;
            end if;
            if wea_vec(3) = '1' then
               RAM(addr_a)(BYTE_WIDTH*4 - 1 downto BYTE_WIDTH*3) := datain_a3;
            end if;
         end if;
      end process;

      process(clk)
      begin
         if rising_edge(clk) then
            if (web_vec = (BYTES - 1 downto 0 => '0')) then
               reg_b <= RAM(addr_b);
            end if;

            if web_vec(0) = '1' then
               RAM(addr_b)(BYTE_WIDTH*1 - 1 downto BYTE_WIDTH*0) := datain_b0;
            end if;
            if web_vec(1) = '1' then
               RAM(addr_b)(BYTE_WIDTH*2 - 1 downto BYTE_WIDTH*1) := datain_b1;
            end if;
            if web_vec(2) = '1' then
               RAM(addr_b)(BYTE_WIDTH*3 - 1 downto BYTE_WIDTH*2) := datain_b2;
            end if;
            if web_vec(3) = '1' then
               RAM(addr_b)(BYTE_WIDTH*4 - 1 downto BYTE_WIDTH*3) := datain_b3;
            end if;
         end if;
      end process;

      dataout_a <= reg_a;
      dataout_b <= reg_b;
   end generate;

end rtl;
