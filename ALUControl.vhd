----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:03:40 10/30/2014 
-- Design Name: 
-- Module Name:    ALUControl - arch_alucontrol 
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

entity ALUControl is
    Port ( ALUOp : in  STD_LOGIC_VECTOR (2 downto 0);
           funct : in  STD_LOGIC_VECTOR (5 downto 0);
			  HiLoWrite	: out STD_LOGIC;
			  HiLoSelect	: out STD_LOGIC;
			  MovetoReg	: out STD_LOGIC;
			  JumptoPC	: out STD_LOGIC;
			  Shift		: out STD_LOGIC;
           ALUCtrl : out  STD_LOGIC_VECTOR (4 downto 0));
end ALUControl;

architecture arch_alucontrol of ALUControl is

begin
process(ALUOp, funct)
--hiloselect
--mfhi 1
--mflo 0

--movetoreg
--mfhi/mflo 1

--hilowrite
--mult/multu 1

--jumptoPC
--jr 1

begin

case ALUOp is
when "000" => -- add
	ALUCtrl <= "00010";
	HiLoWrite <= '0';
	MovetoReg <= '0';
	HiLoSelect <= '0';
	JumptoPC <= '0';
	Shift <= '0';
when "001" => -- sub
	ALUCtrl <= "00110";
	HiLoWrite <= '0';
	MovetoReg <= '0';
	HiLoSelect <= '0';
	JumptoPC <= '0';
	Shift <= '0';
when "111" => -- slt
	ALUCtrl <= "00111";
	HiLoWrite <= '0';
	MovetoReg <= '0';
	HiLoSelect <= '0';
	JumptoPC <= '0';
	Shift <= '0';
when "010" => -- r-type
	case funct is
		when "011010" =>
			--div
			ALUCtrl <= "10010";
			HiLoWrite <= '1';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
			
		when "011011" =>
			--divu
			ALUCtrl <= "10011";
			HiLoWrite <= '1';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
			
		when "001000" =>
			--jr
			ALUCtrl <= "11111";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '1';
			Shift <= '0';
			
		when "001001" =>
		--jalr
			ALUCtrl <= "11111";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '1';
			Shift <= '0';
			
		when "010000" =>
			--mfhi
			ALUCtrl <= "11111";
			HiLoWrite <= '0';
			MovetoReg <= '1';
			HiLoSelect <= '1';
			JumptoPC <= '0';
			Shift <= '0';
			
		when "010010" =>
			--mflo
			ALUCtrl <= "11111";
			HiLoWrite <= '0';
			MovetoReg <= '1';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
			
		when "100000" =>
			--add
			ALUCtrl <= "00010";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
			
		when "100010" =>
			--sub
			ALUCtrl <= "00110";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
			
		when "011000" =>
			--mult
			ALUCtrl <= "10000";
			HiLoWrite <= '1';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
			
		when "011001" =>
			--multu
			ALUCtrl <= "10001";
			HiLoWrite <= '1';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
			
		when "100100" =>
			--and
			ALUCtrl <= "00000";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
			
		when "100111" =>
			--nor
			ALUCtrl <= "01100";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
		
		when "100110" =>
			--xor
			ALUCtrl <= "00100";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
			
		when "100101" =>
			--or
			ALUCtrl <= "00001";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
		
		when "000100" =>
			--sllv
			ALUCtrl <= "00101";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
					
		when "000000" =>
			--sll
			ALUCtrl <= "00101";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '1';
			
		when "000111" =>
			--srav
			ALUCtrl <= "01001";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
		
		when "000011" =>
			--sra
			ALUCtrl <= "01001";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '1';
								
		when "000110" =>
			--srlv
			ALUCtrl <= "01101";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
		
		when "000010" =>
			--srl
			ALUCtrl <= "01101";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '1';
			
		when "101010" =>
			--slt
			ALUCtrl <= "00111";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
			
		when "101011" =>
			--sltu
			ALUCtrl <= "01110";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
			
		when others => 
			ALUCtrl <= "11111";
			HiLoWrite <= '0';
			MovetoReg <= '0';
			HiLoSelect <= '0';
			JumptoPC <= '0';
			Shift <= '0';
	end case;
when "011" => -- or
	ALUCtrl <= "00001";
	HiLoWrite <= '0';
	MovetoReg <= '0';
	HiLoSelect <= '0';
	JumptoPC <= '0';
	Shift <= '0';
when others => 
	ALUCtrl <= "11111";
	HiLoWrite <= '0';
	MovetoReg <= '0';
	HiLoSelect <= '0';
	JumptoPC <= '0';
	Shift <= '0';
end case;
end process;
end arch_alucontrol;

