library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity SPI2AvalonBridge is
	port(
		 sci_c0_reset_n			: in std_logic;--avalon #reset
		 sci_c0_clk				: in std_logic;--avalon clock
--*********************** Global signals *****************************************
		 SPI_nCS				: in std_logic;
		 SPI_SCLK				: in std_logic;--POL=1, PHA=1 (clock start from high to low, latch on rising edge)
		 SPI_MOSI				: in std_logic;--MSb first
		 SPI_MISO				: buffer std_logic;--MSb first
--*********************** DM6467T signals ****************************************
		 avm_m0_read_n			: out std_logic;
		 avm_m0_write_n			: buffer std_logic;
		 avm_m0_address			: buffer std_logic_vector(31 downto 0);
		 avm_m0_readdata		: in std_logic_vector(31 downto 0);
		 avm_m0_readdatavalid	: in std_logic;
		 avm_m0_writedata		: buffer std_logic_vector(31 downto 0);
		 avm_m0_byteenable		: buffer std_logic_vector(3 downto 0);
		 avm_m0_waitrequest		: in std_logic
--************************* Avalon-MM ********************************
--************************* Export Signals ***************************
		 -- Test0					: out std_logic--
		 -- Test0					: out std_logic_vector(7 downto 0)--;--SPICommnad
		 -- Test1					: out std_logic_vector(7 downto 0);--SPIBitCount
		 -- Test2					: out std_logic_vector(31 downto 0);--EMIFLatch
		 -- Test3					: out std_logic_vector(31 downto 0);--ReadData
		 -- Test4					: out std_logic_vector(1 downto 0)--SCLK R/F
		);
end SPI2AvalonBridge;

ARCHITECTURE Arc_SPI2AvalonBridge OF SPI2AvalonBridge IS

	-- 0x00 = nop
	-- 0x80 = Set Address
	-- 0x81 = Write 8bit data
	-- 0x82 = Read 8bit Data
	-- 0x83 = Write 16bit data
	-- 0x84 = Read 16bit Data
	-- 0x85 = Write 32bit data
	-- 0x86 = Read 32bit Data
	-- 0x88 = increment address and do read (LS3b)
	-- 0x89 = increment address and do write (LS3b)

	type 	States is(T1, T2, T3, T4);
	signal 	State			: States;
	
	signal	SPICommnad		: std_logic_vector(7 downto 0);
	signal	LatchCommnad	: std_logic_vector(7 downto 0);
	signal	SPIBitCount		: std_logic_vector(7 downto 0);
	
	signal	EMIFLatch		: std_logic_vector(3 downto 0);
	
	signal	ReadData		: std_logic_vector(31 downto 0);
	
	signal	SclkDetect		: std_logic;
	signal	SclkRising		: std_logic;
	signal	SclkFalling		: std_logic;
	
	signal	EndOfWrite		: std_logic;
	
	signal	SigSPI_nCS		: std_logic;
	signal	SigSPI_SCLK		: std_logic;
	signal	SigSPI_MOSI		: std_logic;
	
BEGIN

	-- Test0(4 downto 0) <= avm_m0_readdata(4 downto 0);
	-- Test0(5) <= avm_m0_write_n;
	-- Test0(6) <= avm_m0_waitrequest;
	-- Test0(7) <= avm_m0_readdatavalid;

	SPIClk_Proc : process(sci_c0_reset_n, sci_c0_clk)
		begin
			if (sci_c0_reset_n='0')then
				SclkDetect <= '1';
				SclkRising <= '0';
				SclkFalling <= '0';
				SigSPI_nCS  <= '1';
				SigSPI_SCLK <= '1';
				SigSPI_MOSI <= '1';
				-- LatchCommnad <= x"00";
			else
				if rising_edge (sci_c0_clk)then
					-- Test0 <= SPICommnad;
					-- Test1 <= SPIBitCount;
					-- Test2 <= avm_m0_address;
					-- Test3 <= ReadData;
					-- Test4 <= avm_m0_waitrequest&EndOfWrite;
					-- LatchCommnad <= SPICommnad
					SigSPI_nCS  <= SPI_nCS;
					SigSPI_SCLK <= SPI_SCLK;
					SigSPI_MOSI <= SPI_MOSI;
					SclkDetect <= SigSPI_SCLK;
					if (SclkDetect = '0' and SigSPI_SCLK = '1') then
						SclkRising <= '1';
					else
						SclkRising <= '0';
					end if;
					if (SclkDetect = '1' and SigSPI_SCLK = '0') then
						SclkFalling <= '1';
					else
						SclkFalling <= '0';
					end if;
				end if;
			end if;
		end process SPIClk_Proc;

	SPI_Proc : process(sci_c0_reset_n, sci_c0_clk)
		begin	
			if (sci_c0_reset_n='0')then
				SPI_MISO <= '1';
				SPICommnad <= x"00";
				SPIBitCount <= x"00";
				avm_m0_address <= (others => '0');
				avm_m0_writedata <= (others => '0');
				ReadData <= (others => '0');
				-- ReadData <= x"AAAAAAAA";
				EMIFLatch <= x"F";
			else
				if rising_edge (sci_c0_clk)then
					if (avm_m0_readdatavalid = '1') then-- and SPICommnad(0) = '0') then
						ReadData <= avm_m0_readdata;
						-- ReadData <= not(ReadData);
						SPI_MISO <= '1';--make sure that data latch is befor falling edge of SCLK
					elsif (SclkFalling = '1') then
						if (SPIBitCount >= x"08" and SPICommnad(0) = '0' and SPICommnad(3 downto 0) /= x"0") then--SPI read time
							ReadData <= ReadData(30 downto 0) & '1';
							SPI_MISO <= ReadData(31);
						else
							ReadData <= ReadData;
							SPI_MISO <= '1';
						end if;
					else
						ReadData <= ReadData;
						SPI_MISO <= SPI_MISO;
					end if;
					if (SPIBitCount > x"07" and SPICommnad = x"80" and SclkRising = '1') then--collect AVL address
						avm_m0_address <= avm_m0_address(30 downto 0) & SigSPI_MOSI;
					elsif (SPICommnad(3) = '1' and SPICommnad(0) = '0' and SPIBitCount = x"27" and SclkRising = '1') then--increment address command
						avm_m0_address <= avm_m0_address + 4;
					elsif (SPICommnad(3) = '1' and EndOfWrite = '1') then
						avm_m0_address <= avm_m0_address + 4;
					else
						avm_m0_address <= avm_m0_address;
					end if;
					if (SigSPI_nCS = '0') then
						-- if (SclkFalling = '1') then--every falling edge of SCLK
						-- if (SclkRising = '1') then--every falling edge of SCLK
							-- SPIBitCount <= SPIBitCount + 1;
						-- else
							-- SPIBitCount <= SPIBitCount;
						-- end if;
						if (SclkRising = '1') then
							if (SPIBitCount < x"08") then--collect SPI command
								SPICommnad <= SPICommnad(6 downto 0) & SigSPI_MOSI;
							else
								SPICommnad <= SPICommnad;
							end if;
							if (SPIBitCount > x"07" and SPICommnad(0) = '1') then--collect AVL write data command
								avm_m0_writedata <= avm_m0_writedata(30 downto 0) & SigSPI_MOSI;
							else
								avm_m0_writedata <= avm_m0_writedata;
							end if;
							if (SPIBitCount = x"27" and SPICommnad(0) = '0') then--read (include set address)
								SPIBitCount <= x"00";
								EMIFLatch <= x"6";--read command to AVL
							elsif (SPIBitCount = x"27" and SPICommnad(0) = '1') then--write
								SPIBitCount <= x"00";
								EMIFLatch <= x"1";--write command to AVL
							else
								SPIBitCount <= SPIBitCount + 1;
								EMIFLatch <= x"F";
							end if;
						end if;
					else
						-- if (SPIBitCount = x"27") then
							SPIBitCount <= x"00";
						-- else
							-- SPIBitCount <= SPIBitCount;
						-- end if;
						SPICommnad <= SPICommnad;
						avm_m0_writedata <= avm_m0_writedata;
						EMIFLatch <= x"F";
					end if;
				end if;
			end if;
		end process SPI_Proc;

	SPI2AVL_Proc : process(sci_c0_reset_n, sci_c0_clk)
		begin	
			if (sci_c0_reset_n='0')then
				avm_m0_read_n <= '1';
				avm_m0_write_n <= '1';
				avm_m0_byteenable <= (others => '0');
				EndOfWrite <= '0';
				State <= T1;
			else
				if rising_edge (sci_c0_clk)then
					case SPICommnad(2 downto 0) is
						when "001" | "010" =>
							avm_m0_byteenable <= x"1";
						when "011" | "100" =>
							avm_m0_byteenable <= x"3";
						-- when "101" | "110" =>
							-- avm_m0_byteenable <= x"F";
						when others =>
							avm_m0_byteenable <= x"F";
					end case;
					case State is
						when T1 =>
							EndOfWrite <= '0';
							if (EMIFLatch(3) = '0' and SigSPI_nCS = '1') then
								if (EMIFLatch(2) = '1' and EMIFLatch(0) = '0') then--read operation
									avm_m0_read_n <= '0';
									avm_m0_write_n <= '1';
									State <= T2;
								elsif (EMIFLatch(2) = '0' and EMIFLatch(1) = '0') then--write operation (read modified write)
									avm_m0_read_n <= '0';
									avm_m0_write_n <= '1';
									State <= T3;
								else
									avm_m0_read_n <= '1';
									avm_m0_write_n <= '1';
									State <= T1;
								end if;
							else
								avm_m0_read_n <= '1';
								avm_m0_write_n <= '1';
								State <= T1;
							end if;
						
						when T2 =>--read 32bit data from the avalone
							avm_m0_write_n <= '1';
							EndOfWrite <= '0';
							if (avm_m0_waitrequest = '0') then
							-- if (avm_m0_readdatavalid = '1') then
								avm_m0_read_n <= '1';
							end if;
							if (EMIFLatch = x"F") then
								State <= T1;
							else
								State <= T2;
							end if;
							
						when T3 =>
							EndOfWrite <= '0';
							-- avm_m0_write_n <= '1';
							if (avm_m0_waitrequest = '0') then
								avm_m0_read_n <= '1';
							end if;
							if (avm_m0_readdatavalid = '1') then
								avm_m0_write_n <= '0';
								State <= T4;
							else
								avm_m0_write_n <= '1';
								State <= T3;
							end if;
						
						when others =>
							avm_m0_read_n <= '1';
							if (avm_m0_waitrequest = '0') then
								avm_m0_write_n <= '1';
							else
								avm_m0_write_n <= '0';
							end if;
							if (EMIFLatch = x"F") then
								EndOfWrite <= '1';
								State <= T1;
							else
								EndOfWrite <= '0';
								State <= T4;
							end if;
							
					end case;
				end if;
			end if;
		end process SPI2AVL_Proc;
		
END Arc_SPI2AvalonBridge;