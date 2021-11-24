library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.AltInitConstantPKG.all;

entity AvalonMaster_AltInit is
	port(
		 csi_c0_reset_n			: in std_logic;--avalon #reset
		 csi_c0_clk				: in std_logic;--avalon clock
		 EnableStart			: in std_logic;
--*********************** Global signals *****************************************
		 avm_m0_read_n			: out std_logic;
		 avm_m0_write_n			: out std_logic;
		 avm_m0_address			: buffer std_logic_vector(31 downto 0);
		 avm_m0_readdata		: in std_logic_vector(31 downto 0);
		 avm_m0_readdatavalid	: in std_logic;
		 avm_m0_writedata		: buffer std_logic_vector(31 downto 0);
		 avm_m0_byteenable		: out std_logic_vector(3 downto 0);
		 avm_m0_waitrequest		: in std_logic--;
--************************* Avalon-MM ********************************
		);
end AvalonMaster_AltInit;

ARCHITECTURE Arc_AvalonMaster_AltInit OF AvalonMaster_AltInit IS

	type 	States is(T1, T2, T3);--, T4, T5, T6);
	signal 	State			: States;
	
	signal	Enable			: std_logic;
	signal	WaitCounter		: std_logic_vector(31 downto 0);
	signal	ProgCounter		: integer range 0 to 255;
		 
BEGIN

	AVLMaster_Proc : process(csi_c0_reset_n, csi_c0_clk)
--------------------------------------------------------------------------------
	    procedure AvlIdle  is
			begin
				avm_m0_write_n <= '1';
				avm_m0_read_n <= '1';
				avm_m0_address <= (others => '0');
				avm_m0_writedata <= (others => '0');
	    end AvlIdle;
--------------------------------------------------------------------------------
	    procedure AvlWrite (Add : std_logic_vector(31 downto 0); Data : std_logic_vector(31 downto 0)) is
			begin
				avm_m0_read_n <= '1';
				avm_m0_write_n <= '0';
				avm_m0_address <= Add;
				avm_m0_writedata <= Data;
	    end AvlWrite;
--------------------------------------------------------------------------------
	    procedure AvlRead (Add : std_logic_vector(31 downto 0)) is
			begin
				avm_m0_read_n <= '0';
				avm_m0_write_n <= '1';
				avm_m0_address <= Add;
				avm_m0_writedata <= (others => '0');
	    end AvlRead;
--------------------------------------------------------------------------------
		begin	
			if (csi_c0_reset_n = '0' or EnableStart = '0')then
				AvlIdle;
				avm_m0_byteenable <= (others => '0');
				WaitCounter <= (others => '0');
				Enable <= '0';
				ProgCounter <= 0;
				State <= T1;
			else
				if rising_edge (csi_c0_clk)then
					avm_m0_byteenable <= x"F";--32bit
					case State is
						when T1 =>
							Enable <= Enable;-- and EnableStart;
							if (WaitCounter = x"00000800") then
								if (Enable = '0') then
									AvlWrite(MDIODataMtrx(ProgCounter), MDIODataMtrx(ProgCounter + 1));
									ProgCounter <= ProgCounter;
									WaitCounter <= (others => '0');
									State <= T2;
								else
									AvlIdle;
									ProgCounter <= 0;
									WaitCounter <= x"00000800";
									State <= T1;
								end if;
							else
								AvlIdle;
								ProgCounter <= ProgCounter;
								WaitCounter <= WaitCounter + 1;
								State <= T1;
							end if;
						when T2 =>
							Enable <= Enable;
							ProgCounter <= ProgCounter;
							if (WaitCounter = x"00000800" and avm_m0_waitrequest = '0') then
								if (MDIODataMtrx(ProgCounter) = MDIO_0_DataReg or MDIODataMtrx(ProgCounter) = MDIO_0_CtrlReg) then
									AvlRead(MDIO_0_DataReg);
								elsif (MDIODataMtrx(ProgCounter) = MDIO_1_DataReg or MDIODataMtrx(ProgCounter) = MDIO_1_CtrlReg) then
									AvlRead(MDIO_1_DataReg);
								else
									AvlRead(MDIO_2_DataReg);
								end if;
								WaitCounter <= (others => '0');
								State <= T3;
							else
								AvlIdle;
								WaitCounter <= WaitCounter + 1;
								State <= T2;
							end if;
						when others =>
							Enable <= Enable;
							WaitCounter <= (others => '0');
							if (avm_m0_readdatavalid = '1') then
								AvlIdle;
								if (avm_m0_readdata(31) = '0') then--MDIO Control is ready
									if (MDIODataMtrx(ProgCounter + 1) = x"00008001") then
										if (avm_m0_readdata(7 downto 0) = x"7E") then--phy is ready
											ProgCounter <= ProgCounter + 2;
										else
											ProgCounter <= ProgCounter - 2;--back to start
										end if;
									elsif (ProgCounter = (MatrixSize - 2)) then
										ProgCounter <= 0;
										Enable <= '1';
									else
										ProgCounter <= ProgCounter + 2;
									end if;
									State <= T1;
								else
									ProgCounter <= ProgCounter;
									State <= T2;
								end if;
							else
								ProgCounter <= ProgCounter;
								State <= T3;
							end if;
					end case;
				end if;
			end if;
		end process AVLMaster_Proc;
		
END Arc_AvalonMaster_AltInit;