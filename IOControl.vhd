library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity IOControl is
	port(
		 csi_c0_reset_n			: in std_logic;--avalon #reset
		 csi_c0_clk				: in std_logic;--avalon clock 25MHz
--*********************** Global signals *****************************************
		 avs_s0_read_n			: in std_logic;
		 avs_s0_write_n			: in std_logic;
		 avs_s0_chipselect_n	: in std_logic;
		 avs_s0_address			: in std_logic;
		 avs_s0_readdata		: out std_logic_vector(31 downto 0);
		 avs_s0_readdatavalid	: out std_logic;
		 avs_s0_writedata		: in std_logic_vector(31 downto 0);
		 avm_s0_waitrequest		: out std_logic;
--************************* Avalon-MM Slave **************************************
		 InputIO				: in std_logic_vector(31 downto 0);
		 IOControl				: out std_logic_vector(31 downto 0)
--************************* export signals ***************************************
		);
end IOControl;

ARCHITECTURE Arc_IOControl OF IOControl IS

	type 		States is(T1, T2, T3);
	signal 		State		: States;
	
	signal		IOCtrlSig	: std_logic_vector(31 downto 0);
	
BEGIN

	avm_s0_waitrequest <= '0';
						
	Avalon_Proc : process(csi_c0_reset_n, csi_c0_clk)
		begin	
			if (csi_c0_reset_n = '0')then
				avs_s0_readdatavalid <= '0';
				avs_s0_readdata	<= (others => '0');
				IOCtrlSig <= x"8000007F";
				-- IOCtrlSig <= x"0000007F";
				IOControl <= (others => '0');
			else
				if rising_edge (csi_c0_clk)then
					IOControl <= IOCtrlSig;
					if (avs_s0_read_n = '0' and avs_s0_chipselect_n = '0') then
						avs_s0_readdatavalid <= '1';
						if (avs_s0_address = '0') then
							avs_s0_readdata	<= IOCtrlSig;
						else
							avs_s0_readdata	<= InputIO;
						end if;
					else
						avs_s0_readdatavalid <= '0';
						avs_s0_readdata	<= (others => '0');
					end if;
					if (avs_s0_write_n = '0' and avs_s0_chipselect_n = '0') then
						if (avs_s0_address = '0') then
							IOCtrlSig <= avs_s0_writedata;
						end if;
					else
						IOCtrlSig <= IOCtrlSig and x"FFFF7FFF";
					end if;
				end if;
			end if;
		end process Avalon_Proc;

END Arc_IOControl;