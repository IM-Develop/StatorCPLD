library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ParallelToI2C is
	port(
		 csi_c0_reset_n			: in std_logic;--avalon #reset
		 csi_c0_clk				: in std_logic;--avalon clock 108MHz
--*********************** Global signals *****************************************
		 avs_s0_read_n			: in std_logic;
		 avs_s0_write_n			: in std_logic;
		 avs_s0_chipselect_n	: in std_logic;
		 avs_s0_address			: in std_logic;
		 avs_s0_readdata		: out std_logic_vector(7 downto 0);
		 avs_s0_readdatavalid	: out std_logic;
		 avs_s0_writedata		: in std_logic_vector(7 downto 0);
		 avs_s0_waitrequest		: out std_logic;
--************************* Avalon-MM Slave **************************************
		 SCL        			: inout std_logic;
		 SDA        			: inout std_logic;
		 Busy       			: buffer std_logic;--interrupt
		 Err					: out std_logic
		);
end ParallelToI2C;

ARCHITECTURE Arc_ParallelToI2C OF ParallelToI2C IS

	-- type 	States is(Idle, Start, Stop, WaitSCL, Write, Read, EndState);
	type 	States is(T1, T2, T3, T4, T5);
	signal 	State 		: States;

	signal 	SCLSig    	: std_logic;
	signal 	SDASig	 	: std_logic;
	signal 	BaudCount 	: std_logic_vector(11 downto 0);

	signal 	Error     	: std_logic;
	
	signal	InProgress	: std_logic;

	signal 	IntBusy   	: std_logic;

	signal 	BitCount  	: std_logic_vector(7 downto 0);
	signal 	TempData  	: std_logic_vector(7 downto 0);

	signal	Update		: std_logic_vector(1 downto 0);

	signal 	Command   	: std_logic_vector(2 downto 0);
	
	-- constant	BaudNumber	: std_logic_vector(11 downto 0) := x"437";--50KHz at 108MHz
	constant	BaudNumber	: std_logic_vector(11 downto 0) := x"1F3";--50KHz at 108MHz
--	"001" = Start
--	"010" = Stop
--	"011" = continue start
--  "100" = read with Master Ack
--  "101" = read without Master Ack
--	"110" = Write Byte

BEGIN

	avs_s0_waitrequest <= '0';
	
	avs_s0_readdata <= 	TempData when(avs_s0_read_n = '0' and avs_s0_chipselect_n = '0' and avs_s0_address = '0') else
						"000000"&Busy&Error when(avs_s0_read_n = '0' and avs_s0_chipselect_n = '0' and avs_s0_address = '1') else
						(others => 'Z');
						
	avs_s0_readdatavalid <= '1' when(avs_s0_read_n = '0' and avs_s0_chipselect_n = '0') else '0';

	Busy <= IntBusy;
	Err <= Error;

	BaudRate_Proc : process(csi_c0_reset_n, csi_c0_clk)
		begin
			if (csi_c0_reset_n = '0') then
				SCLSig <= '0';
				BaudCount <= x"000";
			else
				if rising_edge(csi_c0_clk) then
					if (BaudCount = BaudNumber) then--100KHz BaudNumber
						SCLSig <= not(SCLSig);
						BaudCount <= x"000";
					else
						BaudCount <= BaudCount + 1;
					end if;
				end if;
			end if;
		end process BaudRate_Proc;

	I2C_Proc : process(csi_c0_reset_n, csi_c0_clk)
		begin
			if (csi_c0_reset_n = '0') then
				SDASig <= '1';
				SCL <= 'Z';
				SDA <= 'Z';
				IntBusy <= '0';
				Error <= '0';
				Command <= "000";
				BitCount <= x"00";
				TempData <= x"00";
				InProgress <= '0';
				Update <= "00";
				State <= T1;
			else
				if rising_edge(csi_c0_clk) then
					SDASig <= SDA;
					if (avs_s0_write_n = '0' and avs_s0_chipselect_n = '0') then
						if (avs_s0_address = '1') then
							Update <= "01";
							Command <= avs_s0_writedata(2 downto 0);
						else
							Update <= "10";
							TempData <= avs_s0_writedata;
						end if;
					else
						if (State /= T1) then
							Update <= "00";
						else
							Update <= Update;
						end if;
					end if;
					case State is
						when T1 =>
							BitCount <= x"00";
							if (Update /= "00") then
								case Command is
									when "001" =>--start
										IntBusy <= '1';
										InProgress <= '1';
										if (BaudCount = BaudNumber and SCLSig = '0') then
											if (SCL = '0' and SDA = '0') then
												SCL <= '0';
												SDA <= '1';
												State <= T1;
											elsif (SCL = '0' and SDA = '1') then
												SCL <= 'Z';
												SDA <= '1';
												State <= T1;
											elsif (SCL = '1' and SDA = '0') then
												SCL <= '0';
												SDA <= '0';
												State <= T1;
											else
												SCL <= 'Z';
												SDA <= '0';
												State <= T5;
											end if;
										end if;
									when "010" =>--stop
										IntBusy <= '1';
										if (BaudCount = BaudNumber and SCLSig = '0') then
											if (SCL = '0' and SDA = '0') then
												SCL <= 'Z';
												SDA <= '0';
												InProgress <= '1';
												State <= T1;
											elsif (SCL = '0' and SDA = '1') then
												SCL <= '0';
												SDA <= '0';
												InProgress <= '1';
												State <= T1;
											elsif (SCL = '1' and SDA = '0') then
												SCL <= 'Z';
												SDA <= '1';
												InProgress <= '0';
												State <= T5;
											else
												SCL <= '0';
												SDA <= '1';
												InProgress <= '1';
												State <= T1;
											end if;
										end if;
									when "011" =>--continue start
										IntBusy <= '1';
										InProgress <= '1';
										if (BaudCount = BaudNumber and SCLSig = '0') then
											if (SCL = '0' and SDA = '0') then
												SCL <= '0';
												SDA <= '1';
												State <= T1;
											elsif (SCL = '0' and SDA = '1') then
												SCL <= 'Z';
												SDA <= '1';
												State <= T1;
											elsif (SCL = '1' and SDA = '0') then
												SCL <= '0';
												SDA <= '0';
												State <= T1;
											else
												SCL <= 'Z';
												SDA <= '0';
												State <= T5;
											end if;
										end if;
									when "100"|"101" =>--read with/without ack
										IntBusy <= '1';
										InProgress <= '1';
										if (BaudCount = BaudNumber and SCLSig = '0') then
											State <= T3;
										else
											State <= T1;
										end if;
									when "110" =>--write
										InProgress <= '1';
										if (Update = "10") then--update of data
											IntBusy <= '1';
											if (BaudCount = BaudNumber and SCLSig = '0') then
												SCL <= '0';
												SDA <= '0';
												State <= T2;
											else
												SCL <= SCL;
												SDA <= SDA;
												State <= T1;
											end if;
										else
											IntBusy <= '0';
											SCL <= SCL;
											SDA <= SDA;
											State <= T1;
										end if;
									when others =>
										InProgress <= InProgress;
										SCL <= 'Z';
										SDA <= 'Z';
										IntBusy <= '0';
										Error <= Error;
										State <= T1;
								end case;
							else
								if (InProgress = '1') then
									SCL <= SCL;
									SDA <= SDA;
								else
									SCL <= 'Z';
									SDA <= 'Z';
								end if;
								InProgress <= InProgress;
								IntBusy <= '0';
								Error <= Error;
								State <= T1;
							end if;
						when T2 =>
							InProgress <= InProgress;
							if (BaudCount = BaudNumber) then
								if (SCLSig = '1') then--falling edge
									if (BitCount < x"08") then
										TempData <= TempData(6 downto 0) & '0';
										SDA <= TempData(7);
									else
										SDA <= 'Z';
									end if;
								end if;
								if (SCLSig = '0') then--rising edge
									SCL <= 'Z';
									Error <= '0';
									State <= T2;
								else--falling edge
									-- SCL <= '0';
									if (BitCount >= x"09" and SDA = '0' and SCL = '1') then
										SCL <= 'Z';
										Error <= '0';
										BitCount <= x"00";
										State <= T4;
									else
										if (BitCount > x"F0") then
											SCL <= 'Z';
											Error <= '1';
											BitCount <= x"00";
											State <= T4;
										else
											SCL <= '0';
											Error <= '0';
											BitCount <= BitCount + 1;
											State <= T2;
										end if;
									end if;
								end if;
							end if;
						when T3 =>
							InProgress <= InProgress;
							IntBusy <= '1';
							if (BaudCount = BaudNumber) then
								if (SCLSig = '1') then--falling edge of SCL
									BitCount <= BitCount + 1;
									-- SCL <= '0';
									if (BitCount < x"08") then
										SCL <= '0';
										SDA <= 'Z';
										-- State <= T3;
									elsif (BitCount = x"08") then
										SCL <= '0';
										SDA <= Command(0);
										-- State <= T3;
									else
										SCL <= 'Z';
										SDA <= 'Z';
										-- State <= T4;
									end if;
									State <= T3;
								else
									SCL <= 'Z';
									if (BitCount < x"09") then
										TempData <= TempData(6 downto 0) & SDASig;
										State <= T3;
									else
										TempData <= TempData;
										if (SCL = '1' and BitCount > x"09") then
											State <= T4;
										else
											State <= T3;
										end if;
									end if;
								end if;
							end if;
						when T4 =>
							InProgress <= InProgress;
							-- SCL <= '0';
							if (SCLSig = '1') then
								SCL <= 'Z';
							else
								SCL <= '0';
							end if;
							SDA <= 'Z';
							Error <= Error;
							if (SDASig = '1') then
								IntBusy <= '0';
								Command <= "000";
								State <= T1;
							else
								IntBusy <= '1';
								State <= T4;
							end if;
						when others =>
							SCL <= SCL;
							SDA <= SDA;
							InProgress <= InProgress;
							Error <= Error;
							if (BaudCount = BaudNumber and SCLSig = '0') then
								IntBusy <= '0';
								Command <= "000";
								State <= T1;
							else
								IntBusy <= '1';
								State <= T5;
							end if;
					end case;
				end if;
			end if;
		end process I2C_Proc;

END Arc_ParallelToI2C;
