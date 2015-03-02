----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:56:37 11/10/2014 
-- Design Name: 
-- Module Name:    HiLoReg - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity HiLoReg is
    Port ( READ_HILODATA : out  STD_LOGIC_VECTOR (63 downto 0);
           WRITE_HILODATA : in  STD_LOGIC_VECTOR (63 downto 0);
           WRITE_REG : in  STD_LOGIC;
           CLK : in  STD_LOGIC);
end HiLoReg;

architecture Behavioral of HiLoReg is
signal REG_DATA : STD_LOGIC_VECTOR (63 downto 0) := (others => '0');
begin
READ_HILODATA <= REG_DATA;

process(CLK)
begin
	if rising_edge(CLK) then
		if WRITE_REG = '1' then
			REG_DATA <= WRITE_HILODATA;
		end if;
	end if;
end process;

end Behavioral;

