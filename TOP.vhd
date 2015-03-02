----------------------------------------------------------------------------------
-- Company: NUS
-- Engineer: Rajesh Panicker
-- 
-- Create Date:   21:06:18 14/10/2014
-- Design Name: 	TOP (MIPS Wrapper)
-- Target Devices: Nexys 4 (Artix 7 100T) or Spartan 6 LX9 Microboard.
-- Tool versions: ISE 14.7
-- Description: Top level module - wrapper for MIPS processor
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.03 - Support added for Spartan 6, Blinky program updated, Some minor modifications
-- Additional Comments: See the notes below. The interface (entity) as well as implementation (architecture) can be modified
--
----------------------------------------------------------------------------------


----------------------------------------------------------------
-- NOTE : 
----------------------------------------------------------------

-- Instruction and data memory are WORD addressable (NOT byte addressable). 
-- Each can store 256 WORDs. 
-- Address Range of Instruction Memory is 0x00400000 to 0x004003FC (word addressable - only multiples of 4 are valid). This will cause warnings about 2 unused bits, but that's ok.
-- Address Range of Data Memory is 0x10010000 to 0x100103FC (word addressable - only multiples of 4 are valid).
-- LED(N_LEDs_RES-1 downto 0) is mapped to the word address 0x10020000. Only the least significant N_LEDs_RES bits written to this location are used.
-- DIP switches are mapped to the word address 0x10030000. Only the least significant N_DIPs bits read from this location are valid.
-- You can change the above addresses to some other convenient value for simulation, and change it to their original values for synthesis / FPGA testing.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;

----------------------------------------------------------------
-- TOP level module interface
----------------------------------------------------------------

entity TOP is
		Generic 
		(
			constant N_LEDs_RES	: integer := 8; -- Number of LEDs displaying Result. 8 for Artix 7; 2 for Spartan 6
			constant N_LEDs_PC	: integer := 6; -- Number of LEDs displaying PC. 6 for Artix 7; 2 for Spartan 6**. 
			constant N_LEDS_ADD	: integer := 2;  -- Number of additional LEDs. 2 for Artix 7; 0 for Spartan 6
			constant N_DIPs		: integer := 16  -- Number of DIPs. 16 for Artix 7; 4 for Spartan 6
			
			--**This count does not include PC(22) displayed on LED(14) and divided clock displayed on LED(15) for Artix 7
		);
		Port 
		(
			DIP 				: in  STD_LOGIC_VECTOR (N_DIPs-1 downto 0);  -- DIP switch inputs. Not debounced.
			LED 				: out  STD_LOGIC_VECTOR (N_LEDs_RES+N_LEDs_PC+N_LEDS_ADD-1 downto 0); -- LEDs.
			-------- for Artix 7 ----------
			-- (15) showing the divided clock
			-- (14 downto 8) showing PC(22) & PC(7 downto 2)
			-- (7 downto 0) mapped to the address 0x10020000
			-------- for Spartan 6 ----------
			-- (3 downto 2) showing PC(3 downto 2)
			-- (1 downto 0) mapped to the address 0x10020000
			RESET				: in  STD_LOGIC; 	-- Reset -> BTNC (Centre push button) for Artix 7; SW5 for Spartan 6.
			CLK_undiv		: in  STD_LOGIC 	-- 100MHz clock for both Artix 7 and Spartan 6. Converted to a lower frequency using CLK_DIV_PROCESS before use.
		);
end TOP;


architecture arch_TOP of TOP is

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------
constant CLK_DIV_BITS	: integer := 27; --26 for a clock of the order of 1Hz. Changed in top.vhd_v2 : use (CLK_DIV_BITS of top.vhd_v2)+1. 
-- 1 for a 50MHz clock.
-- See the notes in CLK_DIV_PROCESS for SIMULATION or for obtaining a 100MHz clock frequency, 

----------------------------------------------------------------
-- MIPS component declaration
----------------------------------------------------------------
component mips is
    Port ( 	
			Addr_Instr 		: out STD_LOGIC_VECTOR (31 downto 0); 	-- Input to instruction memory (normally comes from the output of PC)
			Instr 			: in STD_LOGIC_VECTOR (31 downto 0);  	-- Output from the instruction memory
			Addr_Data		: out STD_LOGIC_VECTOR (31 downto 0); 	-- Address sent to data memory / memory-mapped peripherals
			Data_In			: in STD_LOGIC_VECTOR (31 downto 0);  	-- Data read from data memory / memory-mapped peripherals
			Data_Out			: out  STD_LOGIC_VECTOR (31 downto 0); -- Data to be written to data memory / memory-mapped peripherals 
			MemRead 			: out STD_LOGIC; 	-- MemRead signal to data memory / memory-mapped peripherals 
			MemWrite 		: out STD_LOGIC; 	-- MemWrite signal to data memory / memory-mapped peripherals 
			RESET				: in STD_LOGIC; 	-- Reset signal for the processor. Should reset ALU, PC and pipeline registers (if present). Resetting general purpose registers is not essential (though it could be done).
			CLK				: in STD_LOGIC 	-- Divided (lower frequency) clock for the processor.
			);
end component mips;

----------------------------------------------------------------
-- MIPS signals
----------------------------------------------------------------
signal Addr_Instr 	: STD_LOGIC_VECTOR (31 downto 0);
signal Instr 			: STD_LOGIC_VECTOR (31 downto 0);
signal Data_In			: STD_LOGIC_VECTOR (31 downto 0);
signal Addr_Data		: STD_LOGIC_VECTOR (31 downto 0);
signal Data_Out		: STD_LOGIC_VECTOR (31 downto 0);
signal MemRead 		: STD_LOGIC; 
signal MemWrite 		: STD_LOGIC; 

----------------------------------------------------------------
-- Others signals
----------------------------------------------------------------
signal dec_DATA_MEM, dec_LED, dec_DIP : std_logic;  -- data memory address decoding
signal CLK : std_logic; --divided (low freq) clock

----------------------------------------------------------------
-- Memory type declaration
----------------------------------------------------------------
type MEM_256x32 is array (0 to 255) of std_logic_vector (31 downto 0); -- 256 words

----------------------------------------------------------------
-- Instruction Memory
----------------------------------------------------------------
constant INSTR_MEM : MEM_256x32 := (
x"3c09ffff",
x"3529ffff",
x"252affff",
x"252b0001",
x"252c0000",
		
--			x"3c09ffff", -- lui $t1,0xffff
--			x"3529fffa", -- ori $t1,0xfffa
--			x"3c080000", -- lui $t0,0
--			x"35080002", -- ori $t1,2
--			x"0128001a", -- div $t1,$t0
--			x"00005010", -- mfhi $t2
--			x"00005812", -- mflo $t3
--			x"0128001b", -- div $t1,$t0
--			x"00006010", -- mfhi $t4
--			x"00006812", -- mflo $t5
--			x"016d7026", -- xor $t6,$t3,$t5
			
--			x"3c08ffff", --lui $t0 0xffff
--			x"35080000", --ori $t0 0x0000
--			x"3c090000", --lui $t1, 0
--			x"35290004", --ori $t1, 4
--			x"00085200", --sll $t2, $t0, 8
--			x"00085a02", --srl $t3, $t0, 8
--			x"00086203", --sra $t4, $t0, 8
--			x"01286804", --sllv $t5, $t0, $t1
--			x"01287006", --srlv $t6, $t0, $t1
--			x"01287807", --srav $t7, $t0, $t1
			
--			x"35290001",	--ori $t1, 1
--			x"354a0001",	--ori $t2, 1
--			x"05310003",	--bgezal $t1, loop2
--			x"3c01ffff",	--loop1: ori $t3, -1
--			x"3421ffff",
--			x"01615825",
--			x"358c0001",	--loop2:	ori $t4, 1
--			x"0561fffb",	--bgez $t3, loop1
--			x"03e00008",	--jr $ra
			
--			x"3c09ffff",	--lui $t1, 0xffff
--			x"35290000",	--ori $t1, 0xffff
--			x"3c0a0000",	--lui $t2, 0
--			x"354a0004",	--ori $t2, 4
--			x"01495804",	--sllv $t3, $t1, $t2
--			x"00096200",	--sll $t4, $t1, 8
--			x"00096a02",	--srl $t5, $t1, 8
--			x"00097203",	--sra $t6, $t1, 8
			
--			x"0c100005",--			jal init
--			x"012a5820",--			add $t3, $t1, $t2
--			x"012a0018",--			mult $t1, $t2
--			x"00006010",--			mfhi $t4
--			x"00006812",--			mflo $t5
--			x"3c090000",--init:	lui $t1, 0
--			x"35290006",--			ori $t1, 6
--			x"354a0000",--			ori $t2, 0
--			x"354a0006",--			ori $t2, 6
--			x"03e00008",--			jr $ra

--			x"3c09f000",	--lui $t1, 0xf000
--			x"3529f002",	--ori $t1, 0xf002
--			x"3c0af000",	--lui $t2, 0xf000
--			x"354af003",	--ori $t2, 0xf003
--			x"012a0018",	--mult $t1, $t2
--			x"00005810",	--mfhi $t3
--			x"00006012",	--mflo $t4
--			x"3c0d0040",	--lui $t5, 0x0040
--			x"35ad0000",	--ori $t5, 0x0000
--			x"01a00008",	--jr $t5
			
--			x"3c090000", -- start : lui $t1, 0x0000 # constant 1 upper half word. not required if GPRs are reset when RESET is pressed
--			x"35290001", -- 			ori $t1, 0x0001 # constant 1 lower half word
--			x"3c081002", -- 			lui $t0, 0x1002 # DIP address upper half word before offset
--			x"35088001", --			ori $t0, 0x8001 # DIP address lower half word before offset
--			x"8d0c7fff", --			lw  $t4, 0x7fff($t0) # read from DIP address 0x10030000 = 0x10028001 + 0x7fff
--			x"3c081002", --			lui $t0, 0x1002 # LED address upper half word before offset
--			x"35080001", --			ori $t0, 0x0001 # LED address lower half word before offset
--			x"3400ffff", --			ori $zero, 0xffff # writing to zero. should have no effect
--			x"3c0a0000", -- loop: 	lui $t2, 0x0000 # delay counter (n) upper half word if using slow clock
--			x"354a0004", -- 			ori $t2, 0x0004 # delay counter (n) lower half word if using slow clock
--			-- x"3c0a00ff",-- 			#lui $t2, 0x00ff # delay counter (n) upper half word if using fast clock		
--			-- x"354affff",-- 			#ori $t2, 0xffff # delay counter (n) lower half word if using fast clock
--			x"01495022", -- delay: 	sub $t2, $t2, $t1 # begining of delay loop
--			x"0149582a", -- 			slt $t3, $t2, $t1
--			x"1160fffd", -- 			beq $t3, $zero, delay # end of delay loop
--			x"ad0cffff", -- 			sw  $t4, 0xffffffff($t0)	# write to LED address 0x10020000 = 0x10020001 + 0xffffffff.
--			x"01806027", --			nor $t4, $t4, $zero # flip the bits
--			x"08100008", -- 			j loop # infinite loop; # repeats every n*3 (delay instructions) + 5 (non-delay instructions).
			others=> x"00000000");

-- The Blinky program reads the DIP switches in the beginning. Let the value read be VAL.
-- It will then keep alternating between VAL(N_LEDs_RES-1 downto 0) , not(VAL(N_LEDs_RES-1 downto 0)), 
-- essentially blinking LED(N_LEDs_RES-1 downto 0) according to the initial pattern read from the DIP switches.
-- Changes in top.vhd_v2 : DIP and LED addresses are now calculated using positive and negative offsets - to test if LW and SW works completely.
-- Changes in top.vhd_v3 : Added an instruction which writes to $zer0. Should have no effect.

----------------------------------------------------------------
-- Data Memory
----------------------------------------------------------------
signal DATA_MEM : MEM_256x32 := (others=> x"00000000");


----------------------------------------------------------------	
----------------------------------------------------------------
-- <Wrapper architecture>
----------------------------------------------------------------
----------------------------------------------------------------	
		
begin

----------------------------------------------------------------
-- Debug LEDs
----------------------------------------------------------------			
LED(N_LEDs_PC+N_LEDs_RES-1 downto N_LEDs_RES) <= Addr_Instr(N_LEDs_PC+1 downto 2); -- debug showing PC
LED(N_LEDs_RES+N_LEDs_PC+N_LEDS_ADD-2) <= Addr_Instr(22); -- debug showing PC(22) on LED(14) for Artix 7; comment out for Spartan 6
LED(N_LEDs_RES+N_LEDs_PC+N_LEDS_ADD-1) <= CLK; 		-- debug showing clock on LED(15) for Artix 7; comment out for Spartan 6

----------------------------------------------------------------
-- MIPS port map
----------------------------------------------------------------
MIPS1 : MIPS port map ( 
			Addr_Instr 		=>  Addr_Instr,
			Instr 			=>  Instr, 		
			Data_In			=>  Data_In,	
			Addr_Data		=>  Addr_Data,		
			Data_Out			=>  Data_Out,	
			MemRead 			=>  MemRead,		
			MemWrite 		=>  MemWrite,
			RESET				=>	 RESET,
			CLK				=>  CLK				
			);

----------------------------------------------------------------
-- Data memory address decoding
----------------------------------------------------------------
dec_DATA_MEM <= '1' 	when Addr_Data>=x"10010000" and Addr_Data<=x"100103FC" else '0'; -- To check if address is in the valid range, assuming 256 word memory
dec_LED 		<= '1'	when Addr_Data=x"10020000" else '0';
dec_DIP 		<= '1' 	when Addr_Data=x"10037000" else '0';

----------------------------------------------------------------
-- Data memory read
----------------------------------------------------------------
Data_In 	<= (31-N_DIPs downto 0 => '0') & DIP						when MemRead = '1' and dec_DIP = '1' 
				else DATA_MEM(conv_integer(Addr_Data(9 downto 2)))	when MemRead = '1' and dec_DATA_MEM = '1'
				else (others=>'0');
				
----------------------------------------------------------------
-- Instruction memory read
----------------------------------------------------------------
Instr <= INSTR_MEM(conv_integer(Addr_Instr(9 downto 2))) 
			when Addr_Instr>=x"00400000" and Addr_Instr<=x"004003FC" -- To check if address is in the valid range, assuming 256 word memory. Also helps minimize warnings (--changed in top.vhd_v2 to have a stricter check)
			else x"00000000";

----------------------------------------------------------------
-- Data Memory-mapped LED write
----------------------------------------------------------------
write_LED: process (CLK)
begin
	if CLK'event and CLK = '1' then
		if RESET = '1' then
			LED(N_LEDs_RES-1 downto 0) <= (others=> '0');
		elsif (MemWrite = '1') and  (dec_LED = '1') then
			LED(N_LEDs_RES-1 downto 0) <= Data_Out(N_LEDs_RES-1 downto 0);
		end if;
	end if;
end process;

----------------------------------------------------------------
-- Data Memory write
----------------------------------------------------------------
write_DATA_MEM: process (CLK)
begin
    if CLK'event and CLK = '1' then
        if (MemWrite = '1' and dec_DATA_MEM = '1') then
            DATA_MEM(conv_integer(Addr_Data(9 downto 2))) <= Data_Out;
        end if;
    end if;
end process;

----------------------------------------------------------------
-- Clock divider
----------------------------------------------------------------
 CLK <= CLK_undiv;
-- IMPORTANT : >>> uncomment the previous line and comment out the rest of the process
--					>>> for SIMULATION or for obtaining a 100MHz clock frequency
--CLK_DIV_PROCESS : process(CLK_undiv)
--variable clk_counter : std_logic_vector(CLK_DIV_BITS-1 downto 0) := (others => '0');
--begin
--	if CLK_undiv'event and CLK_undiv = '1' then
--		clk_counter := clk_counter+1;
--		CLK <= clk_counter(CLK_DIV_BITS-1);
--	end if;
--end process;

end arch_TOP;

----------------------------------------------------------------	
----------------------------------------------------------------
-- </Wrapper architecture>
----------------------------------------------------------------
----------------------------------------------------------------	



----------------------------------------------------------------
-- Blinky Program
----------------------------------------------------------------
--#NOTE:	>>> for simulation in MARS, use a lower value for delay counter, 
--#		>>> and a value closer to 0x10010000 for memory mapped devices.
--start : lui $t1, 0x0000 # constant 1 upper half word. not required if GPRs are reset when RESET is pressed
--			ori $t1, 0x0001 # constant 1 lower half word
--			lui $t0, 0x1002 # DIP address upper half word before offset
--			ori $t0, 0x8001 # DIP address lower half word before offset
--			lw  $t4, 0x7fff($t0) # read from DIP address 0x10030000 = 0x10028001 + 0x7fff
--			lui $t0, 0x1002 # LED address upper half word before offset
--			ori $t0, 0x0001 # LED address lower half word before offset
--			ori $zero, 0xffff # writing to zero. should have no effect
--loop: 	lui $t2, 0x0000 # delay counter (n) upper half word if using slow clock
--			ori $t2, 0x0004 # delay counter (n) lower half word if using slow clock
-- 		#lui $t2, 0x00ff # delay counter (n) upper half word if using fast clock		
-- 		#ori $t2, 0xffff # delay counter (n) lower half word if using fast clock
--delay: sub $t2, $t2, $t1 # begining of delay loop
--			slt $t3, $t2, $t1
--			beq $t3, $zero, delay # end of delay loop
--			sw  $t4, 0xffffffff($t0)	# write to LED address 0x10020000 = 0x10020001 + 0xffffffff.
--			nor $t4, $t4, $zero # flip the bits
--			j loop # infinite loop; # repeats every n*3 (delay instructions) + 5 (non-delay instructions).