library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity I2C2AvalonBridge is
	generic(
			DevAdd				: std_logic_vector(7 downto 0) := x"40"
		   );
	port(
		 sci_c0_reset_n			: in std_logic;--avalon #reset
		 sci_c0_clk				: in std_logic;--avalon clock
--*********************** Global signals **************************************
		 SDA					: inout std_logic;
		 SCL					: in std_logic;
--*********************** I2C signals *****************************************
		 avm_m0_read_n			: buffer std_logic;
		 avm_m0_write_n			: buffer std_logic;
		 avm_m0_address			: buffer std_logic_vector(7 downto 0);
		 avm_m0_readdata		: in std_logic_vector(7 downto 0);
		 avm_m0_readdatavalid	: in std_logic;
		 avm_m0_writedata		: buffer std_logic_vector(7 downto 0);
		 avm_m0_waitrequest		: in std_logic
--************************* Avalon-MM *****************************************
		);
end I2C2AvalonBridge;

ARCHITECTURE Arc_I2C2AvalonBridge OF I2C2AvalonBridge IS

	type 	States is(IdleState, DevAddState, RegAddState, ReadState, WriteState);--, StopState);
	signal 	State 			: States;
	
	signal	SCLLatch		: std_logic_vector(3 downto 0);--for high speed clock need more bits
	signal	SDALatch		: std_logic_vector(3 downto 0);--for high speed clock need more bits
	signal	StartCondition	: std_logic;
	signal	StartContinue	: std_logic;
	signal	StopCondition	: std_logic;
	signal	ReadData		: std_logic_vector(8 downto 0);
	signal	WriteData		: std_logic_vector(8 downto 0);
	signal	WriteEnable		: std_logic;
	signal	ReadCount		: std_logic_vector(3 downto 0);
	signal	Read_nWrite		: std_logic;
	signal	TestWriteData	: std_logic_vector(8 downto 0);
	signal	LoadData		: std_logic;
	signal	TimeOut			: std_logic_vector(11 downto 0);
	
	signal	IntSCL			: std_logic;
	
BEGIN

	StopStart_Proc : process(sci_c0_reset_n, sci_c0_clk)
		begin	
			if (sci_c0_reset_n='0')then
				SCLLatch <= x"F";
			    SDALatch <= x"F";
				StartCondition <= '0';
				StopCondition <= '0';
				IntSCL <= '0';
			else
				if rising_edge (sci_c0_clk)then
					IntSCL <= SCL;
					SCLLatch <= SCLLatch(2 downto 0) & IntSCL;
				    SDALatch <= SDALatch(2 downto 0) & SDA;
					if (SCLLatch = x"F" and SDALatch = x"C") then--start
						StartCondition <= '1';
						StopCondition <= '0';
					elsif (SCLLatch = x"F" and SDALatch = x"3") then--stop
						StartCondition <= '0';
						StopCondition <= '1';
					else
						StartCondition <= '0';
						StopCondition <= '0';
					end if;
				end if;
			end if;
		end process StopStart_Proc;

	I2CRead_Proc : process(sci_c0_reset_n, sci_c0_clk)
		begin	
			if (sci_c0_reset_n='0')then
				ReadData <= "000000000";
				ReadCount <= x"0";
			else
				if rising_edge (sci_c0_clk)then
					if (StartCondition = '1' or StopCondition = '1') then
						ReadData <= "000000000";
						ReadCount <= x"0";
					elsif (SCLLatch = x"3" and ReadCount < x"9") then--rising edge
						ReadData <= ReadData(7 downto 0) & SDA;
						ReadCount <= ReadCount + 1;
					elsif (SCLLatch = x"0" and ReadCount = x"9") then--low on scl
						ReadData <= ReadData;
						ReadCount <= x"0";
					else
						ReadData <= ReadData;
						ReadCount <= ReadCount;
					end if;
				end if;
			end if;
		end process I2CRead_Proc;

	I2CWrite_Proc : process(sci_c0_reset_n, sci_c0_clk)
		begin	
			if (sci_c0_reset_n='0')then
				SDA <= 'Z';
				WriteData <= "000000000";
			else
				if rising_edge (sci_c0_clk)then--StartContinue
					if (LoadData = '1') then
						if (WriteEnable = '1' and StartContinue = '1') then
							SDA <= TestWriteData(8);
							WriteData <= TestWriteData(7 downto 0) & '0';
						else
							SDA <= SDA;
							WriteData <= TestWriteData;
						end if;
					else
						if (WriteEnable = '1') then
							if (SCLLatch = x"C") then--falling edge
								WriteData <= WriteData(7 downto 0) & '0';
								SDA <= WriteData(8);
							end if;
						else
							if (SCLLatch = x"C") then
								WriteData <= WriteData(7 downto 0) & '0';
							end if;
							SDA <= 'Z';
						end if;
					end if;
				end if;
			end if;
		end process I2CWrite_Proc;

	I2C2Avalon_Proc : process(sci_c0_reset_n, sci_c0_clk)
		begin	
			if (sci_c0_reset_n='0')then
				WriteEnable <= '0';
				LoadData <= '0';
				TestWriteData <= "000000000";
				Read_nWrite <= '0';
				avm_m0_read_n <= '1';
				avm_m0_write_n <= '1';
				avm_m0_address <= x"00";
				avm_m0_writedata <= x"00";
				StartContinue <= '0';
				TimeOut <= x"000";
				State <= IdleState;
			else
				if rising_edge (sci_c0_clk)then
					case State is
						when IdleState =>
							WriteEnable <= '0';
							TestWriteData <= "000000000";
							Read_nWrite <= '0';
							avm_m0_read_n <= '1';
							avm_m0_write_n <= '1';
							avm_m0_address <= x"00";
							avm_m0_writedata <= x"00";
							StartContinue <= '0';
							TimeOut <= x"000";
							if (StartCondition = '1') then
								LoadData <= '1';
								State <= DevAddState;
							else
								LoadData <= '0';
								State <= IdleState;
							end if;
						when DevAddState =>
							LoadData <= '0';
							TestWriteData <= TestWriteData;
							-- avm_m0_read_n <= '1';
							avm_m0_write_n <= '1';
							avm_m0_address <= avm_m0_address;
							avm_m0_writedata <= x"00";
							StartContinue <= StartContinue;
							if (SCLLatch = x"F" and ReadCount = x"9") then
								TimeOut <= TimeOut + 1;
							else
								TimeOut <= x"000";
							end if;
							if (SCLLatch = x"C" and ReadCount = x"7") then--falling edge of SCL
								if (ReadData(7 downto 0) = DevAdd) then
									WriteEnable <= '1';
									Read_nWrite <= '0';
									State <= DevAddState;
								else
									WriteEnable <= '0';
									Read_nWrite <= '0';
									State <= IdleState;
								end if;
							elsif (SCLLatch = x"C" and ReadCount = x"8" and WriteEnable = '1') then--falling edge of SCL
								WriteEnable <= '1';
								Read_nWrite <= ReadData(0);
								State <= DevAddState;
							elsif (SCLLatch = x"C" and ReadCount = x"9") then--falling edge of SCL
								-- WriteEnable <= '0';
								Read_nWrite <= Read_nWrite;
								if (StartContinue = '0') then
									avm_m0_read_n <= '1';
									WriteEnable <= '0';
									State <= RegAddState;
								else
									if (Read_nWrite = '1') then
										avm_m0_read_n <= '0';
										WriteEnable <= '1';
										State <= ReadState;
									else
										avm_m0_read_n <= '1';
										WriteEnable <= '0';
										State <= WriteState;
									end if;
								end if;
							elsif (TimeOut = x"CA8") then
								WriteEnable <= '0';
								Read_nWrite <= '0';
								State <= IdleState;
							else
								WriteEnable <= WriteEnable;
								Read_nWrite <= Read_nWrite;
								State <= DevAddState;
							end if;
						when RegAddState =>
							TestWriteData <= avm_m0_readdata & '0';
							Read_nWrite <= Read_nWrite;
							LoadData <= avm_m0_readdatavalid and Read_nWrite;
							avm_m0_write_n <= '1';
							avm_m0_writedata <= x"00";
							StartContinue <= StartContinue;
							if (SCLLatch = x"F" and ReadCount = x"9") then
								TimeOut <= TimeOut + 1;
							else
								TimeOut <= x"000";
							end if;
							if (SCLLatch = x"C" and ReadCount = x"8") then
								avm_m0_address <= ReadData(7 downto 0);
								avm_m0_read_n <= not(Read_nWrite);
							else
								avm_m0_address <= avm_m0_address;
								if (avm_m0_readdatavalid = '1') then
									avm_m0_read_n <= '1';
								else
									avm_m0_read_n <= avm_m0_read_n;
								end if;
							end if;
							if (SCLLatch = x"C" and ReadCount = x"7") then
								WriteEnable <= '1';
								State <= RegAddState;
							elsif (SCLLatch = x"C" and ReadCount = x"9") then
								if (Read_nWrite = '1') then
									WriteEnable <= '1';
									State <= ReadState;
								else
									WriteEnable <= '0';
									State <= WriteState;
								end if;
							elsif (TimeOut = x"CA8") then
								WriteEnable <= '0';
								State <= IdleState;
							else
								WriteEnable <= WriteEnable;
								State <= RegAddState;
							end if;
						when ReadState =>
							Read_nWrite <= Read_nWrite;
							TestWriteData <= avm_m0_readdata & '0';
							LoadData <= avm_m0_readdatavalid and Read_nWrite;
							avm_m0_write_n <= '1';
							avm_m0_writedata <= x"00";
							if (SCLLatch = x"F" and ReadCount = x"9") then
								TimeOut <= TimeOut + 1;
							else
								TimeOut <= x"000";
							end if;
							-- if (SCLLatch = x"C" and ReadCount = x"8") then
								-- avm_m0_address <= avm_m0_address + 1;
								-- avm_m0_read_n <= not(Read_nWrite);
							-- else
								avm_m0_address <= avm_m0_address;
								if (avm_m0_readdatavalid = '1') then
									avm_m0_read_n <= '1';
								else
									avm_m0_read_n <= avm_m0_read_n;
								end if;
							-- end if;
							if (StopCondition = '1') then
								WriteEnable <= '0';
								StartContinue <= '0';
								State <= IdleState;
							elsif (StartCondition = '1') then
								WriteEnable <= '0';
								StartContinue <= '1';
								State <= DevAddState;
							elsif (SCLLatch = x"C" and ReadCount = x"8") then
								WriteEnable <= '0';
								StartContinue <= StartContinue;
								State <= ReadState;
							elsif (SCLLatch = x"3" and ReadCount = x"8") then
								WriteEnable <= not(SDA);
								StartContinue <= StartContinue;
								State <= ReadState;
							elsif (TimeOut = x"CA8") then
								WriteEnable <= '0';
								State <= IdleState;
							else
								WriteEnable <= WriteEnable;
								StartContinue <= StartContinue;
								State <= ReadState;
							end if;
						when others =>--WriteState
							if (SCLLatch = x"F" and ReadCount = x"9") then
								TimeOut <= TimeOut + 1;
							else
								TimeOut <= x"000";
							end if;
							if (SCLLatch = x"C" and ReadCount = x"8") then
								avm_m0_write_n <= '0';
								avm_m0_writedata <= ReadData(7 downto 0);
								avm_m0_address <= avm_m0_address;
							else
								avm_m0_writedata <= avm_m0_writedata;
								if (avm_m0_waitrequest = '0' and avm_m0_write_n = '0') then
									avm_m0_write_n <= '1';
									avm_m0_address <= avm_m0_address + 1;
								else
									avm_m0_write_n <= avm_m0_write_n;
									avm_m0_address <= avm_m0_address;
								end if;
							end if;
							if (StopCondition = '1') then
								WriteEnable <= '0';
								StartContinue <= '0';
								State <= IdleState;
							elsif (StartCondition = '1') then
								WriteEnable <= '0';
								StartContinue <= '1';
								State <= DevAddState;
							elsif (SCLLatch = x"C" and ReadCount = x"7") then
								WriteEnable <= '1';
								StartContinue <= StartContinue;
								State <= WriteState;
							elsif (SCLLatch = x"C" and ReadCount = x"9") then
								WriteEnable <= '0';
								StartContinue <= StartContinue;
								State <= WriteState;
							elsif (TimeOut = x"CA8") then
								WriteEnable <= '0';
								State <= IdleState;
							else
								WriteEnable <= WriteEnable;
								StartContinue <= StartContinue;
								State <= WriteState;
							end if;
					end case;
				end if;
			end if;
		end process I2C2Avalon_Proc;
		
END Arc_I2C2AvalonBridge;