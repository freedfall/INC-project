-- uart_rx.vhd: UART controller - receiving (RX) side
-- Author(s): Timur Kininbayev (xkinin00)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


-- Entity declaration (DO NOT ALTER THIS PART!)
entity UART_RX is
    port(
        CLK      : in std_logic;
        RST      : in std_logic;
        DIN      : in std_logic;
        DOUT     : out std_logic_vector(7 downto 0);
        DOUT_VLD : out std_logic
    );
end entity;

-- Architecture implementation (INSERT YOUR IMPLEMENTATION HERE)
architecture behavioral of UART_RX is
    -- Declaration of internal signals
    signal CLK_CNT    : std_logic_vector(4 downto 0);
    signal BIT_CNT    : std_logic_vector(3 downto 0);
    signal CNT_START  : std_logic;
    signal RX_START   : std_logic;
    signal DATA_VALID : std_logic;
begin

    -- Instance of RX FSM
    fsm: entity work.UART_RX_FSM
    port map (
        CLK        => CLK,
        RST        => RST,
        DIN        => DIN,
        CLK_CNT    => CLK_CNT,
        BIT_CNT    => BIT_CNT,
        CNT_START  => CNT_START,
        RX_START   => RX_START,
        DATA_VALID => DATA_VALID
    );

    DOUT_VLD <= DATA_VALID;

    ------ main process ------
    process(CLK)
    begin
        if rising_edge(CLK) then

            ------ reset data and counters ------
            if RST = '1' then
                DOUT <= (others => '0');
                CLK_CNT <= (others => '0');
                BIT_CNT <= (others => '0');
            end if;

            ------ increment clock counter ------
            if CNT_START = '1' then
                CLK_CNT <= CLK_CNT + 1;
            else
                CLK_CNT <= (others => '0');
            end if;

            ------ write data ------
            if RX_START = '1' then
                if CLK_CNT(4) = '1' then
                    DOUT(to_integer(unsigned(BIT_CNT))) <= DIN;

                    -- reset clock counter and increment bit counter
                    CLK_CNT <= "00000";
                    BIT_CNT <= BIT_CNT + 1;
                end if;
            else
                BIT_CNT <= (others => '0');
            end if;
        end if;
    end process;
end architecture;
