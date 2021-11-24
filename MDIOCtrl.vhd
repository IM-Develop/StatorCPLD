library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity MDIOCtrl is
	port(
		 csi_c0_reset_n			: in std_logic;--avalon #reset
		 csi_c0_clk				: in std_logic;--avalon clock 50MHz
--*********************** Global signals *****************************************
		 avs_s0_read_n			: in std_logic;
		 avs_s0_write_n			: in std_logic;
		 avs_s0_chipselect_n	: in std_logic;
		 avs_s0_address			: in std_logic;
		 avs_s0_readdata		: buffer std_logic_vector(31 downto 0);
		 avs_s0_readdatavalid	: out std_logic;
		 avs_s0_writedata		: in std_logic_vector(31 downto 0);
		 avs_s0_waitrequest		: out std_logic;
--************************* Avalon-MM Slave **************************************
		 MDC					: buffer std_logic;
		 MDIO					: inout std_logic
--************************* export signals ***************************************
		);
end MDIOCtrl;

ARCHITECTURE Arc_MDIOCtrl OF MDIOCtrl IS

	signal 	MDIODQ		: std_logic_vector(140 downto 0);
	signal 	MDIOEn		: std_logic_vector(140 downto 0);
	signal	BitCount	: integer range 0 to 255;
	signal	ConfigData	: std_logic_vector(31 downto 0);
	signal	ConfigReg	: std_logic_vector(15 downto 0);
	
	signal	MDCSig		: std_logic;
	signal	MDCEn		: std_logic;
	
	signal	WaitRqs		: std_logic;
	signal	DataValid	: std_logic;
	
	signal	Ready		: std_logic;
	
	signal	State		: std_logic_vector(3 downto 0);
	signal	ClockCount	: std_logic_vector(15 downto 0);
	
	signal	MDCClkRate 	: std_logic_vector(15 downto 0) := x"0018";--1MHz
	
-- 32xClk of '1', 2xClk of '0', 2xClk of Set Address("00"),      10xClk of phy/device, 2xClk of "10", 16xClk of register add, 2xClk of '1' = 66bit
-- 32xClk of '1', 2xClk of '0', 2xClk of Read("11")/Write("01"), 10xClk of phy/device, 2xClk of "10", 16xClk of register data, 2xClk of '1' = 66bit
--																					   in read this is 2x"ZZ"
	
BEGIN

	avs_s0_waitrequest <= '0';
						
	Avalon_Proc : process(csi_c0_reset_n, csi_c0_clk)
		begin	
			if (csi_c0_reset_n = '0')then
				avs_s0_readdatavalid <= '0';
				avs_s0_readdata	<= (others => '0');
				ConfigData <= (others => '0');
				ConfigReg <= x"0000";
			else
				if rising_edge (csi_c0_clk)then
					if (avs_s0_read_n = '0' and avs_s0_chipselect_n = '0') then
						avs_s0_readdatavalid <= '1';
						if (avs_s0_address = '0') then
							avs_s0_readdata	<= Ready & "000" & x"000" & MDIODQ(18 downto 3);
						else
							avs_s0_readdata	<= x"0000" & ConfigReg;
						end if;
					else
						avs_s0_readdatavalid <= '0';
						avs_s0_readdata	<= (others => '0');
					end if;
					if (avs_s0_write_n = '0' and avs_s0_chipselect_n = '0' and WaitRqs = '0') then
						if (avs_s0_address = '0') then
							ConfigData <= avs_s0_writedata;
						else
							ConfigReg <= avs_s0_writedata(15 downto 0);
						end if;
					elsif (WaitRqs = '1') then
						ConfigData <= (others => '0');
						ConfigReg <= x"0000";
					end if;
				end if;
			end if;
		end process Avalon_Proc;

	MDC <= MDCSig when(MDCEn = '1') else '0';
	MDIO <= MDIODQ(140) when(MDIOEn(140) = '1') else 'Z';

	MDIO_Proc : process(csi_c0_reset_n, csi_c0_clk)
		begin	
			if (csi_c0_reset_n = '0')then
				WaitRqs <= '0';
				DataValid <= '0';
				ClockCount <= (others => '0');
				MDCSig <= '0';
				MDCEn <= '0';
				MDIODQ <= (others => '1');
				MDIOEn <= (others => '0');
				BitCount <= 0;
				Ready <= '0';
				State <= x"0";
			else
				if rising_edge (csi_c0_clk)then
					case State is
						when x"0" =>
							if (ConfigReg(15) = '1' and ConfigReg(14) = '0') then--read
								WaitRqs <= '1';
								DataValid <= '0';
								MDIODQ(140 downto 109) <= (others => '1');
								MDIODQ(108 downto 105) <= (others => '0');
								MDIODQ(104 downto 95) <= ConfigReg(9 downto 0);--phy/device
								MDIODQ(94 downto 93) <= "10";
								MDIODQ(92 downto 77) <= ConfigData(31 downto 16);--register address
								MDIODQ(76 downto 34) <= (others => '1');
								MDIODQ(33 downto 30) <= "0011";--read
								MDIODQ(29 downto 20) <= ConfigReg(9 downto 0);--phy/device
								MDIODQ(19 downto 0) <= (others => '1');
								MDIOEn(140 downto 20) <= (others => '1');
								MDIOEn(19 downto 2) <= (others => '0');
								MDIOEn(1 downto 0) <= (others => '1');
								-- MDIODQ(47 downto 40) <= x"FF";
								-- MDIODQ(39 downto 36) <= "0110";
								-- MDIODQ(35 downto 31) <= ConfigReg(9 downto 5);--phy address
								-- MDIODQ(30 downto 26) <= ConfigReg(4 downto 0);--device address
								-- MDIODQ(25 downto 24) <= "11";
								-- MDIODQ(23 downto 0) <= (others => '1');
								-- MDIOEn(47 downto 26) <= (others => '1');
								-- MDIOEn(25 downto 0) <= (others => '0');
								BitCount <= 140;
								MDCEn <= '1';
								Ready <= '1';
								State <= x"2";
							elsif (ConfigReg(15) = '1' and ConfigReg(14) = '1') then--write
								MDIODQ(140 downto 109) <= (others => '1');
								MDIODQ(108 downto 105) <= (others => '0');
								MDIODQ(104 downto 95) <= ConfigReg(9 downto 0);--phy/device
								MDIODQ(94 downto 93) <= "10";
								MDIODQ(92 downto 77) <= ConfigData(31 downto 16);--register address
								MDIODQ(76 downto 34) <= (others => '1');
								MDIODQ(33 downto 30) <= "0001";--write
								MDIODQ(29 downto 20) <= ConfigReg(9 downto 0);--phy/device
								MDIODQ(19 downto 18) <= "10";
								MDIODQ(17 downto 2) <= ConfigData(15 downto 0);--register address
								MDIODQ(1 downto 0) <= "11";
								MDIOEn <= (others => '1');
								-- MDIODQ(47 downto 40) <= x"FF";
								-- MDIODQ(39 downto 36) <= "0101";
								-- MDIODQ(35 downto 31) <= ConfigReg(9 downto 5);
								-- MDIODQ(30 downto 26) <= ConfigReg(4 downto 0);
								-- MDIODQ(25 downto 24) <= "10";
								-- MDIODQ(23 downto 0) <= ConfigData & x"FF";
								-- MDIOEn <= (others => '1');
								BitCount <= 140;
								MDCEn <= '1';
								Ready <= '1';
								State <= x"1";
							else
								WaitRqs <= '0';
								DataValid <= '0';
								MDIOEn <= (others => '0');
								MDCEn <= '0';
								Ready <= '0';
								State <= x"0";
							end if;
						when x"1" =>
							Ready <= '1';
							if (BitCount > 74 or BitCount < 66) then
								MDCEn <= '1';
							else
								MDCEn <= '0';
							end if;
							if (ClockCount = MDCClkRate and MDCSig = '1') then
								MDIODQ <= MDIODQ(139 downto 0) & '1';
								MDIOEn <= MDIOEn(139 downto 0) & '0';
								if (BitCount = 0) then
									WaitRqs <= '0';
									BitCount <= 0;
									MDCEn <= '0';
									State <= x"0";
								else
									WaitRqs <= '1';
									BitCount <= BitCount - 1;
									-- MDCEn <= '1';
									State <= x"1";
								end if;
							else
								WaitRqs <= '1';
								BitCount <= BitCount;
								-- MDCEn <= '1';
								State <= x"1";
							end if;
						when x"2" =>
							Ready <= '1';
							if (BitCount > 74 or BitCount < 66) then
								MDCEn <= '1';
							else
								MDCEn <= '0';
							end if;
							if (ClockCount = MDCClkRate and MDCSig = '1') then
								MDIODQ <= MDIODQ(139 downto 0) & MDIO;
								MDIOEn <= MDIOEn(139 downto 0) & '0';
								if (BitCount = 0) then
									WaitRqs <= '0';
									DataValid <= '1';
									BitCount <= 0;
									State <= x"3";
								else
									WaitRqs <= '1';
									DataValid <= '0';
									BitCount <= BitCount - 1;
									State <= x"2";
								end if;
							else
								WaitRqs <= '1';
								DataValid <= '0';
								BitCount <= BitCount;
								State <= x"2";
							end if;
						when others =>
							MDIODQ <= MDIODQ;
							WaitRqs <= '0';
							DataValid <= '1';
							BitCount <= 0;
							Ready <= '1';
							if (ClockCount = MDCClkRate and MDCSig = '1') then
								if (avs_s0_chipselect_n = '1') then
									MDCEn <= '0';
									State <= x"0";
								else
									MDCEn <= '1';
									State <= x"3";
								end if;
							else
								MDCEn <= '1';
								State <= x"3";
							end if;
					end case;
					if (ClockCount = MDCClkRate) then
						MDCSig <= not(MDCSig);
						ClockCount <= (others => '0');
					else
						MDCSig <= MDCSig;
						ClockCount <= ClockCount + 1;
					end if;
				end if;
			end if;
		end process MDIO_Proc;

END Arc_MDIOCtrl;