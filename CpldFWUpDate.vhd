library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity CpldFWUpDate is
	port(
		 csi_c0_reset_n			: in std_logic;--avalon #reset
		 csi_c0_clk				: in std_logic;--avalon clock 6.25MHz
--*********************** Global signals *****************************************
		 avs_s0_read_n			: in std_logic;
		 avs_s0_write_n			: in std_logic;
		 avs_s0_chipselect_n	: in std_logic;
		 avs_s0_address			: in std_logic_vector(3 downto 0);
		 avs_s0_readdata		: out std_logic_vector(7 downto 0);
		 avs_s0_readdatavalid	: out std_logic;
		 avs_s0_writedata		: in std_logic_vector(7 downto 0);
		 avs_s0_waitrequest		: out std_logic;
--************************* Avalon-MM Slave **************************************
		 avm_m0_read_n			: out std_logic;
		 avm_m0_write_n			: buffer std_logic;
		 avm_m0_address			: buffer std_logic_vector(31 downto 0);
		 avm_m0_readdata		: in std_logic_vector(31 downto 0);
		 avm_m0_readdatavalid	: in std_logic;
		 avm_m0_writedata		: buffer std_logic_vector(31 downto 0);
		 avm_m0_byteenable		: out std_logic_vector(3 downto 0);
		 avm_m0_waitrequest		: in std_logic
--************************* Avalon-MM Master ********************************
		);
end CpldFWUpDate;

ARCHITECTURE Arc_CpldFWUpDate OF CpldFWUpDate IS

	function RotateBit (Data : std_logic_vector(31 downto 0)) return std_logic_vector is
		variable Output : std_logic_vector(31 downto 0);
		begin
			Output(24) := Data(7);
			Output(25) := Data(6);
			Output(26) := Data(5);
			Output(27) := Data(4);
			Output(28) := Data(3);
			Output(29) := Data(2);
			Output(30) := Data(1);
			Output(31) := Data(0);

			Output(16) := Data(15);
			Output(17) := Data(14);
			Output(18) := Data(13);
			Output(19) := Data(12);
			Output(20) := Data(11);
			Output(21) := Data(10);
			Output(22) := Data(9);
			Output(23) := Data(8);

			Output(8) := Data(23);
			Output(9) := Data(22);
			Output(10) := Data(21);
			Output(11) := Data(20);
			Output(12) := Data(19);
			Output(13) := Data(18);
			Output(14) := Data(17);
			Output(15) := Data(16);

			Output(0) := Data(31);
			Output(1) := Data(30);
			Output(2) := Data(29);
			Output(3) := Data(28);
			Output(4) := Data(27);
			Output(5) := Data(26);
			Output(6) := Data(25);
			Output(7) := Data(24);
			
			return(Output);
		end RotateBit;

	type 	States is(T1, T2, T3);--, T4, T5);
	signal 	State				: States;
	
	signal	AddressReg			: std_logic_vector(31 downto 0);
	signal	DataInReg			: std_logic_vector(31 downto 0);
	-- signal	DataOutReg			: std_logic_vector(31 downto 0);
	signal	OperatReg			: std_logic_vector(7 downto 0);
	

	signal	RegErase		: std_logic;
	
	-- signal	ReadASMICount	: std_logic;

BEGIN

	avs_s0_waitrequest <= '0';
	avm_m0_byteenable <= x"F";
	
	AvalonS_Proc : process(csi_c0_reset_n, csi_c0_clk)
		begin	
			if (csi_c0_reset_n = '0')then
				avs_s0_readdatavalid <= '0';
				avs_s0_readdata	<= (others => '0');
				AddressReg <= (others => '0');
				DataInReg <= (others => '0');
				OperatReg <= x"00";
			else
				if rising_edge (csi_c0_clk)then
					if (avs_s0_read_n = '0' and avs_s0_chipselect_n = '0') then
						avs_s0_readdatavalid <= '1';
						case avs_s0_address is
							when x"0" =>
								avs_s0_readdata	<= AddressReg(7 downto 0);
							when x"1" =>
								avs_s0_readdata	<= AddressReg(15 downto 8);
							when x"2" =>
								avs_s0_readdata	<= AddressReg(23 downto 16);
							when x"3" =>
								avs_s0_readdata	<= AddressReg(31 downto 24);
							when x"4" =>
								avs_s0_readdata	<= DataInReg(7 downto 0);
							when x"5" =>
								avs_s0_readdata	<= DataInReg(15 downto 8);
							when x"6" =>
								avs_s0_readdata	<= DataInReg(23 downto 16);
							when x"7" =>
								avs_s0_readdata	<= DataInReg(31 downto 24);
							when x"8" =>
								avs_s0_readdata	<= OperatReg;
							when others =>
								null;
						end case;
					else
						avs_s0_readdatavalid <= '0';
						avs_s0_readdata	<= (others => '0');
					end if;
					if (avs_s0_write_n = '0' and avs_s0_chipselect_n = '0') then
						case avs_s0_address is
							when x"0" =>
								AddressReg(7 downto 0) <= avs_s0_writedata;
							when x"1" =>
								AddressReg(15 downto 8) <= avs_s0_writedata;
							when x"2" =>
								AddressReg(23 downto 16) <= avs_s0_writedata;
							when x"3" =>
								AddressReg(31 downto 24) <= avs_s0_writedata;
							when x"4" =>
								DataInReg(7 downto 0) <= avs_s0_writedata;
							when x"5" =>
								DataInReg(15 downto 8) <= avs_s0_writedata;
							when x"6" =>
								DataInReg(23 downto 16) <= avs_s0_writedata;
							when x"7" =>
								DataInReg(31 downto 24) <= avs_s0_writedata;
							when x"8" =>
								OperatReg <= avs_s0_writedata;
							when others =>
								null;
						end case;
					else
						if (avm_m0_readdatavalid = '1') then
							DataInReg <= RotateBit(avm_m0_readdata);
						else
							DataInReg <= DataInReg;
						end if;
						if (RegErase = '1') then
							OperatReg <= x"00";
						else
							OperatReg <= OperatReg;
						end if;
					end if;
				end if;
			end if;
		end process AvalonS_Proc;
		
	Uncompress_Proc : process(csi_c0_reset_n, csi_c0_clk)
		begin	
			if (csi_c0_reset_n = '0')then
				avm_m0_read_n <= '1';
				avm_m0_write_n <= '1';
				avm_m0_address <= (others => '0');
				avm_m0_writedata <= (others => '0');
				-- DataOutReg <= (others => '0');
				RegErase <= '0';
				State <= T1;
			else
				if rising_edge (csi_c0_clk)then
					avm_m0_address <= AddressReg;
					case State is
						when T1 =>
							RegErase <= '0';
							if (OperatReg = x"01") then--write normal
								avm_m0_writedata <= DataInReg;
								avm_m0_read_n <= '1';
								avm_m0_write_n <= '0';
								-- DataOutReg <= DataOutReg;
								RegErase <= '1';
								State <= T2;
							elsif (OperatReg = x"02") then--write config data
								avm_m0_writedata <= RotateBit(DataInReg);
								avm_m0_read_n <= '1';
								avm_m0_write_n <= '0';
								-- DataOutReg <= DataOutReg;
								RegErase <= '1';
								State <= T2;
							elsif (OperatReg = x"03") then--read
								avm_m0_read_n <= '0';
								avm_m0_write_n <= '1';
								-- DataOutReg <= (others => '0');
								RegErase <= '1';
								State <= T3;
							else
								avm_m0_read_n <= '1';
								avm_m0_write_n <= '1';
								RegErase <= '0';
								-- DataOutReg <= DataOutReg;
								State <= T1;
							end if;
						when T2 =>
							avm_m0_read_n <= '1';
							RegErase <= '0';
							-- DataOutReg <= DataOutReg;
							if (avm_m0_waitrequest = '0') then
								avm_m0_write_n <= '1';
								State <= T1;
							else
								avm_m0_write_n <= '0';
								State <= T2;
							end if;
						when others =>
							RegErase <= '0';
							if (avm_m0_waitrequest = '0') then
								avm_m0_read_n <= '1';
							end if;
							if (avm_m0_readdatavalid = '1') then
								-- DataOutReg <= avm_m0_readdata;
								State <= T1;
							else
								-- DataOutReg <= (others => '0');
								State <= T3;
							end if;
					end case;
				end if;
			end if;
		end process Uncompress_Proc;

END Arc_CpldFWUpDate;