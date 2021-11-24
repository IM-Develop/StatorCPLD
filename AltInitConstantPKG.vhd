library ieee;
use ieee.std_logic_1164.all;

package AltInitConstantPKG is

	constant MDIO_0_DataReg	: std_logic_vector(31 downto 0) := x"00000060";
	constant MDIO_0_CtrlReg	: std_logic_vector(31 downto 0) := x"00000064";
	constant MDIO_1_DataReg	: std_logic_vector(31 downto 0) := x"00000070";
	constant MDIO_1_CtrlReg	: std_logic_vector(31 downto 0) := x"00000074";
	constant MDIO_2_DataReg	: std_logic_vector(31 downto 0) := x"00000080";
	constant MDIO_2_CtrlReg	: std_logic_vector(31 downto 0) := x"00000084";
	
	constant MatrixSize			: integer := 56;

	subtype DataReg is std_logic_vector(31 downto 0);
	type MDIOMtrx is array (0 to (MatrixSize - 1)) of DataReg;
	
	--MDIO_x_CtrlReg(15 downto 14) : "11" = write, "10" = read
	--MDIO_x_CtrlReg(9 downto 5)   : phy address (88x3310 have only phy "0")
	--MDIO_x_CtrlReg(4 downto 0)   : device address (88x3310 have 1, 3, 4, 7, 31)
	
	constant MDIODataMtrx	: MDIOMtrx :=	(
											 MDIO_0_DataReg, x"C0500000",--check for PHY ready
											 MDIO_0_CtrlReg, x"00008001",--device 1 register 0xC050 (value 0x7E is ready) 
------------------------------------------------------------------------------------------------------------------------
											 MDIO_0_DataReg, x"F00033FF",
											 MDIO_0_CtrlReg, x"0000C01F",--write to phy "0" device "31"
------------------------------------------------------------------------------------------------------------------------
											 MDIO_0_DataReg, x"F001001C",--auto neg 10BASE-R
											 MDIO_0_CtrlReg, x"0000C01F",--write to phy "0" device "31"
------------------------------------------------------------------------------------------------------------------------
											 MDIO_1_DataReg, x"C0500000",--check for PHY ready
											 MDIO_1_CtrlReg, x"00008001",--device 1 register 0xC050 (value 0x7E is ready) 
------------------------------------------------------------------------------------------------------------------------
											 MDIO_1_DataReg, x"F00033FF",
											 MDIO_1_CtrlReg, x"0000C01F",--write to phy "0" device "31"
------------------------------------------------------------------------------------------------------------------------
											 MDIO_1_DataReg, x"F001001C",--auto neg 10BASE-R
											 MDIO_1_CtrlReg, x"0000C01F",--write to phy "0" device "31"
------------------------------------------------------------------------------------------------------------------------
											 MDIO_2_DataReg, x"C0500000",--check for PHY ready
											 MDIO_2_CtrlReg, x"00008001",--device 1 register 0xC050 (value 0x7E is ready) 
											 MDIO_2_DataReg, x"F00033BF",
											 MDIO_2_CtrlReg, x"0000C01F",--write to phy "0" device "31"
											 MDIO_2_DataReg, x"F001000C",--auto neg 1000BASE-R
											 MDIO_2_CtrlReg, x"0000C01F",--write to phy "0" device "31"
											 MDIO_2_DataReg, x"F001800C",--software reset
											 MDIO_2_CtrlReg, x"0000C01F",--write to phy "0" device "31"
------------------------------------------------------------------------------------------------------------------------
											 MDIO_0_DataReg, x"C0000069",--swap pairs ABCD to DCBA
											 MDIO_0_CtrlReg, x"0000C001",--write to phy "0" device "1"
------------------------------------------------------------------------------------------------------------------------
											 MDIO_0_DataReg, x"0000B000",--software reset
											 MDIO_0_CtrlReg, x"0000C007",
------------------------------------------------------------------------------------------------------------------------
											 MDIO_1_DataReg, x"C0000069",--swap pairs ABCD to DCBA
											 MDIO_1_CtrlReg, x"0000C001",--write to phy "0" device "1"
------------------------------------------------------------------------------------------------------------------------
											 MDIO_1_DataReg, x"0000B000",--software reset
											 MDIO_1_CtrlReg, x"0000C007"
											);
												
end AltInitConstantPKG;
