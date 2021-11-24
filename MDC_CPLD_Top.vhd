library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity MDC_CPLD_Top is
	port(
		 CPLD_nReset		: in std_logic;
		 FPGA_CLK0			: in std_logic;--25MHz
		 FPGA_CLK1			: in std_logic;
		 DebugClk			: out std_logic;--12.5MHz
		 ALTLED0			: out std_logic;
		 ALTLED1			: out std_logic;
		 -- Test				: out std_logic_vector(7 downto 0);
--*********************** Global signals *****************************************
		 I2C1_SCL			: in std_logic;--MCU I2C
		 I2C1_SDA			: inout std_logic;
--*********************** Global signals *****************************************
		 PHY_0P8V_EN_0		: buffer std_logic;
		 PHY_0P8V_EN_1		: buffer std_logic;
		 PHY_0P8V_EN_2		: buffer std_logic;
		 PHY_1P5V_EN		: buffer std_logic;
		 PHY_2P0V_EN		: buffer std_logic;
		 PHY_2P5V_EN		: buffer std_logic;
--*********************** Global signals *****************************************
		 -- PHY0_MDC			: in std_logic;
		 -- PHY0_MDIO			: in std_logic;
		 PHY0_MDC			: buffer std_logic;
		 PHY0_MDIO			: inout std_logic;
		 PHY0_NINT			: in std_logic;
		 PHY0_NRST			: buffer std_logic;
		 PHY0_RX_LOS		: in std_logic;
		 PHY0_SCL			: inout std_logic;--optic I2C
		 PHY0_SDA			: inout std_logic;
		 PHY0_TX_DISABLE	: out std_logic;
		 PHY0_TX_FAULT		: in std_logic;
--*********************** Global signals *****************************************
		 -- PHY1_MDC			: in std_logic;
		 -- PHY1_MDIO			: in std_logic;
		 PHY1_MDC			: buffer std_logic;
		 PHY1_MDIO			: inout std_logic;
		 PHY1_NINT			: in std_logic;
		 PHY1_NRST			: buffer std_logic;
		 PHY1_RX_LOS		: in std_logic;
		 PHY1_SCL			: inout std_logic;--optic I2C
		 PHY1_SDA			: inout std_logic;
		 PHY1_TX_DISABLE	: out std_logic;
		 PHY1_TX_FAULT		: in std_logic;
--*********************** Global signals *****************************************
		 -- PHY2_MDC			: in std_logic;
		 -- PHY2_MDIO			: in std_logic;
		 PHY2_MDC			: buffer std_logic;
		 PHY2_MDIO			: inout std_logic;
		 PHY2_NINT			: in std_logic;
		 PHY2_NRST			: buffer std_logic;
		 PHY2_RX_LOS		: in std_logic;
		 PHY2_SCL			: inout std_logic;--optic I2C
		 PHY2_SDA			: inout std_logic;
		 PHY2_TX_DISABLE	: out std_logic;
		 PHY2_TX_FAULT		: in std_logic;
--*********************** Global signals *****************************************
		 SPI1_MISO			: out std_logic;
		 SPI1_MOSI			: in std_logic;
		 SPI1_NSS			: in std_logic;
		 SPI1_SCK			: in std_logic--;
--*********************** Global signals *****************************************
		 -- PROG_E				: in std_logic
--*********************** Global signals *****************************************
		);
end MDC_CPLD_Top;

ARCHITECTURE Arc_MDC_CPLD_Top OF MDC_CPLD_Top IS
	
    component MDC_CPLD_QSys is
        port(
             clk_clk           : in    std_logic                     := 'X';             -- clk
             input_export      : in    std_logic_vector(31 downto 0) := (others => 'X'); -- export
             output_export     : out   std_logic_vector(31 downto 0);                    -- export
             phy0_i2c_SDA      : inout std_logic                     := 'X';             -- SDA
             phy0_i2c_SCL      : out   std_logic;                                        -- SCL
             phy1_i2c_SDA      : inout std_logic                     := 'X';             -- SDA
             phy1_i2c_SCL      : out   std_logic;                                        -- SCL
             phy2_i2c_SDA      : inout std_logic                     := 'X';             -- SDA
             phy2_i2c_SCL      : out   std_logic;                                        -- SCL
             pll_lock_export   : out   std_logic;                                        -- export
             reset_reset_n     : in    std_logic                     := 'X';             -- reset_n
             spi_miso_export   : out   std_logic;                                        -- export
             spi_mosi_export   : in    std_logic                     := 'X';             -- export
             spi_ncs_export    : in    std_logic                     := 'X';             -- export
             spi_sclk_export   : in    std_logic                     := 'X';             -- export
             sysclock_clk      : out   std_logic;                                        -- clk
             winner_scl_export : in    std_logic                     := 'X';             -- export
             winner_sda_export : inout std_logic                     := 'X';             -- export
             mdc0_export       : out   std_logic;                                        -- export
             mdio0_export      : inout std_logic                     := 'X';             -- export
             mdc1_export       : out   std_logic;                                        -- export
             mdio1_export      : inout std_logic                     := 'X';             -- export
             mdc2_export       : out   std_logic;                                        -- export
             mdio2_export      : inout std_logic                     := 'X';             -- export
			 debug_clk_clk	   : out std_logic;
			 enablestartmdio_export : in    std_logic                     := 'X'              -- export
			);
    end component MDC_CPLD_QSys;
	
	component CPLDLedCTRL
		port(
			 nReset    		: in std_logic;
			 Clk       		: in std_logic;
	--*********************** Global signals *****************************************
			 CPLDLed		: buffer std_logic_vector(1 downto 0)
			);
	end component;
	
	signal	IOCtrl		: std_logic_vector(31 downto 0);
	signal	InputIO		: std_logic_vector(31 downto 0);
	signal	Leds		: std_logic_vector(1 downto 0);
	
	signal	PHYxPowerEN	: std_logic;

	signal	Puls100uSec	: std_logic;
	signal	TimeCounter	: std_logic_vector(15 downto 0);
	signal	TVPResetCo	: std_logic_vector(15 downto 0);
	
	signal	ResetFlags	: std_logic_vector(7 downto 0);
	
	signal	ResetMDIO	: std_logic;
	
	signal	SysClock	: std_logic;
	signal	SysnRST		: std_logic;
	
BEGIN

	ALTLED0 		<= Leds(0);
	ALTLED1 		<= Leds(1);
	
	PHY_1P5V_EN 	<= ResetFlags(0) and IOCtrl(0);
	PHY_2P0V_EN 	<= ResetFlags(0) and IOCtrl(0);
	PHY_2P5V_EN 	<= ResetFlags(0) and IOCtrl(0);
	PHY_0P8V_EN_0 	<= ResetFlags(1) and IOCtrl(1);
	PHY_0P8V_EN_1 	<= ResetFlags(2) and IOCtrl(2);
	PHY_0P8V_EN_2 	<= ResetFlags(3) and IOCtrl(3);
	PHY0_NRST		<= ResetFlags(4) and IOCtrl(4);
	PHY1_NRST		<= ResetFlags(4) and IOCtrl(5);
	PHY2_NRST		<= ResetFlags(4) and IOCtrl(6);
	PHY0_TX_DISABLE <= ResetFlags(5) or IOCtrl(8);
	PHY1_TX_DISABLE <= ResetFlags(5) or IOCtrl(9);
	PHY2_TX_DISABLE <= ResetFlags(5) or IOCtrl(10);
	
	ResetMDIO		<= ResetFlags(6) and IOCtrl(31);
				
	InputIO(8 downto 0) <= PHY2_TX_FAULT&PHY2_RX_LOS&PHY2_NINT&PHY1_TX_FAULT&PHY1_RX_LOS&PHY1_NINT&PHY0_TX_FAULT&PHY0_RX_LOS&PHY0_NINT;
	InputIO(31 downto 9) <= (others => '0');
		 
    U0 : component MDC_CPLD_QSys
        port map(
				 clk_clk         	=> FPGA_CLK0,         --      clk.clk
				 output_export   	=> IOCtrl,   --   ioctrl.export
				 reset_reset_n   	=> CPLD_nReset,   --    reset.reset_n
				 spi_miso_export 	=> SPI1_MISO, -- spi_miso.export
				 spi_mosi_export 	=> SPI1_MOSI, -- spi_mosi.export
				 spi_ncs_export  	=> SPI1_NSS,  --  spi_ncs.export
				 spi_sclk_export 	=> SPI1_SCK,  -- spi_sclk.export
				 input_export	 	=> InputIO,
				 phy0_i2c_SDA    	=> PHY0_SDA,    -- phy0_i2c.SDA
				 phy0_i2c_SCL    	=> PHY0_SCL,    --         .SCL
				 phy1_i2c_SDA    	=> PHY1_SDA,    -- phy1_i2c.SDA
				 phy1_i2c_SCL    	=> PHY1_SCL,    --         .SCL
				 phy2_i2c_SDA    	=> PHY2_SDA,    -- phy2_i2c.SDA
				 phy2_i2c_SCL    	=> PHY2_SCL,    --         .SCL
				 winner_sda_export 	=> I2C1_SDA,
				 winner_scl_export 	=> I2C1_SCL,
				 pll_lock_export   	=> SysnRST,
				 sysclock_clk      	=> SysClock,
				 debug_clk_clk		=> DebugClk,
				 mdc0_export       	=> PHY0_MDC,       --       mdc0.export
				 mdio0_export      	=> PHY0_MDIO,      --      mdio0.export
				 mdc1_export       	=> PHY1_MDC,       --       mdc1.export
				 mdio1_export      	=> PHY1_MDIO,      --      mdio1.export
				 mdc2_export       	=> PHY2_MDC,       --       mdc2.export
				 mdio2_export      	=> PHY2_MDIO,       --      mdio2.export
				 enablestartmdio_export => ResetMDIO--IOCtrl(31)
				);
				
	U1 : CPLDLedCTRL
		port map(
				 nReset    		 => SysnRST,
				 Clk       		 => SysClock,
				 CPLDLed		 => Leds
				);
		
	Clock100uSec_Proc : process(SysnRST, SysClock)
		begin
			if (SysnRST = '0')then
				TimeCounter <= x"0000";
				Puls100uSec <= '1';
			else
				if rising_edge (SysClock)then
					if (TimeCounter = x"09C4") then
						TimeCounter <= x"0000";
						Puls100uSec <= '1';
					else
						TimeCounter <= TimeCounter + 1;
						Puls100uSec <= '0';
					end if;
				end if;
			end if;
		end process Clock100uSec_Proc;

	Reset_Proc : process(SysnRST, SysClock)
		begin	
			if (SysnRST = '0')then
				ResetFlags <= x"20";
				TVPResetCo <= x"0000";
			else
				if rising_edge (SysClock)then
					if (Puls100uSec = '1') then
						if (TVPResetCo(7 downto 0) >= x"F0") then
							case TVPResetCo(15 downto 8) is
								when x"00" =>--switch on common phy power
									ResetFlags <= x"21";
									TVPResetCo(7 downto 0) <= x"00";
									TVPResetCo(15 downto 8) <= TVPResetCo(15 downto 8) + 1;
								when x"01" =>--switch on phy 0 core
									ResetFlags <= x"23";
									TVPResetCo(7 downto 0) <= x"00";
									TVPResetCo(15 downto 8) <= TVPResetCo(15 downto 8) + 1;
								when x"02" =>--switch on phy 1 core
									ResetFlags <= x"27";
									TVPResetCo(7 downto 0) <= x"00";
									TVPResetCo(15 downto 8) <= TVPResetCo(15 downto 8) + 1;
								when x"03" =>--switch on phy 2 core
									ResetFlags <= x"3F";
									TVPResetCo(7 downto 0) <= x"00";
									TVPResetCo(15 downto 8) <= TVPResetCo(15 downto 8) + 1;
								when x"04" =>--switch on optic trancievers
									ResetFlags <= x"1F";
									TVPResetCo(7 downto 0) <= x"00";
									TVPResetCo(15 downto 8) <= TVPResetCo(15 downto 8) + 1;
								when x"80" =>--start MDIO write
									ResetFlags <= x"5F";
									TVPResetCo(7 downto 0) <= x"00";
									TVPResetCo(15 downto 8) <= TVPResetCo(15 downto 8) + 1;
								when others =>--hold state and wait for power reset
									if (IOCtrl(15) = '1') then
										ResetFlags <= x"20";
										TVPResetCo <= x"0000";
									else
										ResetFlags <= ResetFlags;
										TVPResetCo(7 downto 0) <= x"00";
										if (TVPResetCo(15 downto 8) = x"FF") then
											TVPResetCo(15 downto 8) <= x"FF";
										else
											TVPResetCo(15 downto 8) <= TVPResetCo(15 downto 8) + 1;
										end if;
									end if;
									-- ResetFlags <= ResetFlags;
									-- TVPResetCo(7 downto 0) <= x"00";
									-- if (TVPResetCo(15 downto 8) = x"FF") then
										-- TVPResetCo(15 downto 8) <= x"FF";
									-- else
										-- TVPResetCo(15 downto 8) <= TVPResetCo(15 downto 8) + 1;
									-- end if;
							end case;
						else
							TVPResetCo(7 downto 0) <= TVPResetCo(7 downto 0) + 1;
							TVPResetCo(15 downto 8) <= TVPResetCo(15 downto 8);
							ResetFlags <= ResetFlags;
						end if;
					end if;
				end if;
			end if;
		end process Reset_Proc;
		
	-- Reset_Proc : process(IOCtrl(0), SysClock)--setenv bootcmd run Platform Authenticate rdboot
		-- begin	
			-- if (IOCtrl(0) = '0')then
				-- PHY_0P8V_EN_0 	<= '0';--IOCtrl(1);
				-- PHY_0P8V_EN_1 	<= '0';--IOCtrl(2);
				-- PHY_0P8V_EN_2 	<= '0';--IOCtrl(3);
				-- PHY_1P5V_EN 	<= '0';--IOCtrl(0);
				-- PHY_2P0V_EN 	<= '0';--IOCtrl(0);
				-- PHY_2P5V_EN 	<= '0';--IOCtrl(0);
				-- PHY0_NRST		<= '0';--IOCtrl(4);
				-- PHY1_NRST		<= '0';--IOCtrl(5);
				-- PHY2_NRST		<= '0';--IOCtrl(6);
				-- PHY0_TX_DISABLE <= '1';
				-- PHY1_TX_DISABLE <= '1';
				-- PHY2_TX_DISABLE <= '1';
				-- TVPResetCo 		<= x"00";
			-- else
				-- if rising_edge (SysClock)then
					-- if (Puls100uSec = '1') then
						-- if (TVPResetCo = x"F0") then
							-- TVPResetCo 		<= x"F0";
							-- PHY0_TX_DISABLE <= IOCtrl(8);
							-- PHY1_TX_DISABLE <= IOCtrl(9);
							-- PHY2_TX_DISABLE <= IOCtrl(10);
							-- PHY0_NRST		<= IOCtrl(4);
							-- PHY1_NRST		<= IOCtrl(5);
							-- PHY2_NRST		<= IOCtrl(6);
							-- PHY_0P8V_EN_0 	<= IOCtrl(1);
							-- PHY_0P8V_EN_1 	<= IOCtrl(2);
							-- PHY_0P8V_EN_2 	<= IOCtrl(3);
							-- PHY_1P5V_EN 	<= IOCtrl(0);
							-- PHY_2P0V_EN 	<= IOCtrl(0);
							-- PHY_2P5V_EN 	<= IOCtrl(0);
						-- elsif (TVPResetCo >= x"30" and TVPResetCo < x"80") then
							-- TVPResetCo <= TVPResetCo + 1;
							-- PHY0_TX_DISABLE <= '1';
							-- PHY1_TX_DISABLE <= '1';
							-- PHY2_TX_DISABLE <= '1';
							-- PHY0_NRST 		<= '0';
							-- PHY1_NRST 		<= '0';
							-- PHY2_NRST 		<= '0';
							-- PHY_0P8V_EN_0 	<= IOCtrl(1);
							-- PHY_0P8V_EN_1 	<= IOCtrl(2);
							-- PHY_0P8V_EN_2 	<= IOCtrl(3);
							-- PHY_1P5V_EN 	<= IOCtrl(0);
							-- PHY_2P0V_EN 	<= IOCtrl(0);
							-- PHY_2P5V_EN 	<= IOCtrl(0);
						-- else
							-- TVPResetCo <= TVPResetCo + 1;
							-- PHY0_TX_DISABLE <= '1';
							-- PHY1_TX_DISABLE <= '1';
							-- PHY2_TX_DISABLE <= '1';
							-- PHY0_NRST <= '0';
							-- PHY1_NRST <= '0';
							-- PHY2_NRST <= '0';
							-- PHY_0P8V_EN_0 	<= PHY_0P8V_EN_0;
							-- PHY_0P8V_EN_1 	<= PHY_0P8V_EN_1;
							-- PHY_0P8V_EN_2 	<= PHY_0P8V_EN_2;
							-- PHY_1P5V_EN 	<= PHY_1P5V_EN;
							-- PHY_2P0V_EN 	<= PHY_2P0V_EN;
							-- PHY_2P5V_EN 	<= PHY_2P5V_EN;
						-- end if;
					-- end if;
				-- end if;
			-- end if;
		-- end process Reset_Proc;

END Arc_MDC_CPLD_Top;

    -- component MDC_CPLD_QSys is
        -- port (
            -- clk_clk                : in    std_logic                     := 'X';             -- clk
            -- debug_clk_clk          : out   std_logic;                                        -- clk
            -- input_export           : in    std_logic_vector(31 downto 0) := (others => 'X'); -- export
            -- mdc0_export            : out   std_logic;                                        -- export
            -- mdc1_export            : out   std_logic;                                        -- export
            -- mdc2_export            : out   std_logic;                                        -- export
            -- mdio0_export           : inout std_logic                     := 'X';             -- export
            -- mdio1_export           : inout std_logic                     := 'X';             -- export
            -- mdio2_export           : inout std_logic                     := 'X';             -- export
            -- output_export          : out   std_logic_vector(31 downto 0);                    -- export
            -- phy0_i2c_SDA           : inout std_logic                     := 'X';             -- SDA
            -- phy0_i2c_SCL           : out   std_logic;                                        -- SCL
            -- phy1_i2c_SDA           : inout std_logic                     := 'X';             -- SDA
            -- phy1_i2c_SCL           : out   std_logic;                                        -- SCL
            -- phy2_i2c_SDA           : inout std_logic                     := 'X';             -- SDA
            -- phy2_i2c_SCL           : out   std_logic;                                        -- SCL
            -- pll_lock_export        : out   std_logic;                                        -- export
            -- reset_reset_n          : in    std_logic                     := 'X';             -- reset_n
            -- spi_miso_export        : out   std_logic;                                        -- export
            -- spi_mosi_export        : in    std_logic                     := 'X';             -- export
            -- spi_ncs_export         : in    std_logic                     := 'X';             -- export
            -- spi_sclk_export        : in    std_logic                     := 'X';             -- export
            -- sysclock_clk           : out   std_logic;                                        -- clk
            -- winner_scl_export      : in    std_logic                     := 'X';             -- export
            -- winner_sda_export      : inout std_logic                     := 'X';             -- export
            -- enablestartmdio_export : in    std_logic                     := 'X'              -- export
        -- );
    -- end component MDC_CPLD_QSys;

    -- u0 : component MDC_CPLD_QSys
        -- port map (
            -- clk_clk                => CONNECTED_TO_clk_clk,                --             clk.clk
            -- debug_clk_clk          => CONNECTED_TO_debug_clk_clk,          --       debug_clk.clk
            -- input_export           => CONNECTED_TO_input_export,           --           input.export
            -- mdc0_export            => CONNECTED_TO_mdc0_export,            --            mdc0.export
            -- mdc1_export            => CONNECTED_TO_mdc1_export,            --            mdc1.export
            -- mdc2_export            => CONNECTED_TO_mdc2_export,            --            mdc2.export
            -- mdio0_export           => CONNECTED_TO_mdio0_export,           --           mdio0.export
            -- mdio1_export           => CONNECTED_TO_mdio1_export,           --           mdio1.export
            -- mdio2_export           => CONNECTED_TO_mdio2_export,           --           mdio2.export
            -- output_export          => CONNECTED_TO_output_export,          --          output.export
            -- phy0_i2c_SDA           => CONNECTED_TO_phy0_i2c_SDA,           --        phy0_i2c.SDA
            -- phy0_i2c_SCL           => CONNECTED_TO_phy0_i2c_SCL,           --                .SCL
            -- phy1_i2c_SDA           => CONNECTED_TO_phy1_i2c_SDA,           --        phy1_i2c.SDA
            -- phy1_i2c_SCL           => CONNECTED_TO_phy1_i2c_SCL,           --                .SCL
            -- phy2_i2c_SDA           => CONNECTED_TO_phy2_i2c_SDA,           --        phy2_i2c.SDA
            -- phy2_i2c_SCL           => CONNECTED_TO_phy2_i2c_SCL,           --                .SCL
            -- pll_lock_export        => CONNECTED_TO_pll_lock_export,        --        pll_lock.export
            -- reset_reset_n          => CONNECTED_TO_reset_reset_n,          --           reset.reset_n
            -- spi_miso_export        => CONNECTED_TO_spi_miso_export,        --        spi_miso.export
            -- spi_mosi_export        => CONNECTED_TO_spi_mosi_export,        --        spi_mosi.export
            -- spi_ncs_export         => CONNECTED_TO_spi_ncs_export,         --         spi_ncs.export
            -- spi_sclk_export        => CONNECTED_TO_spi_sclk_export,        --        spi_sclk.export
            -- sysclock_clk           => CONNECTED_TO_sysclock_clk,           --        sysclock.clk
            -- winner_scl_export      => CONNECTED_TO_winner_scl_export,      --      winner_scl.export
            -- winner_sda_export      => CONNECTED_TO_winner_sda_export,      --      winner_sda.export
            -- enablestartmdio_export => CONNECTED_TO_enablestartmdio_export  -- enablestartmdio.export
        -- );
