library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- use work.AltInitConstantPKG.all;

entity Avl2I2CBridge is
	port(
		 csi_c0_reset_n			: in std_logic;--avalon #reset
		 csi_c0_clk				: in std_logic;--avalon clock
		 -- LoadingBusy			: in std_logic;
--*********************** Global signals *****************************************
		 avs_s0_read_n			: in std_logic;
		 avs_s0_write_n			: in std_logic;
		 avs_s0_chipselect_n	: in std_logic;
		 avs_s0_readdata		: out std_logic_vector(31 downto 0);
		 avs_s0_readdatavalid	: out std_logic;
		 avs_s0_writedata		: in std_logic_vector(31 downto 0);
		 avs_s0_waitrequest		: out std_logic;
--************************* Avalon-MM Slave **************************************
		 SCL        			: inout std_logic;
		 SDA        			: inout std_logic
--************************* export signals ***************************************
		);
end Avl2I2CBridge;

ARCHITECTURE Arc_Avl2I2CBridge OF Avl2I2CBridge IS

	component ParallelToI2C
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
	end component;

	type 	States is(T1, T2, T3, T4);--, T5, T6);
	signal 	State					: States;
	
	signal	I2CCtrlReg				: std_logic_vector(31 downto 0);
	signal	ClearReg				: std_logic;
	
	signal	U1nRead					: std_logic;
	signal	U1nWrite				: std_logic;
	signal	U1nCS					: std_logic;
	signal	U1Add					: std_logic;
	signal	U1RdValid				: std_logic;
	signal	U1WaitReq				: std_logic;
	signal	U1Busy					: std_logic;
	signal	U1QData					: std_logic_vector(7 downto 0);
	signal	U1Data					: std_logic_vector(8 downto 0);
	signal	U1Error					: std_logic;
	
	signal	Status					: std_logic_vector(1 downto 0);
	
	signal	WaitState				: integer range 0 to 15;
	
	-- signal	A						: integer range 0 to (NumI2CChanel - 1);
	signal	ByteCount				: integer range 0 to 15;
	
	-- constant I2CChanelSwitchConst 	: I2CChanel := I2CChanelSwitch;
	
BEGIN

	avs_s0_waitrequest <= '0';
						
	Avalon_Proc : process(csi_c0_reset_n, csi_c0_clk)
		begin	
			if (csi_c0_reset_n = '0')then
				I2CCtrlReg <= (others => '0');
				avs_s0_readdatavalid <= '0';
				avs_s0_readdata	<= (others => '0');
			else
				if rising_edge (csi_c0_clk)then
					if (avs_s0_read_n = '0' and avs_s0_chipselect_n = '0') then
						avs_s0_readdatavalid <= '1';
						avs_s0_readdata(23 downto 0) <= I2CCtrlReg(23 downto 0);
						avs_s0_readdata(31 downto 24) <= "000" & Status(0) & "000" & Status(1);
					else--										 Busy				 Error
						avs_s0_readdatavalid <= '0';
						avs_s0_readdata	<= (others => '0');
					end if;
					if (avs_s0_write_n = '0' and avs_s0_chipselect_n = '0') then
						I2CCtrlReg <= avs_s0_writedata;
					elsif (U1RdValid = '1') then
						I2CCtrlReg(7 downto 0) <= U1QData;
						I2CCtrlReg(31 downto 8) <= I2CCtrlReg(31 downto 8);
					elsif (ClearReg = '1') then
						I2CCtrlReg(7 downto 0) <= I2CCtrlReg(7 downto 0);
						I2CCtrlReg(31 downto 8) <= (others => '0');
					else
						I2CCtrlReg <= I2CCtrlReg;
					end if;
				end if;
			end if;
		end process Avalon_Proc;
		
	U1 : ParallelToI2C
		port map(
				 csi_c0_reset_n			=> csi_c0_reset_n,
				 csi_c0_clk				=> csi_c0_clk,
				 avs_s0_read_n			=> U1nRead,
				 avs_s0_write_n			=> U1nWrite,
				 avs_s0_chipselect_n	=> U1nCS,
				 avs_s0_address			=> U1Add,
				 avs_s0_readdata		=> U1QData,
				 avs_s0_readdatavalid	=> U1RdValid,
				 avs_s0_writedata		=> U1Data(7 downto 0),
				 avs_s0_waitrequest		=> U1WaitReq,
				 SCL        			=> SCL,
				 SDA        			=> SDA,
				 Busy       			=> U1Busy,
				 Err					=> U1Error
				);
				
	Cmos_Proc : process(csi_c0_reset_n, csi_c0_clk)
		begin	
			if (csi_c0_reset_n = '0')then
				U1nRead <= '1';
				U1nWrite <= '1';
				U1nCS <= '1';
				U1Add <= '0';
				U1Data <= (others => '0');
				-- A <= 0;
				ByteCount <= 0;
				ClearReg <= '0';
				WaitState <= 0;
				Status <= "00";
				State <= T1;
			else
				if rising_edge (csi_c0_clk)then
					U1Add <= U1Data(8);
					case State is
						when T1 =>
							U1nRead <= '1';
							U1nWrite <= '1';
							U1nCS <= '1';
							ByteCount <= 0;
							ClearReg <= '0';
							WaitState <= 0;
							if (I2CCtrlReg(31 downto 28) /= 0 and U1Busy = '0') then-- and LoadingBusy = '0') then
								Status <= "01";
								State <= T2;
							else
								Status(0) <= U1Busy;
								Status(1) <= Status(1);
								State <= T1;
							end if;
						when T2 =>
							ByteCount <= ByteCount;
							if (U1Busy = '0') then
								Status <= Status;
								case ByteCount is
									when 0 =>
										U1nWrite <= '0';
										U1Data <= "100000001";--start
									when 1 =>
										U1nWrite <= '0';
										U1Data <= "100000110";--write command
									when 2 =>
										U1nWrite <= '0';
										U1Data <= '0'&I2CCtrlReg(22 downto 16)&'0';--dev add + write
									when 3 =>
										U1nWrite <= '0';
										U1Data <= "100000110";--write command
									when 4 =>
										U1nWrite <= '0';
										U1Data <= '0'&I2CCtrlReg(15 downto 8);--reg add
									when 5 =>
										U1nWrite <= '0';
										U1Data <= "100000110";--write command
									when 6 =>
										U1nWrite <= '0';
										U1Data <= '0'&I2CCtrlReg(7 downto 0);--data
									when 7 =>
										U1nWrite <= '0';
										U1Data <= "100000011";--continue start
									when 8 =>
										U1nWrite <= '0';
										U1Data <= "100000110";--write command
									when 9 =>
										U1nWrite <= '0';
										U1Data <= '0'&I2CCtrlReg(22 downto 16)&'1';--dev add + read
									when 10 =>
										U1nWrite <= '0';
										U1Data <= "100000101";--read without Master Ack
									when others =>
										U1nWrite <= '0';
										U1Data <= "100000010";--stop
								end case;
								if (WaitState = 4) then
									U1nCS <= '0';
									WaitState <= 0;
									State <= T3;
								else
									U1nCS <= '1';
									WaitState <= WaitState + 1;
									State <= T2;
								end if;
							else
								if (U1Error = '1') then
									Status <= Status or "10";
								else
									Status <= Status and "01";
								end if;
								ClearReg <= '0';
								U1nWrite <= '1';
								U1nRead <= '1';
								U1nCS <= '1';
								WaitState <= 0;
								State <= T2;
							end if;
						when T3 =>
							U1nRead <= '1';
							U1nWrite <= '1';
							U1nCS <= '1';
							WaitState <= 0;
							U1Data <= U1Data;
							if (U1Busy = '1' or U1Data = "100000110" or U1Data = "100000011") then--working or set write command
								if (I2CCtrlReg(31 downto 28) = x"1") then--write operation
									if (ByteCount = 6) then
										ClearReg <= '0';
										ByteCount <= 15;
										if (U1Error = '1') then
											Status <= Status or "10";
										else
											Status <= Status and "01";
										end if;
										State <= T2;
									elsif (ByteCount = 15) then
										ClearReg <= '1';
										ByteCount <= 0;
										Status <= Status and "10";
										State <= T1;
									else
										ClearReg <= '0';
										ByteCount <= ByteCount + 1;
										if (U1Error = '1') then
											Status <= Status or "10";
										else
											Status <= Status and "01";
										end if;
										State <= T2;
									end if;
								elsif (I2CCtrlReg(31 downto 28) = x"2") then--read operation
									if (ByteCount = 4) then
										ClearReg <= '0';
										ByteCount <= 7;
										if (U1Error = '1') then
											Status <= Status or "10";
										else
											Status <= Status and "01";
										end if;
										State <= T2;
									elsif (ByteCount = 10) then
										ClearReg <= '0';
										ByteCount <= 15;
										if (U1Error = '1') then
											Status <= Status or "10";
										else
											Status <= Status and "01";
										end if;
										State <= T4;
									elsif (ByteCount = 15) then
										ClearReg <= '1';
										ByteCount <= 0;
										Status <= Status and "10";
										State <= T1;
									else
										ClearReg <= '0';
										ByteCount <= ByteCount + 1;
										if (U1Error = '1') then
											Status <= Status or "10";
										else
											Status <= Status and "01";
										end if;
										State <= T2;
									end if;
								else--bug
									if (ByteCount = 15) then
										ClearReg <= '1';
										ByteCount <= 0;
										Status <= "10";
										State <= T1;
									else
										ClearReg <= '0';
										ByteCount <= 15;
										if (U1Error = '1') then
											Status <= Status or "10";
										else
											Status <= Status and "01";
										end if;
										State <= T2;
									end if;
								end if;
							else
								Status <= Status;
								ClearReg <= '0';
								ByteCount <= ByteCount;
								State <= T3;
							end if;
						when others =>
							ByteCount <= ByteCount;
							U1nWrite <= '1';
							WaitState <= 0;
							ClearReg <= '0';
							U1Data <= (others => '0');
							if (U1Busy = '0') then
								Status <= Status;
								if (U1RdValid = '1') then
									U1nCS <= '1';
									U1nRead <= '1';
									State <= T2;
								else
									U1nCS <= '0';
									U1nRead <= '0';
									State <= T4;
								end if;
							else
								if (U1Error = '1') then
									Status <= Status or "10";
								else
									Status <= Status and "01";
								end if;
								U1nCS <= '1';
								U1nRead <= '1';
								State <= T4;
							end if;
					end case;
				end if;
			end if;
		end process Cmos_Proc;

END Arc_Avl2I2CBridge;