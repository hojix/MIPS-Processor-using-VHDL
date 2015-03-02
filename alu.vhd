----------------------------------------------------------------------------------
-- Company: NUS
-- Engineer: Rajesh Panicker
-- 
-- Create Date:   10:39:18 13/09/2014
-- Design Name: 	ALU
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool versions: ISE 14.7
-- Description: ALU template for MIPS processor
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.03 - Asserting reset will cause everything in the MULTI_CYCLE_PROCESS to be reset 
-- Additional Comments: 
--
----------------------------------------------------------------------------------


------------------------------------------------------------------
-- ALU Entity
------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity alu is
generic (width 	: integer := 32);
Port (Clk			: in	STD_LOGIC;
		Control		: in	STD_LOGIC_VECTOR (5 downto 0);
		Operand1		: in	STD_LOGIC_VECTOR (width-1 downto 0);
		Operand2		: in	STD_LOGIC_VECTOR (width-1 downto 0);
		Result1		: out	STD_LOGIC_VECTOR (width-1 downto 0);
		Result2		: out	STD_LOGIC_VECTOR (width-1 downto 0);
		Status		: out	STD_LOGIC_VECTOR (2 downto 0));		
end alu;


------------------------------------------------------------------
-- ALU Architecture
------------------------------------------------------------------

architecture Behavioral of alu is

type states is (COMBINATIONAL, MULTI_CYCLE);
signal state, n_state 	: states := COMBINATIONAL;


----------------------------------------------------------------------------
-- ALU Adder instantiation
----------------------------------------------------------------------------
component alu_adder is
generic (width : integer);
port (A 		: in 	std_logic_vector(width-1 downto 0);
		B 		: in 	std_logic_vector(width-1 downto 0);
		C_in 	: in 	std_logic;
		S 		: out std_logic_vector(width-1 downto 0);
		C_out	: out std_logic);
end component alu_adder;


----------------------------------------------------------------------------
-- Adder signals
----------------------------------------------------------------------------
signal B 		: std_logic_vector(width-1 downto 0) := (others => '0'); 
signal C_in 	: std_logic := '0';
signal S 		: std_logic_vector(width-1 downto 0) := (others => '0'); 
signal C_out	: std_logic := '0'; --not used

----------------------------------------------------------------------------
-- shifter instantiation
----------------------------------------------------------------------------

component shifter is
	generic ( width : integer := 32 ); 
    Port ( EN : in  STD_LOGIC;
           CONTROL : in  STD_LOGIC_VECTOR ( 1 downto 0);
           DATA_IN : in  STD_LOGIC_VECTOR (31 downto 0);
           DATA_OUT : out  STD_LOGIC_VECTOR (31 downto 0));
end component shifter;

----------------------------------------------------------------------------
-- Shifter signals
----------------------------------------------------------------------------
signal S0,S1,S2,S3,S4,S5 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0'); 

----------------------------------------------------------------------------
-- Signals for MULTI_CYCLE_PROCESS
----------------------------------------------------------------------------
signal Result1_multi		: STD_LOGIC_VECTOR (width-1 downto 0) := (others => '0'); 
signal Result2_multi		: STD_LOGIC_VECTOR (width-1 downto 0) := (others => '0');
signal done		 			: STD_LOGIC := '0';

begin

-- <port maps>
adder32		: alu_adder generic map (width =>  width) port map (  A=>Operand1, B=>B, C_in=>C_in, S=>S, C_out=>C_out );
shift1bit	: shifter generic map (width => 1) port map ( Operand1(0),Control(3 downto 2),S0,S1);
shift2bit 	: shifter generic map (width => 2) port map ( Operand1(1),Control(3 downto 2),S1,S2);
shift4bit 	: shifter generic map (width => 4) port map ( Operand1(2),Control(3 downto 2),S2,S3);
shift8bit 	: shifter generic map (width => 8) port map ( Operand1(3),Control(3 downto 2),S3,S4);
shift16bit 	: shifter generic map (width => 16) port map ( Operand1(4),Control(3 downto 2),S4,S5);
-- </port maps>


----------------------------------------------------------------------------
-- COMBINATIONAL PROCESS
----------------------------------------------------------------------------
COMBINATIONAL_PROCESS : process (
											Control, Operand1, Operand2, state, -- external inputs
											S, S5,-- ouput from the adder (or other components)
											Result1_multi, Result2_multi, done -- from multi-cycle process(es)
											)
begin

-- <default outputs>
Status(2 downto 0) <= "000"; -- both statuses '0' by default 
Result1 <= (others=>'0');
Result2 <= (others=>'0');

n_state <= state;
S0 <= Operand2;
B <= Operand2;
C_in <= '0';
-- </default outputs>

--reset
if Control(5) = '1' then
	n_state <= COMBINATIONAL;
else

case state is
	when COMBINATIONAL =>
		case Control(4 downto 0) is
		--and
		when "00000" =>   -- takes 0 cycles to execute
			Result1 <= Operand1 and Operand2;
		--or
		when "00001" =>
			Result1 <= Operand1 or Operand2;
		--xor
		when "00100" => 
			Result1 <= (Operand1 and not Operand2) or (not Operand1 and Operand2);
		--nor
		when "01100" => 
			Result1 <= Operand1 nor Operand2;
		--add
		when "00010" =>
			Result1 <= S;
			-- overflow
			Status(1) <= ( Operand1(width-1) xnor  Operand2(width-1) )  and ( Operand2(width-1) xor S(width-1) );
		-- sub
		when "00110" =>
			B <= not(Operand2);
			C_in <= '1';
			Result1 <= S;
			-- overflow
			Status(1) <= (not Operand1(width-1) and Operand2(width-1) and S(width-1)) or (Operand1(width-1) and not Operand2(width-1) and not S(width-1));
			--zero
			if S = x"00000000" then 
				Status(0) <= '1'; 
			else
				Status(0) <= '0';
			end if;
		--sll/srl/sra
		when "00101" | "01101" | "01001"=>
			Result1 <= S5;
		--slt
		when "00111" =>
			B <= not(Operand2);
			C_in <= '1';
			if (not Operand1(width-1) and Operand2(width-1) and S(width-1)) = '1' or (Operand1(width-1) and not Operand2(width-1) and not S(width-1)) = '1' then
				Result1 <= x"0000000"&"000"&(not(S(width-1)));
			else
				Result1 <= x"0000000"&"000"&S(width-1);
			end if;
		-- sltu
		when "01110" =>
			B <= not(Operand2);
			C_in <= '1';
		if C_out = '1'  then
			Result1 <= (others=>'0');
		else
			Result1 <= x"00000001"; 
		end if;
		-- multi-cycle operations
		when "10000" | "10001" | "11110" | "10010" | "10011" => 
			n_state <= MULTI_CYCLE;
			Status(2) <= '1';
		-- default cases (already covered)
		when others=> null;
		end case;
	when MULTI_CYCLE => 
		if done = '1' then
			Result1 <= Result1_multi;
			Result2 <= Result2_multi;
			n_state <= COMBINATIONAL;
			Status(2) <= '0';
		else
			Status(2) <= '1';
			n_state <= MULTI_CYCLE;
		end if;
	end case;
end if;	
end process;


----------------------------------------------------------------------------
-- STATE UPDATE PROCESS
----------------------------------------------------------------------------

STATE_UPDATE_PROCESS : process (Clk) -- state updating
begin  
   if (Clk'event and Clk = '1') then
		state <= n_state;
   end if;
end process;

----------------------------------------------------------------------------
-- MULTI CYCLE PROCESS
----------------------------------------------------------------------------

MULTI_CYCLE_PROCESS : process (Clk) -- multi-cycle operations done here
-- assume that Operand1 and Operand 2 do not change while multi-cycle operations are being performed

variable count 			: std_logic_vector(15 downto 0) := (others => '0');
variable temp_sum 		: std_logic_vector(2*width-1 downto 0) := (others => '0');
variable operand1_val	: std_logic_vector(2*width-1 downto 0) := (others => '0');
variable operand2_val	: std_logic_vector(width-1 downto 0) := (others => '0');
variable numerator 		: std_logic_vector(width-1 downto 0) := (others => '0');
variable denominator 	: std_logic_vector(width-1 downto 0) := (others => '0');
variable quotient 		: std_logic_vector(width-1 downto 0) := (others => '0');
variable remainder 		: std_logic_vector(width-1 downto 0) := (others => '0');
variable sign_quotient 	: std_logic := '0';
variable sign_remainder : std_logic := '0';
variable signed1 			: std_logic_vector(width-1 downto 0) := (others => '0');
variable signed2 			: std_logic_vector(width-1 downto 0) := (others => '0');
variable sign 				: std_logic := '0';

begin  
   if (Clk'event and Clk = '1') then 
		if Control(5) = '1' then
			count := (others => '0');
			temp_sum := (others => '0');
		end if;
		done <= '0';
		if n_state = MULTI_CYCLE then
			case Control(4 downto 0) is			
			when "10001" => -- multu
				if state = COMBINATIONAL then  -- n_state = MULTI_CYCLE and state = COMBINATIONAL implies we are just transitioning into MULTI_CYCLE					
							temp_sum := (others => '0');
							count := (others => '0');
							operand1_val := (width-1 downto 0 => '0') & Operand1;
							operand2_val := Operand2;
				end if;
					if operand2_val(0) = '1' then 
						temp_sum := temp_sum + operand1_val;
					end if;
						operand1_val := operand1_val(2*width-2 downto 0) & '0';
						operand2_val := '0' & operand2_val(width-1 downto 1);
						count := count + 1;
					if count = x"20" then
						Result1_multi <= temp_sum(width-1 downto 0);
						Result2_multi <= temp_sum(2*width-1 downto width);
						done <= '1';	
					end if;
			when "10000" => -- mult
				if state = COMBINATIONAL then  -- n_state = MULTI_CYCLE and state = COMBINATIONAL implies we are just transitioning into MULTI_CYCLE					
					if Operand1(width-1) = '1' then
						signed1 := (not Operand1) +1;
					else
						signed1 := Operand1;
					end if;
					
					if Operand2(width-1) = '1' then
						signed2 := (not Operand2) + 1;
					else 
						signed2 := Operand2;
					end if;
					
					operand1_val := (width-1 downto 0 => '0') & signed1;
					operand2_val := signed2;
					temp_sum := (others => '0');
					count := (others => '0');
					sign := Operand1(width-1) xor Operand2(width-1);
				end if;
		
					if operand2_val(0) = '1' then 
						temp_sum := temp_sum + operand1_val;
					end if;
					count := count + 1;
					operand1_val := operand1_val(2*width-2 downto 0) & '0';
					operand2_val := '0' & operand2_val(width-1 downto 1);
						
					if count = x"1F" then
						if sign = '1' then 
							temp_sum := (not temp_sum) + 1;
						end if;
						Result1_multi <= temp_sum(width-1 downto 0);
						Result2_multi <= temp_sum(2*width-1 downto width);
						done <= '1';	
					end if;
			--div
			when "10010" =>
				if state = COMBINATIONAL then
					if Operand1(width-1) = '1' then										--operand1 is negative
						signed1 := (not Operand1) + 1;
					else
						signed1 := Operand1;
					end if;

					if Operand2(width-1) = '1' then										--operand2 is negative
						signed2 := (not Operand2) + 1;
					else
						signed2 := Operand2;
					end if;

					sign_quotient := Operand1(width-1) xor Operand2(width-1);	--sign of quotient
					sign_remainder := Operand1(width-1);								--sign of remainder
					numerator (width-1 downto 0):= signed1(width-1 downto 0);
					denominator (width-1 downto 0) := signed2(width-1 downto 0);
					quotient := (others=>'0');												--initialise quotient
					remainder := (others=>'0');											--initialise remainder
					count := (others=>'0');													--initialise count
				else
					count := count + 1;
					if count=x"21" then														--count = 33
						if sign_quotient = '1' then										--if quotient is negative
							quotient := (not quotient) + 1;
						end if;
						if sign_remainder = '1' then										--if remainder is negative
							remainder := (not remainder) + 1;
						end if;
					
						Result1_multi <= quotient;
						Result2_multi <= remainder;
						done <= '1';
					else
						remainder := remainder(width-2 downto 0) & '0';  -- shift left by 1
						quotient := quotient(width-2 downto 0) & quotient(width-1);  -- rotate left by 1
						numerator := numerator(width-2 downto 0) & numerator(width-1);  -- rotate left by 1

						remainder(0) := numerator(0);

						if remainder >= denominator then
							quotient(0) := '1';
							remainder := remainder-denominator;
--							remainder := remainder+(denominator xor x"FFFFFFFF")+1;
						end if;
					end if;
				end if;
			
			--divu
			when "10011" =>
				if state = COMBINATIONAL then
					numerator := Operand1;
					denominator := Operand2;
					quotient := (others=>'0');
					remainder := (others=>'0');
					count := (others=>'0');
				else
					count := count + 1;
					if count=x"21" then
						Result1_multi <= quotient;
						Result2_multi <= remainder;
						done <= '1';
					else
						remainder := remainder(width-2 downto 0) & '0';  -- shift left by 1
						quotient := quotient(width-2 downto 0) & quotient(width-1);  -- rotate left by 1
						numerator := numerator(width-2 downto 0) & numerator(width-1);  -- rotate left by 1

						remainder(0) := numerator(0);

						if remainder >= denominator then
							quotient(0) := '1';
							remainder := remainder - denominator;
--							remainder := remainder+(denominator xor x"FFFFFFFF")+1;
						end if;
					end if;
				end if;
			when "11110" => -- takes 1 cycle to execute, just returns the operands
				if state = COMBINATIONAL then
					Result1_multi <= Operand1;
					Result2_multi <= Operand2;
					done <= '1';
				end if;	
			when others=> null;
			end case;
		end if;
	end if;
end process;


end Behavioral;


------------------------------------------------------------------
-- Adder Entity
------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity alu_adder is
generic (width : integer := 32);
port (A 		: in std_logic_vector(width-1 downto 0);
		B 		: in std_logic_vector(width-1 downto 0);
		C_in 	: in std_logic;
		S 		: out std_logic_vector(width-1 downto 0);
		C_out	: out std_logic);
end alu_adder;

------------------------------------------------------------------
-- Adder Architecture
------------------------------------------------------------------

architecture alu_adder_arch of alu_adder is
signal S_wider : std_logic_vector(width downto 0);
begin
	S_wider <= ('0'& A) + ('0'& B) + C_in;
	S <= S_wider(width-1 downto 0);
	C_out <= S_wider(width);
end alu_adder_arch;

------------------------------------------------------------------
-- shifter Entity
------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity shifter is
	generic ( width : integer := 32 ); 
    Port ( EN : in  STD_LOGIC;
           CONTROL : in  STD_LOGIC_VECTOR ( 1 downto 0);
           DATA_IN : in  STD_LOGIC_VECTOR (31 downto 0);
           DATA_OUT : out  STD_LOGIC_VECTOR (31 downto 0));
end shifter;

------------------------------------------------------------------
-- Shifter Architecture
------------------------------------------------------------------
architecture Behavioral of shifter is

begin
process(EN,CONTROL,DATA_IN)
begin
	if EN = '1' then
		case CONTROL is
			when "01" =>
				DATA_OUT(31 downto width) <= DATA_IN(31-width downto 0);
				DATA_OUT(width-1 downto 0) <= (others => '0');
			when "11" | "10" =>
				if CONTROL(0) = '1' then
					DATA_OUT(31-width downto 0) <= DATA_IN(31 downto width);
					DATA_OUT(31 downto 31-width+1) <= (others => '0');
				else
					DATA_OUT(31-width downto 0) <= DATA_IN(31 downto width);
					DATA_OUT(31 downto 31-width+1) <= (others => DATA_IN(31));
				end if;
			when others => DATA_OUT <= DATA_IN;
		end case;
	else
		DATA_OUT <= DATA_IN;
	end if;
end process;
end Behavioral;