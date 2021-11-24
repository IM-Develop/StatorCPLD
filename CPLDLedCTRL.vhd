library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity CPLDLedCTRL is
	port(
		 nReset    		: in std_logic;
		 Clk	       	: in std_logic;--22.11842MHz
--*********************** Global signals *****************************************
		 CPLDLed		: buffer std_logic_vector(1 downto 0)
		);
end CPLDLedCTRL;

ARCHITECTURE Arc_CPLDLedCTRL OF CPLDLedCTRL IS

	signal	Puls1HzCounter		: std_logic_vector(23 downto 0);
	
BEGIN

	PWM_Proc : process(nReset, Clk)
		begin	
			if (nReset = '0')then
				Puls1HzCounter <= (others => '0');
				CPLDLed <= "10";
			else
				if rising_edge (Clk)then
					if (Puls1HzCounter = x"A8C000") then
						CPLDLed <= not(CPLDLed);
						Puls1HzCounter <= (others => '0');
					else
						CPLDLed <= CPLDLed;
						Puls1HzCounter <= Puls1HzCounter + 1;
					end if;
				end if;
			end if;
		end process PWM_Proc;

END Arc_CPLDLedCTRL;