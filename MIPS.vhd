----------------------------------------------------------------------------------
-- Company: NUS
-- Engineer: Rajesh Panicker
-- 
-- Create Date:   21:06:18 14/10/2014
-- Design Name: 	MIPS
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool versions: ISE 14.7
-- Description: MIPS processor
--
-- Dependencies: PC, ALU, ControlUnit, RegFile
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: DO NOT modify the interface (entity). Implementation (architecture) can be modified.
--

----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;

entity MIPS is -- DO NOT modify the interface (entity)
    Port ( 	
			Addr_Instr 		: out STD_LOGIC_VECTOR (31 downto 0);
			Instr 			: in STD_LOGIC_VECTOR (31 downto 0);
			Addr_Data		: out STD_LOGIC_VECTOR (31 downto 0);
			Data_In			: in STD_LOGIC_VECTOR (31 downto 0);
			Data_Out			: out  STD_LOGIC_VECTOR (31 downto 0);
			MemRead 			: out STD_LOGIC; 
			MemWrite 		: out STD_LOGIC; 
			RESET				: in STD_LOGIC;
			CLK				: in STD_LOGIC
			);
end MIPS;


architecture arch_MIPS of MIPS is

----------------------------------------------------------------
-- Program Counter
----------------------------------------------------------------
component PC is
	Port(	
			PC_in 	: in STD_LOGIC_VECTOR (31 downto 0);
			PC_out 	: out STD_LOGIC_VECTOR (31 downto 0);
			PC_busy	: in STD_LOGIC;
			RESET		: in STD_LOGIC;
			CLK		: in STD_LOGIC);
end component;

----------------------------------------------------------------
-- ALU
----------------------------------------------------------------
component alu is
	generic (width 	: integer := 32);
	Port (Clk			: in	STD_LOGIC;
			Control		: in	STD_LOGIC_VECTOR (5 downto 0);
			Operand1		: in	STD_LOGIC_VECTOR (width-1 downto 0);
			Operand2		: in	STD_LOGIC_VECTOR (width-1 downto 0);
			Result1		: out	STD_LOGIC_VECTOR (width-1 downto 0);
			Result2		: out	STD_LOGIC_VECTOR (width-1 downto 0);
			Status		: out	STD_LOGIC_VECTOR (2 downto 0));		
end component;

----------------------------------------------------------------
-- Control Unit
----------------------------------------------------------------
component ControlUnit is
    Port ( 	
			opcode 		: in   STD_LOGIC_VECTOR (5 downto 0);
			ALUOp 		: out  STD_LOGIC_VECTOR (2 downto 0);
			Branch 		: out  STD_LOGIC;
			BranchGEZ 		: out  STD_LOGIC;
			Jump	 		: out  STD_LOGIC;
			JumpLink	 	: out  STD_LOGIC;
			LinktoReg	: out  STD_LOGIC;
			MemRead 		: out  STD_LOGIC;	
			MemtoReg 	: out  STD_LOGIC;	
			InstrtoReg	: out  STD_LOGIC; -- true for LUI. When true, Instr(15 downto 0)&x"0000" is written to rt
			MemWrite		: out  STD_LOGIC;	
			ALUSrc 		: out  STD_LOGIC;	
			SignExtend 	: out  STD_LOGIC; -- false for ORI 
			RegWrite		: out  STD_LOGIC;	
			RegDst		: out  STD_LOGIC);
end component;

----------------------------------------------------------------
-- Register File
----------------------------------------------------------------
component RegFile is
    Port ( 	
			ReadAddr1_Reg 	: in  STD_LOGIC_VECTOR (4 downto 0);
			ReadAddr2_Reg 	: in  STD_LOGIC_VECTOR (4 downto 0);
			ReadData1_Reg 	: out STD_LOGIC_VECTOR (31 downto 0);
			ReadData2_Reg 	: out STD_LOGIC_VECTOR (31 downto 0);				
			WriteAddr_Reg	: in  STD_LOGIC_VECTOR (4 downto 0); 
			WriteData_Reg 	: in STD_LOGIC_VECTOR (31 downto 0);
			RegWrite 		: in STD_LOGIC; 
			CLK 				: in  STD_LOGIC);
end component;

----------------------------------------------------------------
-- Hi/Lo Register
----------------------------------------------------------------
component HiLoReg is
    Port ( READ_HILODATA : out  STD_LOGIC_VECTOR (63 downto 0);
           WRITE_HILODATA : in  STD_LOGIC_VECTOR (63 downto 0);
           WRITE_REG : in  STD_LOGIC;
           CLK : in  STD_LOGIC);
end component;

----------------------------------------------------------------
-- Sign Extend
----------------------------------------------------------------
component SignExtender is
    Port ( SignExtend_In 		: in  STD_LOGIC_VECTOR (15 downto 0);
           SignExtend_Out 		: out  STD_LOGIC_VECTOR (31 downto 0);
           SignExtend_Enable 	: in  STD_LOGIC);
end component;

----------------------------------------------------------------
-- ALU Control
----------------------------------------------------------------
component ALUControl is
    Port ( ALUOp 		: in  STD_LOGIC_VECTOR (2 downto 0);
           funct 		: in  STD_LOGIC_VECTOR (5 downto 0);
			  HiLoWrite	: out 	STD_LOGIC;
			  HiLoSelect	: out STD_LOGIC;
			  MovetoReg	: out STD_LOGIC;
			  JumptoPC	: out STD_LOGIC;
			  Shift	: out STD_LOGIC;
           ALUCtrl	: out  STD_LOGIC_VECTOR (4 downto 0));
end component;

----------------------------------------------------------------
-- Adder
----------------------------------------------------------------

component Adder is
    Port ( A 		: in  STD_LOGIC_VECTOR (31 downto 0);
           B 		: in  STD_LOGIC_VECTOR (31 downto 0);
           RESULT	: out  STD_LOGIC_VECTOR (31 downto 0));
end component;

----------------------------------------------------------------
-- Multiplexer
----------------------------------------------------------------
component Multiplexer is
	generic ( width : integer := 32 );
	port( A : in STD_LOGIC_VECTOR(width-1 downto 0);
			B : in STD_LOGIC_VECTOR(width-1 downto 0);
			SELECT_BIT : in STD_LOGIC;
			DATA_OUT : out STD_LOGIC_VECTOR(width-1 downto 0));
end component;

----------------------------------------------------------------
-- Hi/Lo Register Signals
----------------------------------------------------------------
	signal ReadData_HiLoReg : STD_LOGIC_VECTOR (63 downto 0);
	signal WriteData_HiLoReg : STD_LOGIC_VECTOR (63 downto 0);
	signal HiLoRegWrite : STD_LOGIC;

----------------------------------------------------------------
-- BranchGEZAL JumpLink Multiplexer Signals
----------------------------------------------------------------
	signal BLJLMuxInputA	: STD_LOGIC_VECTOR(0 downto 0);
	signal BLJLMuxInputB	: STD_LOGIC_VECTOR(0 downto 0);
	signal BLJLMuxSelect	: STD_LOGIC;
	signal BLJLMuxOutput	: STD_LOGIC_VECTOR(0 downto 0);

----------------------------------------------------------------
-- BranchGEZAL RegWrite Multiplexer Signals
----------------------------------------------------------------
	signal BLRWMuxInputA	: STD_LOGIC_VECTOR(0 downto 0);
	signal BLRWMuxInputB	: STD_LOGIC_VECTOR(0 downto 0);
	signal BLRWMuxSelect	: STD_LOGIC;
	signal BLRWMuxOutput	: STD_LOGIC_VECTOR(0 downto 0);

----------------------------------------------------------------
-- BranchGEZAL LinktoReg Multiplexer Signals
----------------------------------------------------------------
	signal BLLRMuxInputA	: STD_LOGIC_VECTOR(0 downto 0);
	signal BLLRMuxInputB	: STD_LOGIC_VECTOR(0 downto 0);
	signal BLLRMuxSelect	: STD_LOGIC;
	signal BLLRMuxOutput	: STD_LOGIC_VECTOR(0 downto 0);

----------------------------------------------------------------
-- BranchGEZ Multiplexer Signals
----------------------------------------------------------------
	signal BGEZMuxInputA	: STD_LOGIC_VECTOR(0 downto 0);
	signal BGEZMuxInputB	: STD_LOGIC_VECTOR(0 downto 0);
	signal BGEZMuxSelect	: STD_LOGIC;
	signal BGEZMuxOutput	: STD_LOGIC_VECTOR(0 downto 0);

----------------------------------------------------------------
-- ShiftMux Multiplexer Signals
----------------------------------------------------------------
	signal ShiftMuxInputA	: STD_LOGIC_VECTOR(31 downto 0);
	signal ShiftMuxInputB	: STD_LOGIC_VECTOR(31 downto 0);
	signal ShiftMuxSelect	: STD_LOGIC;
	signal ShiftMuxOutput	: STD_LOGIC_VECTOR(31 downto 0);

----------------------------------------------------------------
-- LinkRegMux Multiplexer Signals
----------------------------------------------------------------
	signal LRMuxInputA	: STD_LOGIC_VECTOR(31 downto 0);
	signal LRMuxInputB	: STD_LOGIC_VECTOR(31 downto 0);
	signal LRMuxSelect	: STD_LOGIC;
	signal LRMuxOutput	: STD_LOGIC_VECTOR(31 downto 0);

----------------------------------------------------------------
-- JumpLink Multiplexer Signals
----------------------------------------------------------------
	signal JLMuxInputA	: STD_LOGIC_VECTOR(4 downto 0);
	signal JLMuxInputB	: STD_LOGIC_VECTOR(4 downto 0);
	signal JLMuxSelect	: STD_LOGIC;
	signal JLMuxOutput	: STD_LOGIC_VECTOR(4 downto 0);

----------------------------------------------------------------
-- Move Multiplexer Signals
----------------------------------------------------------------
	signal MoveMuxInputA	: STD_LOGIC_VECTOR(31 downto 0);
	signal MoveMuxInputB	: STD_LOGIC_VECTOR(31 downto 0);
	signal MoveMuxSelect	: STD_LOGIC;
	signal MoveMuxOutput	: STD_LOGIC_VECTOR(31 downto 0);

----------------------------------------------------------------
-- Hi/Lo Multiplexer Signals
----------------------------------------------------------------
	signal HiLoMuxInputA	: STD_LOGIC_VECTOR(31 downto 0);
	signal HiLoMuxInputB	: STD_LOGIC_VECTOR(31 downto 0);
	signal HiLoMuxSelect	: STD_LOGIC;
	signal HiLoMuxOutput	: STD_LOGIC_VECTOR(31 downto 0);

----------------------------------------------------------------
-- JumpReg Multiplexer Signals
----------------------------------------------------------------
	signal JRMuxInputA	: STD_LOGIC_VECTOR(31 downto 0);
	signal JRMuxInputB	: STD_LOGIC_VECTOR(31 downto 0);
	signal JRMuxSelect	: STD_LOGIC;
	signal JRMuxOutput	: STD_LOGIC_VECTOR(31 downto 0);

----------------------------------------------------------------
-- PC Multiplexer Signals
----------------------------------------------------------------
	signal PCMuxInputA	: STD_LOGIC_VECTOR(31 downto 0);
	signal PCMuxInputB	: STD_LOGIC_VECTOR(31 downto 0);
	signal PCMuxSelect	: STD_LOGIC;
	signal PCMuxOutput	: STD_LOGIC_VECTOR(31 downto 0);
	
----------------------------------------------------------------
-- WriteAddr Multiplexer Signals
----------------------------------------------------------------
	signal WAMuxInputA	: STD_LOGIC_VECTOR(4 downto 0);
	signal WAMuxInputB	: STD_LOGIC_VECTOR(4 downto 0);
	signal WAMuxSelect	: STD_LOGIC;
	signal WAMuxOutput	: STD_LOGIC_VECTOR(4 downto 0);
	
----------------------------------------------------------------
-- ALU Multiplexer Signals
----------------------------------------------------------------
	signal ALUMuxInputA	: STD_LOGIC_VECTOR(31 downto 0);
	signal ALUMuxInputB	: STD_LOGIC_VECTOR(31 downto 0);
	signal ALUMuxSelect	: STD_LOGIC;
	signal ALUMuxOutput	: STD_LOGIC_VECTOR(31 downto 0);
	
----------------------------------------------------------------
-- WriteData Multiplexer Signals
----------------------------------------------------------------
	signal WDMuxInputA	: STD_LOGIC_VECTOR(31 downto 0);
	signal WDMuxInputB	: STD_LOGIC_VECTOR(31 downto 0);
	signal WDMuxSelect	: STD_LOGIC;
	signal WDMuxOutput	: STD_LOGIC_VECTOR(31 downto 0);
	
----------------------------------------------------------------
-- Jump Multiplexer Signals
----------------------------------------------------------------
	signal JumpMuxInputA	: STD_LOGIC_VECTOR(31 downto 0);
	signal JumpMuxInputB	: STD_LOGIC_VECTOR(31 downto 0);
	signal JumpMuxSelect	: STD_LOGIC;
	signal JumpMuxOutput	: STD_LOGIC_VECTOR(31 downto 0);
	
----------------------------------------------------------------
-- LUI Multiplexer Signals
----------------------------------------------------------------
	signal LUIMuxInputA	: STD_LOGIC_VECTOR(31 downto 0);
	signal LUIMuxInputB	: STD_LOGIC_VECTOR(31 downto 0);
	signal LUIMuxSelect	: STD_LOGIC;
	signal LUIMuxOutput	: STD_LOGIC_VECTOR(31 downto 0);
	
----------------------------------------------------------------
-- PC+4 Adder Signals
----------------------------------------------------------------
--	signal PC4AdderInputA	: STD_LOGIC_VECTOR (31 downto 0);
--	signal PC4AdderInputB	: STD_LOGIC_VECTOR (31 downto 0);
--	signal PC4AdderResult	: STD_LOGIC_VECTOR (31 downto 0);

----------------------------------------------------------------
-- PC Adder Signals
----------------------------------------------------------------
	signal PCAdderInputA	: STD_LOGIC_VECTOR (31 downto 0);
	signal PCAdderInputB	: STD_LOGIC_VECTOR (31 downto 0);
	signal PCAdderResult	: STD_LOGIC_VECTOR (31 downto 0);

----------------------------------------------------------------
-- Branch Adder Signals
----------------------------------------------------------------
	signal BranchAdderInputA	: STD_LOGIC_VECTOR (31 downto 0);
	signal BranchAdderInputB	: STD_LOGIC_VECTOR (31 downto 0);
	signal BranchAdderResult	: STD_LOGIC_VECTOR (31 downto 0);

----------------------------------------------------------------
-- ALU Control Signals
----------------------------------------------------------------
	signal	funct			: STD_LOGIC_VECTOR (5 downto 0);
	signal	ALUCtrl			: STD_LOGIC_VECTOR (4 downto 0);
	signal	HiLoWrite		: STD_LOGIC;
	signal	HiLoSelect		: STD_LOGIC;
	signal	MovetoReg		: STD_LOGIC;
	signal	JumptoPC		: STD_LOGIC;
	signal	Shift		: STD_LOGIC;
----------------------------------------------------------------
-- Sign Extend Signals
----------------------------------------------------------------
	signal SignExtend_In		:	STD_LOGIC_VECTOR (15 downto 0);
	signal SignExtend_Out:  STD_LOGIC_VECTOR (31 downto 0);
----------------------------------------------------------------
-- PC Signals
----------------------------------------------------------------
	signal	PC_in 		:  STD_LOGIC_VECTOR (31 downto 0);
	signal	PC_out 		:  STD_LOGIC_VECTOR (31 downto 0);
	signal	PC_busy		: 	STD_LOGIC;
----------------------------------------------------------------
-- ALU Signals
----------------------------------------------------------------
	signal	ALU_InA 			:  STD_LOGIC_VECTOR (31 downto 0);
	signal	ALU_InB 			:  STD_LOGIC_VECTOR (31 downto 0);
	signal	ALU_OutA 		:  STD_LOGIC_VECTOR (31 downto 0);
	signal	ALU_OutB 		:  STD_LOGIC_VECTOR (31 downto 0);
	signal	ALU_Control		:  STD_LOGIC_VECTOR (5 downto 0);
	signal	ALU_Status		:  STD_LOGIC_VECTOR (2 downto 0);

----------------------------------------------------------------
-- Control Unit Signals
----------------------------------------------------------------				
 	signal	opcode 		:  STD_LOGIC_VECTOR (5 downto 0);
	signal	ALUOp 		:  STD_LOGIC_VECTOR (2 downto 0);
	signal	Branch 		:  STD_LOGIC;
	signal	BranchGEZ 		:  STD_LOGIC;
	signal	Jump	 		:  STD_LOGIC;
	signal	JumpLink		:  STD_LOGIC;	
	signal	LinktoReg	:  STD_LOGIC;
	signal	MemtoReg 	:  STD_LOGIC;
	signal 	InstrtoReg	: 	STD_LOGIC;		
	signal	ALUSrc 		:  STD_LOGIC;	
	signal	SignExtend 	: 	STD_LOGIC;
	signal	RegWrite		: 	STD_LOGIC;	
	signal	RegDst		:  STD_LOGIC;

----------------------------------------------------------------
-- Register File Signals
----------------------------------------------------------------
 	signal	ReadAddr1_Reg 	:  STD_LOGIC_VECTOR (4 downto 0);
	signal	ReadAddr2_Reg 	:  STD_LOGIC_VECTOR (4 downto 0);
	signal	ReadData1_Reg 	:  STD_LOGIC_VECTOR (31 downto 0);
	signal	ReadData2_Reg 	:  STD_LOGIC_VECTOR (31 downto 0);
	signal	WriteAddr_Reg	:  STD_LOGIC_VECTOR (4 downto 0); 
	signal	WriteData_Reg 	:  STD_LOGIC_VECTOR (31 downto 0);
	signal	RegWrite_Reg	:	STD_LOGIC;

----------------------------------------------------------------
-- Other Signals
----------------------------------------------------------------
	--<any other signals used goes here>
	signal	PCSrc			: STD_LOGIC;
	signal	PCIncrement	: STD_LOGIC_VECTOR (31 downto 0);

----------------------------------------------------------------	
----------------------------------------------------------------
-- <MIPS architecture>
----------------------------------------------------------------
----------------------------------------------------------------
begin

----------------------------------------------------------------
-- Hi/Lo port map
----------------------------------------------------------------

HiLoReg1: HiLoReg PORT MAP (
          READ_HILODATA => ReadData_HiLoReg,
          WRITE_HILODATA => WriteData_HiLoReg,
          WRITE_REG => HiLoRegWrite,
          CLK => CLK
        );

----------------------------------------------------------------
-- BranchGEZAL JumpLink Multiplexer port map
----------------------------------------------------------------
BLJLMux		:Multiplexer generic map (width => 1 )port map
				(
				A				=> BLJLMuxInputA,
				B				=> BLJLMuxInputB,
				SELECT_BIT	=> BLJLMuxSelect,
				DATA_OUT		=> BLJLMuxOutput
				);

----------------------------------------------------------------
-- BranchGEZAL LinktoReg Multiplexer port map
----------------------------------------------------------------
BLLRMux		:Multiplexer generic map (width => 1 )port map
				(
				A				=> BLLRMuxInputA,
				B				=> BLLRMuxInputB,
				SELECT_BIT	=> BLLRMuxSelect,
				DATA_OUT		=> BLLRMuxOutput
				);

----------------------------------------------------------------
-- BranchGEZAL RegWrite Multiplexer port map
----------------------------------------------------------------
BLRWMux		:Multiplexer generic map (width => 1 )port map
				(
				A				=> BLRWMuxInputA,
				B				=> BLRWMuxInputB,
				SELECT_BIT	=> BLRWMuxSelect,
				DATA_OUT		=> BLRWMuxOutput
				);

----------------------------------------------------------------
-- BranchGEZ Multiplexer port map
----------------------------------------------------------------
BGEZMux		:Multiplexer generic map (width => 1 )port map
				(
				A				=> BGEZMuxInputA,
				B				=> BGEZMuxInputB,
				SELECT_BIT	=> BGEZMuxSelect,
				DATA_OUT		=> BGEZMuxOutput
				);

----------------------------------------------------------------
-- Shift Multiplexer port map
----------------------------------------------------------------
ShiftMux		:Multiplexer generic map (width => 32 )port map
				(
				A				=> ShiftMuxInputA,
				B				=> ShiftMuxInputB,
				SELECT_BIT	=> ShiftMuxSelect,
				DATA_OUT		=> ShiftMuxOutput
				);

----------------------------------------------------------------
-- LinkReg Multiplexer port map
----------------------------------------------------------------
LRMux		:Multiplexer generic map (width => 32 )port map
				(
				A				=> LRMuxInputA,
				B				=> LRMuxInputB,
				SELECT_BIT	=> LRMuxSelect,
				DATA_OUT		=> LRMuxOutput
				);

----------------------------------------------------------------
-- JumpLink Multiplexer port map
----------------------------------------------------------------
JLMux		:Multiplexer generic map (width => 5 )port map
				(
				A				=> JLMuxInputA,
				B				=> JLMuxInputB,
				SELECT_BIT	=> JLMuxSelect,
				DATA_OUT		=> JLMuxOutput
				);

----------------------------------------------------------------
-- Move Multiplexer port map
----------------------------------------------------------------
MoveMux		:Multiplexer generic map (width => 32 )port map
				(
				A				=> MoveMuxInputA,
				B				=> MoveMuxInputB,
				SELECT_BIT	=> MoveMuxSelect,
				DATA_OUT		=> MoveMuxOutput
				);

----------------------------------------------------------------
-- Hi/Lo Multiplexer port map
----------------------------------------------------------------
--A is Hi Reg data
--B is Lo Reg data
HiLoMux		:Multiplexer generic map (width => 32 )port map
				(
				A				=> HiLoMuxInputA,
				B				=> HiLoMuxInputB,
				SELECT_BIT	=> HiLoMuxSelect,
				DATA_OUT		=> HiLoMuxOutput
				);

----------------------------------------------------------------
-- JumpReg Multiplexer port map
----------------------------------------------------------------
--A is Hi Reg data
--B is Lo Reg data
JRMux		:Multiplexer generic map (width => 32 )port map
				(
				A				=> JRMuxInputA,
				B				=> JRMuxInputB,
				SELECT_BIT	=> JRMuxSelect,
				DATA_OUT		=> JRMuxOutput
				);

----------------------------------------------------------------
-- PC Multiplexer port map
----------------------------------------------------------------
--A is BranchAdderResult = PC+4 + branch offset	(branch)
--B is PCAdderResult = PC+4							(others)
PCMux		:Multiplexer generic map (width => 32 )port map
				(
				A				=> PCMuxInputA,
				B				=> PCMuxInputB,
				SELECT_BIT	=> PCMuxSelect,
				DATA_OUT		=> PCMuxOutput
				);
				
----------------------------------------------------------------
-- WriteAddr Multiplexer port map
----------------------------------------------------------------
--A is Instr(15 downto 11) = rd (r-type)
--B is Instr(20 downto 16) = rt (lw)
WAMux		:Multiplexer generic map (width => 5 )port map
				(
				A				=> WAMuxInputA,
				B				=> WAMuxInputB,
				SELECT_BIT	=> WAMuxSelect,
				DATA_OUT		=> WAMuxOutput
				);
				
----------------------------------------------------------------
-- ALU Multiplxer port map
----------------------------------------------------------------
--A is SignExtend_Out = address offset for base register 	(lw, sw)
--B is ReadData2_Reg = rt												(rtype, beq)
ALUMux		:Multiplexer generic map (width => 32 )port map
				(
				A				=> ALUMuxInputA,
				B				=> ALUMuxInputB,
				SELECT_BIT	=> ALUMuxSelect,
				DATA_OUT		=> ALUMuxOutput
				);
				
----------------------------------------------------------------
-- WriteData Multiplexer port map
----------------------------------------------------------------
--A is Data_Out = data memory output	(lw, sw)
--B is ALU_Out = alu result				(rtype, beq)
WDMux		:Multiplexer generic map (width => 32 )port map
				(
				A				=> WDMuxInputA,
				B				=> WDMuxInputB,
				SELECT_BIT	=> WDMuxSelect,
				DATA_OUT		=> WDMuxOutput
				);
				
----------------------------------------------------------------
-- Jump Multiplexer port map
----------------------------------------------------------------
--A is (PC+4)(31 downto 28) & Instr(25 downto 0) & "00"
--B is PCMuxOutput = PC+4	(others)
JumpMux		:Multiplexer generic map (width => 32 )port map
				(
				A				=> JumpMuxInputA,
				B				=> JumpMuxInputB,
				SELECT_BIT	=> JumpMuxSelect,
				DATA_OUT		=> JumpMuxOutput
				);

----------------------------------------------------------------
-- LUI Multiplexer port map
----------------------------------------------------------------
--A is Instr(15 downto 0) & x"0000" shifted immediate
--B is WDMuxOutput
LUIMux		:Multiplexer generic map (width => 32 )port map
				(
				A				=> LUIMuxInputA,
				B				=> LUIMuxInputB,
				SELECT_BIT	=> LUIMuxSelect,
				DATA_OUT		=> LUIMuxOutput
				);

----------------------------------------------------------------
-- PC+4 Adder port map
----------------------------------------------------------------
--PC4Adder		:Adder port map
--					(
--					A			=> PC4AdderInputA,
--					B			=> PC4AdderInputB,
--					RESULT	=> PC4AdderResult
--					);

----------------------------------------------------------------
-- PC Adder port map
----------------------------------------------------------------
PCAdder		:Adder port map
					(
					A			=> PCAdderInputA,
					B			=> PCAdderInputB,
					RESULT	=> PCAdderResult
					);
					
----------------------------------------------------------------
-- Branch Adder port map
----------------------------------------------------------------
BranchAdder		:Adder port map
					(
					A			=> BranchAdderInputA,
					B			=> BranchAdderInputB,
					RESULT	=> BranchAdderResult
					);
					
----------------------------------------------------------------
-- Sign Extend port map
----------------------------------------------------------------
SignExtend1		:SignExtender port map
						(
						SignExtend_In 		=> SignExtend_In,
						SignExtend_Out 	=> SignExtend_Out,
						SignExtend_Enable	=> SignExtend
						);

----------------------------------------------------------------
-- ALU Control port map
----------------------------------------------------------------
ALUControl1		:ALUControl port map
						(
						ALUOp			=> ALUOp,
						funct			=> funct,
						HiLoWrite	=> HiLoWrite,
						HiLoSelect	=> HiLoSelect,
						MovetoReg	=> MovetoReg,
						JumptoPC		=> JumptoPC,
						Shift			=> Shift,
						ALUCtrl		=> ALUCtrl
						);
----------------------------------------------------------------
-- PC port map
----------------------------------------------------------------
PC1				: PC port map
						(
						PC_in 	=> PC_in, 
						PC_out 	=> PC_out,
						PC_busy	=> PC_busy,
						RESET 	=> RESET,
						CLK 		=> CLK
						);
						
----------------------------------------------------------------
-- ALU port map
----------------------------------------------------------------
ALU1 				: ALU generic map (width => 32 )port map
						(
						Operand1 	=> ALU_InA, 
						Operand2 	=> ALU_InB, 
						Result1 		=> ALU_OutA,
						Result2 		=> ALU_OutB,
						Status 		=> ALU_Status, 
						Control  	=> ALU_Control,
						CLK			=> CLK
						);
						
----------------------------------------------------------------
-- Control Unit port map
----------------------------------------------------------------
ControlUnit1 	: ControlUnit port map
						(
						opcode 		=> opcode, 
						ALUOp 		=> ALUOp, 
						Branch 		=> Branch,
						BranchGEZ 	=> BranchGEZ,
						Jump 			=> Jump,
						JumpLink 	=> JumpLink,
						LinktoReg	=> LinktoReg,
						MemRead 		=> MemRead, 
						MemtoReg 	=> MemtoReg, 
						InstrtoReg 	=> InstrtoReg, 
						MemWrite 	=> MemWrite, 
						ALUSrc 		=> ALUSrc, 
						SignExtend 	=> SignExtend, 
						RegWrite 	=> RegWrite, 
						RegDst 		=> RegDst
						);
						
----------------------------------------------------------------
-- Register file port map
----------------------------------------------------------------
RegFile1			: RegFile port map
						(
						ReadAddr1_Reg 	=>  ReadAddr1_Reg,
						ReadAddr2_Reg 	=>  ReadAddr2_Reg,
						ReadData1_Reg 	=>  ReadData1_Reg,
						ReadData2_Reg 	=>  ReadData2_Reg,
						WriteAddr_Reg 	=>  WriteAddr_Reg,
						WriteData_Reg 	=>  WriteData_Reg,
						RegWrite 		=>  RegWrite_Reg,
						CLK 				=>  CLK				
						);

----------------------------------------------------------------
-- Processor logic
----------------------------------------------------------------
--<Rest of the logic goes here>
--process(Instr, Data_In, ALUOp, Branch, Jump, MemtoReg, InstrtoReg, ALUSrc, PCIncrement, PCSrc,
--								SignExtend_Out, RegDst, ReadData1_Reg, ReadData2_Reg, ALU_Out, PC_out, ALU_zero)
--begin

---------HiLo---------
WriteData_HiLoReg	<= ALU_OutB & ALU_OutA;
HiLoRegWrite		<= HiLoWrite; -- control bit to write to hi/lo register
-------------------------

----------MIPS----------
Addr_Instr	<= PC_out;
Addr_Data	<= ALU_OutA;
Data_Out		<= ReadData2_Reg;
-------------------------------

----------ALU CONTROL----------
funct <= Instr (5 downto 0);
-------------------------------

------------PC+4 ADDER-----------
--PC4AdderInputA <= PCAdderResult;
--PC4AdderInputB <= x"00000004";
-------------------------------

------------PC ADDER-----------
PCAdderInputA <= PC_out;
PCAdderInputB <= x"00000004";
-------------------------------

------------Branch ADDER-----------
BranchAdderInputA <= PCAdderResult;
BranchAdderInputB <= SignExtend_Out(29 downto 0) & "00";
-----------------------------------

------------------ALU------------------
ALU_InA						<= ShiftMuxOutput;
ALU_InB						<= ALUMuxOutput;
ALU_Control(4 downto 0)	<= ALUCtrl;
ALU_Control(5) 			<= RESET;
----------------------------------------

-------BranchGEZAL JumpLink MUX----------
BLJLMuxInputA(0) <= Instr(20);
BLJLMuxInputB(0) <= JumpLink;
BLJLMuxSelect <= BranchGEZ;
-------------------------------

-------BranchGEZAL LinktoReg MUX----------
BLLRMuxInputA(0) <= Instr(20);
BLLRMuxInputB(0) <= LinktoReg;
BLLRMuxSelect <= BranchGEZ;
-------------------------------

--------BranchGEZAL RegWrite MUX-------
BLRWMuxInputA(0) <= Instr(20);
BLRWMuxInputB(0) <= RegWrite;
BLRWMuxSelect <= BranchGEZ;
-------------------------------

------------BranchGEZ MUX-------------
BGEZMuxInputA(0) <= (not ReadData1_Reg(31)) and Branch;
BGEZMuxInputB(0) <= PCSrc;
BGEZMuxSelect <= BranchGEZ;
-------------------------------

------------Shift MUX-------------
ShiftMuxInputA <= x"000000" & "000" & Instr(10 downto 6);
ShiftMuxInputB <= ReadData1_Reg;
ShiftMuxSelect <= Shift;
-------------------------------

------------LinkReg MUX-------------
LRMuxInputA <= PCAdderResult;
LRMuxInputB <= MoveMuxOutput;
LRMuxSelect <= BLLRMuxOutput(0) or JumptoPC; -- activates when PC + 4 is needed to write to register. jalr/bgezal/jal (jr activates but written to reg 0) 
-------------------------------

------------JumpLink MUX-------------
JLMuxInputA <= "11111";
JLMuxInputB <= WAMuxOutput;
JLMuxSelect <= BLJLMuxOutput(0);
-------------------------------

------------JumpReg MUX-------------
JRMuxInputA <= ReadData1_Reg;
JRMuxInputB <= JumpMuxOutput;
JRMuxSelect <= JumptoPC;
-------------------------------

------------Move MUX-------------
MoveMuxInputA <= HiLoMuxOutput;
MoveMuxInputB <= LUIMuxOutput;
MoveMuxSelect <= MovetoReg;
-------------------------------

------------Hi/Lo MUX-------------
HiLoMuxInputA <= ReadData_HiLoReg(63 downto 32);
HiLoMuxInputB <= ReadData_HiLoReg(31 downto 0);
HiLoMuxSelect <= HiLoSelect;
-------------------------------

PCSrc <= Branch and ALU_Status(0);
------------PC MUX-------------
PCMuxInputA <= BranchAdderResult;
PCMuxInputB <= PCAdderResult;
PCMuxSelect <= BGEZMuxOutput(0);
-------------------------------

---------WriteAddr MUX----------
WAMuxInputA <= Instr(15 downto 11);
WAMuxInputB <= Instr(20 downto 16);
WAMuxSelect <= RegDst;
-------------------------------

------------ALU MUX-------------
ALUMuxInputA <= SignExtend_Out;
ALUMuxInputB <= ReadData2_Reg;
ALUMuxSelect <= ALUSrc;
--------------------------------

---------WriteData MUX---------
WDMuxInputA <= Data_In;
WDMuxInputB <= ALU_OutA;
WDMuxSelect <= MemtoReg;
-------------------------------

---------Jump MUX---------
JumpMuxInputA <= PCAdderResult(31 downto 28) & Instr(25 downto 0) & "00";
JumpMuxInputB <= PCMuxOutput;
JumpMuxSelect <= Jump;
-------------------------------

---------LUI MUX---------
LUIMuxInputA <= Instr(15 downto 0) & x"0000";
LUIMuxInputB <= WDMuxOutput;
LUIMuxSelect <= InstrtoReg;
-------------------------------

---------SignExtender---------
SignExtend_In <= Instr(15 downto 0);
-------------------------------

---------RegFile---------
ReadAddr1_Reg <= Instr(25 downto 21);
ReadAddr2_Reg <= Instr(20 downto 16);
WriteAddr_Reg <= JLMuxOutput;
WriteData_Reg <= LRMuxOutput;
RegWrite_Reg  <= BLRWMuxOutput(0);
-------------------------

---------Control Unit---------
opcode <= Instr(31 downto 26);
-------------------------

---------PC---------
PC_in 	<= JRMuxOutput;
PC_busy	<= ALU_Status(2);
-----------------------

--end process;
end arch_MIPS;

----------------------------------------------------------------	
----------------------------------------------------------------
-- </MIPS architecture>
----------------------------------------------------------------
----------------------------------------------------------------	
