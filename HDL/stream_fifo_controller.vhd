library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stream_fifo_controller is
    generic (
        DEBUG                               :       boolean                         := FALSE
    );
    port (
        ACLK                                : in    std_logic;
        AUD_ENABLE                          : in    std_logic;
        AUD_PCM_IN                          : in    std_logic_vector ( 31 downto 0 );
        AUD_VALID                           : in    std_logic;

        WREADY                              : in    std_logic;
        WDATA                               : out   std_logic_vector ( 31 downto 0 );
        WVALID                              : out   std_logic;
        WLAST                               : out   std_logic
    );
end entity;

architecture behavioural of stream_fifo_controller is

    signal aud_valid_reg                    : std_logic_vector ( 2 downto 0 );
    signal aud_valid_rising                 : std_logic;
    signal aud_pcm_buf                      : std_logic_vector ( 31 downto 0 );

    signal aud_pcm_counter                  : unsigned ( 8 downto 0 )               := (others => '0');
    signal sequencer                        : unsigned ( 0 downto 0 )               := "0";

    signal wdata_s                          : std_logic_vector ( 31 downto 0 );
    signal wvalid_s                         : std_logic;
    signal wlast_s                          : std_logic;

    component ila_stream_fifo
        port (
            clk : in std_logic;

            probe0 : in std_logic_vector(0 downto 0); 
            probe1 : in std_logic_vector(31 downto 0); 
            probe2 : in std_logic_vector(0 downto 0); 
            probe3 : in std_logic_vector(0 downto 0); 
            probe4 : in std_logic_vector(0 downto 0);
            probe5 : in std_logic_vector(31 downto 0);
            probe6 : in std_logic_vector(8 downto 0)
        );
    end component;

begin

    WDATA <= wdata_s;
    WVALID <= wvalid_s;
    WLAST <= wlast_s;

    debugging : if DEBUG = TRUE generate
        ila_stream_inst : ila_stream_fifo
            port map (
	            clk                             => ACLK,

	            probe0(0)                       => sequencer(0), 
	            probe1                          => aud_pcm_buf,
	            probe2(0)                       => wvalid_s,
	            probe3(0)                       => wlast_s,
	            probe4(0)                       => WREADY,
                probe5                          => wdata_s,
                probe6                          => std_logic_vector(aud_pcm_counter)
            );
    end generate;

    aud_valid_shift_reg : process (ACLK)
        begin
            if rising_edge(ACLK) then
                aud_valid_reg <= aud_valid_reg(1 downto 0) & AUD_VALID;
            end if;
        end process;
    
    aud_valid_edge_detect : process (aud_valid_reg)
        begin
            aud_valid_rising <= (not aud_valid_reg(2)) and aud_valid_reg(1);
        end process;

    control_inst : process (ACLK)
        begin
            if rising_edge(ACLK) then
                if AUD_ENABLE = '1' then
                    if aud_valid_rising = '1' then
                        sequencer <= "1";
                        aud_pcm_buf <= AUD_PCM_IN;
                    else
                        case to_integer(sequencer) is
                            when 1 =>
                                wdata_s <= aud_pcm_buf;
                                wvalid_s <= '1';
                                if (aud_pcm_counter = "111011111") then
                                    wlast_s <= '1';
                                else
                                    wlast_s <= '0';
                                end if;
                                if WREADY = '1' then
                                    if (aud_pcm_counter = "111011111") then
                                        aud_pcm_counter <= (others => '0');
                                    else
                                        aud_pcm_counter <=  aud_pcm_counter + 1;
                                    end if;
                                    sequencer <= "0";
                                end if;
                            when others =>
                                wdata_s <= (others => '0');
                                wvalid_s <= '0';
                                wlast_s <= '0';
                        end case;
                    end if;
                else
                    aud_pcm_counter <= (others => '0');
                    sequencer <= (others => '0');
                    wdata_s <= (others => '0');
                    wvalid_s <= '0';
                    wlast_s <= '0'; 
                end if;
            end if;
        end process;

end architecture;