-- uart_rx_fsm.vhd: UART controller - finite state machine controlling RX side
-- Author(s): Timur Kininbayev (xkinin00)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- ----------------------------------------------------------------------------
--                        Entity declaration
-- ----------------------------------------------------------------------------
entity UART_RX_FSM is
    port(
       CLK        : in std_logic; -- clock signal
       RST        : in std_logic; -- asynchronous reset
       DIN        : in std_logic; -- input data
       CLK_CNT    : in std_logic_vector(4 downto 0); -- clock counter
       BIT_CNT    : in std_logic_vector(3 downto 0); -- bit counter
       CNT_START  : out std_logic; -- signal for starting clock counter
       RX_START   : out std_logic; -- signal for starting data reading
       DATA_VALID : out std_logic  -- signal for data validation 
    );
end entity;

-- ----------------------------------------------------------------------------
--                      Architecture declaration
-- ----------------------------------------------------------------------------
architecture behavioral of UART_RX_FSM is
    ------ all fsm states ------
    type fsm_state is (
        s_idle, s_start, 
        s_readData, s_stop,
        s_validate
    );
    signal actual_state    : fsm_state;
    signal following_state : fsm_state;
begin

------ logic of fsm ------
    fsm_next: process(CLK, RST)
    begin
        if RST = '1' then
            actual_state <= s_idle;
        elsif rising_edge(CLK) then
            actual_state <= following_state;
        end if;
    end process fsm_next;
    
    fsm_logic: process(actual_state, DIN, CLK_CNT, BIT_CNT)
    begin
        case actual_state is

            ------ default processor state ------
            when s_idle =>
                DATA_VALID <= '0';
                RX_START   <= '0';  -- Ensure RX_START is reset in idle state
                CNT_START  <= '0';  -- Ensure CNT_START is reset in idle state
                if DIN = '0' then
                    following_state <= s_start;
                else
                    following_state <= s_idle;
                end if;

            ------ state after DIN = 0 ------
            when s_start =>
                CNT_START <= '1';
                RX_START <= '0';
                if (to_integer(unsigned(CLK_CNT)) = 22)  then
                    following_state <= s_readData;
                else
                    following_state <= s_start;
                end if;

            ------ state for reading input data (8bit) ------
            when s_readData =>
                RX_START <= '1';
                if BIT_CNT = "1000" then
                    following_state <= s_stop;
                else
                    following_state <= s_readData;
                end if;
            
            ------ state after reading data ------
            when s_stop =>
                RX_START <= '0';
                if DIN = '1' then
                    following_state <= s_validate;
                else
                    following_state <= s_idle;
                end if;

            ------ state for validating data ------
            when s_validate =>
                DATA_VALID <= '1';
                CNT_START <= '0';
                following_state <= s_idle;
            
            ------ default case ------
            when others =>
                following_state <= s_idle;
        end case;
    end process fsm_logic;
end architecture;
