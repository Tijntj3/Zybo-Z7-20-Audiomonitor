library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity miniproject_top is
    generic (
        DEBUG                               :       boolean                         := FALSE
    );
    port (
        SYSCLK                              : in    std_logic;

        AC_BCLK                             : out   std_logic;
        AC_MCLK                             : out   std_logic;
        AC_MUTEN                            : out   std_logic;
        AC_PBDAT                            : out   std_logic;
        AC_PBLRC                            : out   std_logic;
        AC_RECDAT                           : in    std_logic;
        AC_RECLRC                           : out   std_logic;
        AC_SCL                              : inout std_logic;
        AC_SDA                              : inout std_logic;

        VAUX_V_P                            : in    std_logic_vector ( 3 downto 0 );
        VAUX_V_N                            : in    std_logic_vector ( 3 downto 0 );

        DDR_addr                            : inout std_logic_vector ( 14 downto 0 );
        DDR_ba                              : inout std_logic_vector ( 2 downto 0 );
        DDR_cas_n                           : inout std_logic;
        DDR_ck_n                            : inout std_logic;
        DDR_ck_p                            : inout std_logic;
        DDR_cke                             : inout std_logic;
        DDR_cs_n                            : inout std_logic;
        DDR_dm                              : inout std_logic_vector ( 3 downto 0 );
        DDR_dq                              : inout std_logic_vector ( 31 downto 0 );
        DDR_dqs_n                           : inout std_logic_vector ( 3 downto 0 );
        DDR_dqs_p                           : inout std_logic_vector ( 3 downto 0 );
        DDR_odt                             : inout std_logic;
        DDR_ras_n                           : inout std_logic;
        DDR_reset_n                         : inout std_logic;
        DDR_we_n                            : inout std_logic;

        FIXED_IO_ddr_vrn                    : inout std_logic;
        FIXED_IO_ddr_vrp                    : inout std_logic;
        FIXED_IO_mio                        : inout std_logic_vector ( 53 downto 0 );
        FIXED_IO_ps_clk                     : inout std_logic;
        FIXED_IO_ps_porb                    : inout std_logic;
        FIXED_IO_ps_srstb                   : inout std_logic
    );
end miniproject_top;

architecture behavioural of miniproject_top is

    signal miniproject_control              : std_logic_vector ( 6 downto 0 )       := (others => '0');
    signal distort_control                  : std_logic_vector ( 3 downto 0 )       := (others => '0');
    signal octaver_control                  : std_logic_vector ( 3 downto 0 )       := (others => '0');
    signal tremolo_control                  : std_logic_vector ( 3 downto 0 )       := (others => '0');
    signal delay_control                    : std_logic_vector ( 3 downto 0 )       := (others => '0');

    signal aud_clk_counter                  : unsigned ( 17 downto 0 )               := (others => '0');
    signal aud_clk_12M                      : std_logic;
    signal aud_clk_3M                       : std_logic;
    signal aud_clk_48K                      : std_logic;
    signal aud_clk_375                      : std_logic;
    signal aud_clk_188                      : std_logic;
    signal aud_clk_94                       : std_logic;
    signal aud_clk_47                       : std_logic;

    signal aud_pcm_a                        : std_logic_vector ( 31 downto 0 );
    signal aud_pcm_b                        : std_logic_vector ( 31 downto 0 );
    signal aud_pcm_stream                   : std_logic_vector ( 31 downto 0 );
    signal aud_pcm_valid                    : std_logic;
    signal aud_pcm_enable                   : std_logic;

    signal aclk                             : std_logic;
    signal stream_data                      : std_logic_vector ( 31 downto 0 );
    signal stream_valid                     : std_logic;
    signal stream_last                      : std_logic;
    signal stream_ready                     : std_logic;

    signal distort_out_L                    : std_logic_vector ( 31 downto 0 );
    signal distort_out_R                    : std_logic_vector ( 31 downto 0 );

    signal octaver_out_L                    : std_logic_vector ( 31 downto 0 );
    signal octaver_out_R                    : std_logic_vector ( 31 downto 0 );

    signal tremolo_out_L                    : std_logic_vector ( 31 downto 0 );
    signal tremolo_out_R                    : std_logic_vector ( 31 downto 0 );
    
    signal delay_out_L                      : std_logic_vector ( 31 downto 0 );
    signal delay_out_R                      : std_logic_vector ( 31 downto 0 );

    component PS_wrapper is
        port (
            ACLK                            : out   std_logic;
            AXI_STR_RXD_0_tdata             : in    std_logic_vector ( 31 downto 0 );
            AXI_STR_RXD_0_tlast             : in    std_logic;
            AXI_STR_RXD_0_tready            : out   std_logic;
            AXI_STR_RXD_0_tvalid            : in    std_logic;
            DDR_addr                        : inout std_logic_vector ( 14 downto 0 );
            DDR_ba                          : inout std_logic_vector ( 2 downto 0 );
            DDR_cas_n                       : inout std_logic;
            DDR_ck_n                        : inout std_logic;
            DDR_ck_p                        : inout std_logic;
            DDR_cke                         : inout std_logic;
            DDR_cs_n                        : inout std_logic;
            DDR_dm                          : inout std_logic_vector ( 3 downto 0 );
            DDR_dq                          : inout std_logic_vector ( 31 downto 0 );
            DDR_dqs_n                       : inout std_logic_vector ( 3 downto 0 );
            DDR_dqs_p                       : inout std_logic_vector ( 3 downto 0 );
            DDR_odt                         : inout std_logic;
            DDR_ras_n                       : inout std_logic;
            DDR_reset_n                     : inout std_logic;
            DDR_we_n                        : inout std_logic;
            FIXED_IO_ddr_vrn                : inout std_logic;
            FIXED_IO_ddr_vrp                : inout std_logic;
            FIXED_IO_mio                    : inout std_logic_vector ( 53 downto 0 );
            FIXED_IO_ps_clk                 : inout std_logic;
            FIXED_IO_ps_porb                : inout std_logic;
            FIXED_IO_ps_srstb               : inout std_logic;
            GPIO_0_tri_o                    : out   std_logic_vector ( 6 downto 0 );
            GPIO_1_tri_o                    : out   std_logic_vector ( 3 downto 0 );
            GPIO_2_tri_o                    : out   std_logic_vector ( 3 downto 0 );
            GPIO_3_tri_o                    : out   std_logic_vector ( 3 downto 0 );
            GPIO_4_tri_o                    : out   std_logic_vector ( 3 downto 0 );
            IIC_0_0_scl_io                  : inout std_logic;
            IIC_0_0_sda_io                  : inout std_logic;
            Vaux14_0_v_n                    : in    std_logic;
            Vaux14_0_v_p                    : in    std_logic;
            Vaux15_0_v_n                    : in    std_logic;
            Vaux15_0_v_p                    : in    std_logic;
            Vaux6_0_v_n                     : in    std_logic;
            Vaux6_0_v_p                     : in    std_logic;
            Vaux7_0_v_n                     : in    std_logic;
            Vaux7_0_v_p                     : in    std_logic
        );
    end component;

    component AUD_CLK_PLL
        port (
            clk_in                          : in     std_logic;
            clk_out1                        : out    std_logic
        );
    end component;

    component ssm2603_serdes is
        generic (
            DEBUG                           :       boolean                         := FALSE
        );
        port (
            AUD_BCLK                        : in    std_logic;
            AUD_WCLK                        : in    std_logic;
            AUD_SER_DIN                     : in    std_logic;
            AUD_SER_DOUT                    : out   std_logic;
    
            AUD_PAR_OUT_A                   : out   std_logic_vector ( 31 downto 0 );
            AUD_PAR_OUT_B                   : out   std_logic_vector ( 31 downto 0 );
            AUD_PAR_IN_A                    : in    std_logic_vector ( 31 downto 0 );
            AUD_PAR_IN_B                    : in    std_logic_vector ( 31 downto 0 );

            AUD_VALID                       : out   std_logic
        );
    end component;

    --Zybo Z7-20 Only
    --component Distortion_0
    --    port (
    --        x                               : in    std_logic_vector(31 downto 0);
    --        y                               : out   std_logic_vector(31 downto 0);
    --        clk_48                          : in    std_logic;
    --        options                         : in    std_logic_vector(0 to 3);
    --        en                              : in    std_logic_vector(0 to 3)
    --    );
    --end component;

    --component octaver_0
    --    port (
    --        x                               : in    std_logic_vector(31 downto 0);
    --        y                               : out   std_logic_vector(31 downto 0);
    --        clk_48                          : in    std_logic;
    --        options                         : in    std_logic_vector(0 to 3);
    --        en                              : in    std_logic_vector(0 to 3)
    --    );
    --end component;

    --component trem_0
    --    port (
    --        x                               : in std_logic_vector(31 downto 0);
    --        y                               : out std_logic_vector(31 downto 0);
    --        clk_48                          : in std_logic;
    --        clk_190                         : in std_logic;
    --        clk_380                         : in std_logic;
    --        clk_95                          : in std_logic;
    --        clk_48hz                        : in std_logic;
    --        options                         : in std_logic_vector(0 to 3);
    --        en                              : in std_logic_vector(0 to 3)
    --    );
    --end component;

    --component delay_0
    --    port (
    --        x                               : in    std_logic_vector(31 downto 0);
    --        y                               : out   std_logic_vector(31 downto 0);
    --        clk_48                          : in    std_logic;
    --        options                         : in    std_logic_vector(0 to 3);
    --        en                              : in    std_logic_vector(0 to 3)
    --    );
    --end component;

    component stream_fifo_controller is
        generic (
            DEBUG                           :       boolean                         := FALSE
        );
        port (
            ACLK                            : in    std_logic;
            AUD_ENABLE                      : in    std_logic;
            AUD_PCM_IN                      : in    std_logic_vector ( 31 downto 0 );
            AUD_VALID                       : in    std_logic;
    
            WREADY                          : in    std_logic;
            WDATA                           : out   std_logic_vector ( 31 downto 0 );
            WVALID                          : out   std_logic;
            WLAST                           : out   std_logic
        );
    end component;

    component ila_top
        port (
	        clk                             : in std_logic;

	        probe0                          : in std_logic_vector(6 downto 0); 
	        probe1                          : in std_logic_vector(3 downto 0); 
	        probe2                          : in std_logic_vector(3 downto 0); 
	        probe3                          : in std_logic_vector(3 downto 0); 
	        probe4                          : in std_logic_vector(3 downto 0); 
	        probe5                          : in std_logic_vector(31 downto 0); 
	        probe6                          : in std_logic_vector(31 downto 0); 
	        probe7                          : in std_logic_vector(31 downto 0); 
	        probe8                          : in std_logic_vector(31 downto 0);
	        probe9                          : in std_logic_vector(31 downto 0)
        );
    end component;  

begin

    debugging : if DEBUG = TRUE generate
        ila_top_inst : ila_top
            port map (
	            clk                             => aud_clk_3M,

	            probe0                          => miniproject_control, 
	            probe1                          => distort_control,
	            probe2                          => octaver_control,
	            probe3                          => tremolo_control,
	            probe4                          => delay_control,
                probe5                          => aud_pcm_a,
                probe6                          => distort_out_L,
                probe7                          => octaver_out_L,
                probe8                          => tremolo_out_L,
                probe9                          => delay_out_L
            );
    end generate;

    aud_clk_3M <= aud_clk_counter(1);
    aud_clk_48K <= aud_clk_counter(7);
    aud_clk_375 <= aud_clk_counter(14);
    aud_clk_188 <= aud_clk_counter(15);
    aud_clk_94 <= aud_clk_counter(16);
    aud_clk_47 <= aud_clk_counter(17);

    AC_MCLK <= aud_clk_12M;
    AC_BCLK <= aud_clk_3M;
    AC_PBLRC <= aud_clk_48K;
    AC_RECLRC <= aud_clk_48K;

    AC_MUTEN <= miniproject_control(0);

    PS_wrapper_inst : PS_wrapper
        port map(
            ACLK                            => aclk,
            AXI_STR_RXD_0_tdata             => stream_data,
            AXI_STR_RXD_0_tlast             => stream_last,
            AXI_STR_RXD_0_tready            => stream_ready,
            AXI_STR_RXD_0_tvalid            => stream_valid,
            DDR_addr                        => DDR_addr,
            DDR_ba                          => DDR_ba,
            DDR_cas_n                       => DDR_cas_n,
            DDR_ck_n                        => DDR_ck_n,
            DDR_ck_p                        => DDR_ck_p,
            DDR_cke                         => DDR_cke,
            DDR_cs_n                        => DDR_cs_n,
            DDR_dm                          => DDR_dm,
            DDR_dq                          => DDR_dq,
            DDR_dqs_n                       => DDR_dqs_n,
            DDR_dqs_p                       => DDR_dqs_p,
            DDR_odt                         => DDR_odt,
            DDR_ras_n                       => DDR_ras_n,
            DDR_reset_n                     => DDR_reset_n,
            DDR_we_n                        => DDR_we_n,
            FIXED_IO_mio                    => FIXED_IO_mio,
            FIXED_IO_ddr_vrn                => FIXED_IO_ddr_vrn,
            FIXED_IO_ddr_vrp                => FIXED_IO_ddr_vrp,
            FIXED_IO_ps_srstb               => FIXED_IO_ps_srstb,
            FIXED_IO_ps_clk                 => FIXED_IO_ps_clk,
            FIXED_IO_ps_porb                => FIXED_IO_ps_porb,
            GPIO_0_tri_o                    => miniproject_control,
            GPIO_1_tri_o                    => distort_control,
            GPIO_2_tri_o                    => octaver_control,
            GPIO_3_tri_o                    => tremolo_control,
            GPIO_4_tri_o                    => delay_control,
            IIC_0_0_scl_io                  => AC_SCL,
            IIC_0_0_sda_io                  => AC_SDA,
            Vaux14_0_v_n                    => VAUX_V_N(2),
            Vaux14_0_v_p                    => VAUX_V_P(2),
            Vaux15_0_v_n                    => VAUX_V_N(3),
            Vaux15_0_v_p                    => VAUX_V_P(3),
            Vaux6_0_v_n                     => VAUX_V_N(0),
            Vaux6_0_v_p                     => VAUX_V_P(0),
            Vaux7_0_v_n                     => VAUX_V_N(1),
            Vaux7_0_v_p                     => VAUX_V_P(1)
        );
    
    aud_clk_pll_inst : AUD_CLK_PLL
        port map(
            clk_in                          => SYSCLK,
            clk_out1                        => aud_clk_12M
        );

    aud_ssm2603_serdes_inst : ssm2603_serdes
        generic map (
            DEBUG                           => FALSE
        )
        port map (
            AUD_BCLK                        => aud_clk_3M,
            AUD_WCLK                        => aud_clk_48K,
            AUD_SER_DIN                     => AC_RECDAT,
            AUD_SER_DOUT                    => AC_PBDAT,
    
            AUD_PAR_OUT_A                   => aud_pcm_a,
            AUD_PAR_OUT_B                   => aud_pcm_b,
            AUD_PAR_IN_A                    => delay_out_L,
            AUD_PAR_IN_B                    => delay_out_R,

            AUD_VALID                       => aud_pcm_valid
        );

    --Zybo Z7-20 Only
    --distortion_L_inst : Distortion_0
    --    port map(
    --        x                               => aud_pcm_a,
    --        y                               => distort_out_L,
    --        clk_48                          => aud_clk_48K,
    --        options                         => distort_control,
    --        en                              => miniproject_control(5 downto 2)
    --    );

    --distortion_R_inst : Distortion_0
    --    port map(
    --        x                               => aud_pcm_b,
    --        y                               => distort_out_R,
    --        clk_48                          => aud_clk_48K,
    --        options                         => distort_control,
    --        en                              => miniproject_control(5 downto 2)
    --    );

    --octaver_L_inst : octaver_0
    --    port map(
    --        x                               => distort_out_L,
    --        y                               => octaver_out_L,
    --        clk_48                          => aud_clk_48K,
    --        options                         => octaver_control,
    --        en                              => miniproject_control(5 downto 2)
    --    );

    --octaver_R_inst : octaver_0
    --    port map(
    --        x                               => distort_out_R,
    --        y                               => octaver_out_R,
    --        clk_48                          => aud_clk_48K,
    --        options                         => octaver_control,
    --        en                              => miniproject_control(5 downto 2)
    --    );

    --tremolo_L_inst : trem_0
    --    port map(
    --        x                               => octaver_out_L,
    --        y                               => tremolo_out_L,
    --        clk_48                          => aud_clk_48K,
    --        clk_190                         => aud_clk_188,
    --        clk_380                         => aud_clk_375,
    --        clk_95                          => aud_clk_94,
    --        clk_48hz                        => aud_clk_47,
    --        options                         => tremolo_control,
    --        en                              => miniproject_control(5 downto 2)
    --    );

    --tremolo_R_inst : trem_0
    --    port map(
    --        x                               => octaver_out_R,
    --        y                               => tremolo_out_R,
    --        clk_48                          => aud_clk_48K,
    --        clk_190                         => aud_clk_188,
    --        clk_380                         => aud_clk_375,
    --        clk_95                          => aud_clk_94,
    --        clk_48hz                        => aud_clk_47,
    --        options                         => tremolo_control,
    --        en                              => miniproject_control(5 downto 2)
    --    );

    --delay_L_inst : delay_0
    --    port map(
    --        x                               => tremolo_out_L,
    --        y                               => delay_out_L,
    --        clk_48                          => aud_clk_48K,
    --        options                         => delay_control,
    --        en                              => miniproject_control(5 downto 2)
    --    );

    --delay_R_inst : delay_0
    --    port map(
    --        x                               => tremolo_out_R,
    --        y                               => delay_out_R,
    --        clk_48                          => aud_clk_48K,
    --        options                         => delay_control,
    --        en                              => miniproject_control(5 downto 2)
    --    );

    --aud_pcm_mux_inst : process (miniproject_control(1 downto 0))
    --    begin
    --        if (miniproject_control(0) = '0') then
    --            aud_pcm_stream <= (others => '0');
    --        else
    --            if (miniproject_control(1) = '0') then
    --                aud_pcm_stream(31 downto 24) <= (others => delay_out_L(23));
    --                aud_pcm_stream(23 downto 0) <= delay_out_L(23 downto 0);
    --            else
    --                aud_pcm_stream(31 downto 24) <= (others => delay_out_R(23));
    --                aud_pcm_stream(23 downto 0) <= delay_out_R(23 downto 0);
    --            end if;
    --        end if;
    --    end process;

    aud_pcm_mux_inst : process (miniproject_control(1 downto 0))
        begin
            if (miniproject_control(0) = '0') then
                aud_pcm_stream <= (others => '0');
            else
                if (miniproject_control(1) = '0') then
                    aud_pcm_stream(31 downto 24) <= (others => aud_pcm_a(23));
                    aud_pcm_stream(23 downto 0) <= aud_pcm_a(23 downto 0);
                else
                    aud_pcm_stream(31 downto 24) <= (others => aud_pcm_b(23));
                    aud_pcm_stream(23 downto 0) <= aud_pcm_b(23 downto 0);
                end if;
            end if;
        end process;

    stream_fifo_controller_inst : stream_fifo_controller
        generic map (
            DEBUG                           => FALSE
        )
        port map (
            ACLK                            => aclk,
            AUD_ENABLE                      => miniproject_control(6),
            AUD_PCM_IN                      => aud_pcm_stream,
            AUD_VALID                       => aud_pcm_valid,
            
            WREADY                          => stream_ready,
            WDATA                           => stream_data,
            WVALID                          => stream_valid,
            WLAST                           => stream_last
        );

    aud_clk_div_inst : process (aud_clk_12M)
        begin
            if rising_edge(aud_clk_12M) then
                aud_clk_counter <= aud_clk_counter + 1;
            end if;
        end process;

end architecture;