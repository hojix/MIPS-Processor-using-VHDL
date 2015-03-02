----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:22:36 10/30/2014 
-- Design Name: 
-- Module Name:    Multiplexer - Behavioral 
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

entity Multiplexer is
	generic ( width : integer := 32 );
	port( A : in STD_LOGIC_VECTOR(width-1 downto 0);
			B : in STD_LOGIC_VECTOR(width-1 downto 0);
			SELECT_BIT : in STD_LOGIC;
			DATA_OUT : out STD_LOGIC_VECTOR(width-1 downto 0));
			
end Multiplexer;

architecture Behavioral of Multiplexer is

begin
process(A,B,SELECT_BIT)
begin
	if SELECT_BIT = '1' then
		DATA_OUT <= A;
	else
		DATA_OUT <= B;
	end if;
end process;

end Behavioral;

