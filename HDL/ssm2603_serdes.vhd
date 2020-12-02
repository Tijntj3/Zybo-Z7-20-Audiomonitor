library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ssm2603_serdes is
    generic (
        DEBUG                               :       boolean                         := FALSE
    );
    port (
        AUD_BCLK                            : in    std_logic;
        AUD_WCLK                            : in    std_logic;
        AUD_SER_DIN                         : in    std_logic;
        AUD_SER_DOUT                        : out   std_logic;

        AUD_PAR_OUT_A                       : out   std_logic_vector ( 31 downto 0 );
        AUD_PAR_OUT_B                       : out   std_logic_vector ( 31 downto 0 );
        AUD_PAR_IN_A                        : in    std_logic_vector ( 31 downto 0 );
        AUD_PAR_IN_B                        : in    std_logic_vector ( 31 downto 0 );

        AUD_VALID                           : out   std_logic
    );
end entity;

architecture behavioural of ssm2603_serdes is

    signal wclk_reg                         : std_logic;
    signal wclk_edge                        : std_logic;
    signal wclk_falling                     : std_logic;

    signal aud_bclk_counter                 : unsigned( 4 downto 0 )                := (others => '0');
    signal aud_shift_reg                    : std_logic_vector ( 23 downto 0 );

    signal aud_par_out_a_s                  : std_logic_vector ( 23 downto 0 );
    signal aud_par_out_b_s                  : std_logic_vector ( 23 downto 0 );

    signal aud_par_in_a_s                   : std_logic_vector ( 23 downto 0 );
    signal aud_par_in_b_s                   : std_logic_vector ( 23 downto 0 );

    function flipBits (pcm_in : in std_logic_vector( 23 downto 0 )) return std_logic_vector is
        variable tmp                        : std_logic_vector ( 23 downto 0 );
        begin
            for k in 0 to 23 loop
                tmp(k) := pcm_in(23 - k);
            end loop;
            return tmp;
        end function;

    component ila_ssm2603   
        port (
            clk                             : in    std_logic;
            
	        probe0                          : in    std_logic_vector( 0 downto 0 ); 
	        probe1                          : in    std_logic_vector( 0 downto 0 ); 
	        probe2                          : in    std_logic_vector( 0 downto 0 ); 
	        probe3                          : in    std_logic_vector( 4 downto 0 ); 
	        probe4                          : in    std_logic_vector( 31 downto 0 ); 
	        probe5                          : in    std_logic_vector( 31 downto 0 ); 
	        probe6                          : in    std_logic_vector( 31 downto 0 ); 
	        probe7                          : in    std_logic_vector( 31 downto 0 );
	        probe8                          : in    std_logic_vector( 31 downto 0 )
        );
    end component  ;

begin

    debugging : if DEBUG = TRUE generate
        debug_ila : ila_ssm2603
            port map (
                clk                         => AUD_BCLK,
            
	            probe0                      => (others => AUD_WCLK),
	            probe1                      => (others => AUD_SER_DIN),
	            probe2                      => (others => wclk_edge),
	            probe3                      => std_logic_vector(aud_bclk_counter),
	            probe4                      => aud_shift_reg,
	            probe5                      => aud_par_out_a_s, 
	            probe6                      => aud_par_out_b_s,
	            probe7                      => aud_par_in_a_s,
	            probe8                      => aud_par_in_b_s
            );
    end generate;

    aud_wclk_delay : process(AUD_BCLK)
        begin
            if rising_edge(AUD_BCLK) then
                wclk_reg <= AUD_WCLK;
            end if;
        end process;
    
    aud_wclk_edge_detect : process (AUD_WCLK, wclk_reg)
        begin
            wclk_edge <= AUD_WCLK xor wclk_reg;
            wclk_falling <= (not (AUD_WCLK)) and wclk_reg;
        end process;

    aud_sequencer : process (AUD_BCLK)
        begin
            if rising_edge(AUD_BCLK) then
                if wclk_edge = '1' then
                    aud_bclk_counter <= (others => '0');
                else
                    aud_bclk_counter <= aud_bclk_counter + 1;
                end if;

                if aud_bclk_counter = 24 then
                    if AUD_WCLK = '0' then
                        aud_par_out_a_s <= aud_shift_reg;
                    else
                        aud_par_out_b_s <= aud_shift_reg;
                    end if;
                end if;

                if wclk_falling = '1' then
                    AUD_VALID <= '1';
                    AUD_PAR_OUT_A(31 downto 24) <= (others => aud_par_out_a_s(23));
                    AUD_PAR_OUT_B(31 downto 24) <= (others => aud_par_out_b_s(23));
                    AUD_PAR_OUT_A(23 downto 0) <= aud_par_out_a_s;
                    AUD_PAR_OUT_B(23 downto 0) <= aud_par_out_b_s;
                    aud_par_in_a_s <= flipBits(AUD_PAR_IN_A(23 downto 0));
                    aud_par_in_b_s <= flipBits(AUD_PAR_IN_B(23 downto 0));
                else
                    AUD_VALID <= '0';
                end if;

                aud_shift_reg <= aud_shift_reg(22 downto 0) & AUD_SER_DIN;
            end if;
        end process;

    aud_out_mux : process (AUD_WCLK, aud_bclk_counter)
        begin
            if AUD_WCLK = '1' then
                AUD_SER_DOUT <= aud_par_in_b_s(to_integer(aud_bclk_counter));
            else
                AUD_SER_DOUT <= aud_par_in_a_s(to_integer(aud_bclk_counter));
            end if;
        end process;

end architecture;