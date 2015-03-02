----------------------------------------------------------------------------------
-- Company: NUS
-- Engineer: Rajesh Panicker
-- 
-- Create Date:   21:06:18 14/10/2014
-- Design Name: 	ControlUnit
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool versions: ISE 14.7
-- Description: Control Unit for the basic MIPS processor
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: The interface (entity) as well as implementation (architecture) can be modified
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;

entity ControlUnit is
    Port ( 	opcode 		: in  STD_LOGIC_VECTOR (5 downto 0);
				ALUOp 		: out  STD_LOGIC_VECTOR (2 downto 0);
				Branch 		: out  STD_LOGIC;
				BranchGEZ	: out  STD_LOGIC;
				Jump	 		: out  STD_LOGIC;	
				JumpLink	 	: out  STD_LOGIC;	
				LinktoReg	: out  STD_LOGIC;	
				MemRead 		: out  STD_LOGIC;	
				MemtoReg 	: out  STD_LOGIC;
				InstrtoReg	: out  STD_LOGIC;
				MemWrite		: out  STD_LOGIC;	
				ALUSrc 		: out  STD_LOGIC;	
				SignExtend 	: out  STD_LOGIC;
				RegWrite		: out  STD_LOGIC;
				RegDst		: out  STD_LOGIC);
end ControlUnit;


architecture arch_ControlUnit of ControlUnit is  
begin   

--<implement control unit here>
process(opcode)
begin
	case opcode is
	
	when "100011" =>
		--lw
		ALUOp <= "000";
		Branch <= '0';
		Jump <= '0';
		JumpLink <= '0';
		LinktoReg <= '0';
		MemRead <= '1';
		MemtoReg <= '1';
		InstrtoReg <= '0';
		MemWrite <= '0';
		ALUSrc <= '1';
		SignExtend <= '1';
		RegWrite <= '1';
		RegDst <= '0';
		BranchGEZ <= '0';
	
	when "101011" =>
		--sw
		ALUOp <= "000";
		Branch <= '0';
		Jump <= '0';
		JumpLink <= '0';
		LinktoReg <= '0';
		MemRead <= '0';
		MemtoReg <= '0';
		InstrtoReg <= '0';
		MemWrite <= '1';
		ALUSrc <= '1';
		SignExtend <= '1';
		RegWrite <= '0';
		RegDst <= '0';
		BranchGEZ <= '0';
	
	when "000000" =>
		--rtype
		ALUOp <= "010";
		ALUSrc <= '0';
		Branch <= '0';
		Jump <= '0';
		JumpLink <= '0';
		LinktoReg <= '0';
		MemRead <= '0';
		MemWrite <= '0';
		MemtoReg <= '0';
		RegWrite <= '1';
		SignExtend <= '0';
		RegDst <= '1';
		InstrtoReg <= '0';
		BranchGEZ <= '0';

	when "001111" =>
		--lui
		ALUOp <= "000";
		Branch <= '0';
		Jump <= '0';
		JumpLink <= '0';
		LinktoReg <= '0';
		MemRead <= '0';
		MemtoReg <= '0';
		InstrtoReg <= '1';
		MemWrite <= '0';
		ALUSrc <= '0';
		SignExtend <= '0';
		RegWrite <= '1';
		RegDst <= '0';
		BranchGEZ <= '0';
		
	when "001101" =>
		--ori
		ALUOp <= "011";
		Branch <= '0';
		Jump <= '0';
		JumpLink <= '0';
		LinktoReg <= '0';
		MemRead <= '0';
		MemtoReg <= '0';
		InstrtoReg <= '0';
		MemWrite <= '0';
		ALUSrc <= '1';
		SignExtend <= '0';
		RegWrite <= '1';
		RegDst <= '0';
		BranchGEZ <= '0';
	
	when "000100" =>
		--beq
		ALUOp <= "001";
		ALUSrc <= '0';
		Branch <= '1';
		Jump <= '0';
		JumpLink <= '0';
		LinktoReg <= '0';
		MemRead <= '0';
		MemWrite <= '0';
		MemtoReg <= '0';
		RegWrite <= '0';
		SignExtend <= '1';
		RegDst <= '0';
		InstrtoReg <= '0';
		BranchGEZ <= '0';
	
	when "000001" =>
		--bgez / bgezal
		ALUOp <= "001";
		ALUSrc <= '0';
		Branch <= '1';
		Jump <= '0';
		JumpLink <= '0';
		LinktoReg <= '0';
		MemRead <= '0';
		MemWrite <= '0';
		MemtoReg <= '0';
		RegWrite <= '0';
		SignExtend <= '1';
		RegDst <= '0';
		InstrtoReg <= '0';
		BranchGEZ <= '1';
	
		when "001000"=>
		--addi
		ALUOp <= "000";
		Branch <= '0';
		Jump <= '0';
		JumpLink <= '0';
		LinktoReg <= '0';
		MemRead <= '0';
		MemtoReg <= '0';
		InstrtoReg <= '0';
		MemWrite <= '0';
		ALUSrc <= '1';
		SignExtend <= '1';
		RegWrite <= '1';
		RegDst <= '0';
		BranchGEZ <= '0';
		
		when "001001"=>
		--addiu
		ALUOp <= "000";
		Branch <= '0';
		Jump <= '0';
		JumpLink <= '0';
		LinktoReg <= '0';
		MemRead <= '0';
		MemtoReg <= '0';
		InstrtoReg <= '0';
		MemWrite <= '0';
		ALUSrc <= '1';
		SignExtend <= '1';
		RegWrite <= '1';
		RegDst <= '0';
		BranchGEZ <= '0';
	
		when "001010" =>
		--slti
		ALUOp <= "111";
		Branch <= '0';
		Jump <= '0';
		JumpLink <= '0';
		LinktoReg <= '0';
		MemRead <= '0';
		MemtoReg <= '0';
		InstrtoReg <= '0';
		MemWrite <= '0';
		ALUSrc <= '1';
		SignExtend <= '1';
		RegWrite <= '1';
		RegDst <= '0';
		BranchGEZ <= '0';

--	when "000001" =>
--		--bgezal
--		ALUOp <= "01";
--		ALUSrc <= '0';
--		Branch <= '1';
--		Jump <= '0';
--		JumpLink <= '0';
--		LinktoReg <= '1';
--		MemRead <= '0';
--		MemWrite <= '0';
--		MemtoReg <= '0';
--		RegWrite <= '1';
--		SignExtend <= '1';
--		RegDst <= '0';
--		InstrtoReg <= '0';
--		BranchGEZ <= '1';
		
	when "000010" =>
		--j
		ALUOp <= "001";
		Branch <= '0';
		Jump <= '1';
		JumpLink <= '0';
		LinktoReg <= '0';
		MemRead <= '0';
		MemtoReg <= '0';
		InstrtoReg <= '0';
		MemWrite <= '0';
		ALUSrc <= '0';
		SignExtend <= '0';
		RegWrite <= '0';
		RegDst <= '0';
		BranchGEZ <= '0';
	
	when "000011" =>
		--jal
		ALUOp <= "001";
		Branch <= '0';
		Jump <= '1';
		JumpLink <= '1';
		LinktoReg <= '1';
		MemRead <= '0';
		MemtoReg <= '0';
		InstrtoReg <= '0';
		MemWrite <= '0';
		ALUSrc <= '0';
		SignExtend <= '0';
		RegWrite <= '1';
		RegDst <= '0';
		BranchGEZ <= '0';
	
	when others =>
		--others
		ALUOp <= "000";
		Branch <= '0';
		Jump <= '0';
		JumpLink <= '0';
		LinktoReg <= '0';
		MemRead <= '0';
		MemtoReg <= '0';
		InstrtoReg <= '0';
		MemWrite <= '0';
		ALUSrc <= '0';
		SignExtend <= '0';
		RegWrite <= '0';
		RegDst <= '0';
		BranchGEZ <= '0';
	end case;
		
end process;
end arch_ControlUnit;

