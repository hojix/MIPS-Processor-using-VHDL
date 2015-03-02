----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:24:35 10/29/2014 
-- Design Name: 
-- Module Name:    SignExtend - Behavioral 
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

entity SignExtender is
    Port ( SignExtend_In : in  STD_LOGIC_VECTOR (15 downto 0);
           SignExtend_Out : out  STD_LOGIC_VECTOR (31 downto 0);
           SignExtend_Enable : in  STD_LOGIC);
end SignExtender;

architecture Behavioral of SignExtender is
signal temp_data : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
begin
process(SignExtend_In,SignExtend_Enable)
begin
	if SignExtend_Enable = '1' then
		SignExtend_Out(31 downto 16) <= (others => SignExtend_In(15));
	else
		SignExtend_Out(31 downto 16) <= (others => '0');
	end if;
	SignExtend_Out(15 downto 0) <= SignExtend_In(15 downto 0);
end process;
end Behavioral;

