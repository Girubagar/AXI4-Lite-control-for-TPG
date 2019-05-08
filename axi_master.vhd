--------AXI LITE CTRL with User Inputs------
--This file can be used to implement Reg Write over AXI Lite Ctrl IF of AXI IPs
--User can provide an input and trigger AXI transaction
--Takes in Address, DATA and Transaction init signal as inputs and gives out AXI Lite Transaction
--The module can be used for both power up config and user triggers
--The address and data for power up config can be added to this file
--The run time data has to be passed from outside

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library unisim;
use unisim.vcomponents.all;

entity axi_master is
port
    (   --Clk and Reset
        clk                 : in  STD_LOGIC;  --27MHz
		aresetn             : in  STD_LOGIC;  --Active low Reset
		--User controls
		addr                : in   STD_LOGIC_VECTOR(7 downto 0);            --actual address need not be 32
		data                : in   STD_LOGIC_VECTOR(31 downto 0);            --actual data need not be 32
		trigger             : in   STD_LOGIC;
        --AXI LITE CTRL IF for AXI IP AXI_L IF
        m_axi_aclk          : out  STD_LOGIC;
        m_axi_aresetn       : out  STD_LOGIC;

        m_axi_awaddr        : out  STD_LOGIC_VECTOR ( 7 downto 0 );
        m_axi_awvalid       : out  STD_LOGIC;
        m_axi_awready       : in   STD_LOGIC;

        m_axi_wdata         : out  STD_LOGIC_VECTOR ( 31 downto 0 );
        m_axi_wvalid        : out  STD_LOGIC;
        m_axi_wready        : in   STD_LOGIC;

        m_axi_bresp         : in   STD_LOGIC_VECTOR ( 1 downto 0 );
        m_axi_bvalid        : in   STD_LOGIC;
        m_axi_bready        : out  STD_LOGIC;

        m_axi_araddr        : out  STD_LOGIC_VECTOR ( 7 downto 0 );
        m_axi_arvalid       : out  STD_LOGIC;
        m_axi_arready       : in   STD_LOGIC;

        m_axi_rdata         : in   STD_LOGIC_VECTOR ( 31 downto 0 );
        m_axi_rresp         : in   STD_LOGIC_VECTOR ( 1 downto 0 );
        m_axi_rvalid        : in   STD_LOGIC;
        m_axi_rready        : out  STD_LOGIC
    );
end axi_master;

architecture Behavioral of axi_master is


--For BD designs base address will be as per address map, for non BD designs, it is 0x00000000
constant addr_control                     : std_logic_vector(7 downto 0):= x"00"; 
--constant addr_global_interrupt_enable     : std_logic_vector(7 downto 0):= x"04";
--constant addr_ip_interupt_enable          : std_logic_vector(7 downto 0):= x"08";
--constant addr_ip_interrupt_status         : std_logic_vector(7 downto 0):= x"0C";
constant addr_active_height               : std_logic_vector(7 downto 0):= x"10"; 
constant addr_active_width                : std_logic_vector(7 downto 0):= x"18"; 
constant addr_background_pattern_id       : std_logic_vector(7 downto 0):= x"20";
constant addr_foreground_pattern_id       : std_logic_vector(7 downto 0):= x"28";
constant addr_mask_id                     : std_logic_vector(7 downto 0):= x"30";
constant addr_motion_speed                : std_logic_vector(7 downto 0):= x"38";
constant addr_color_format                : std_logic_vector(7 downto 0):= x"40";
constant addr_cross_hair_hor              : std_logic_vector(7 downto 0):= x"48";
constant addr_cross_hair_ver              : std_logic_vector(7 downto 0):= x"50";
constant addr_zplate_hor_cntl_start       : std_logic_vector(7 downto 0):= x"58";
constant addr_zplate_hor_cntl_delta       : std_logic_vector(7 downto 0):= x"60";
constant addr_zplate_ver_cntl_start       : std_logic_vector(7 downto 0):= x"68";
constant addr_zplate_ver_cntl_delta       : std_logic_vector(7 downto 0):= x"70";
constant addr_box_size                    : std_logic_vector(7 downto 0):= x"78";
constant addr_box_color_red_y             : std_logic_vector(7 downto 0):= x"80";
constant addr_box_color_green_u           : std_logic_vector(7 downto 0):= x"88";
constant addr_box_color_blue_v            : std_logic_vector(7 downto 0):= x"90";
constant addr_enable_input                : std_logic_vector(7 downto 0):= x"98";
constant addr_pass_thru_start_x           : std_logic_vector(7 downto 0):= x"a0";
constant addr_pass_thru_start_y           : std_logic_vector(7 downto 0):= x"a8";
constant addr_pass_thru_end_x             : std_logic_vector(7 downto 0):= x"b0";
constant addr_pass_thru_end_y             : std_logic_vector(7 downto 0):= x"b8";
constant addr_dpDynamicRange              : std_logic_vector(7 downto 0):= x"c0";
constant addr_dpYUVCoef                   : std_logic_vector(7 downto 0):= x"c8";


constant data_control                     : std_logic_vector(31 downto 0):= x"00000081";--necessary..bit0 - apstart..when 1 starts the the tpg core.
--constant data_global_interrupt_enable     : std_logic_vector(31 downto 0):= x"00000000";
--constant data_ip_interupt_enable          : std_logic_vector(31 downto 0):= x"00000000";
--constant data_ip_interrupt_status         : std_logic_vector(31 downto 0):= x"00000000";
constant data_active_height               : std_logic_vector(31 downto 0):= x"00000190"; --N0.of.rows in GUI..Maximum safe limit-2160
constant data_active_width                : std_logic_vector(31 downto 0):= x"00000280"; --No.of.columns in GUI..Maximum safe limit-4096
constant data_background_pattern_id       : std_logic_vector(31 downto 0):= x"00000009";
constant data_foreground_pattern_id       : std_logic_vector(31 downto 0):= x"00000001";
constant data_mask_id                     : std_logic_vector(31 downto 0):= x"00000000";
constant data_motion_speed                : std_logic_vector(31 downto 0):= x"00000000";
constant data_color_format                : std_logic_vector(31 downto 0):= x"00000000";
constant data_cross_hair_hor              : std_logic_vector(31 downto 0):= x"00000000";
constant data_cross_hair_ver              : std_logic_vector(31 downto 0):= x"00000000";
constant data_zplate_hor_cntl_start       : std_logic_vector(31 downto 0):= x"00000000";
constant data_zplate_hor_cntl_delta       : std_logic_vector(31 downto 0):= x"00000000";
constant data_zplate_ver_cntl_start       : std_logic_vector(31 downto 0):= x"00000000";
constant data_zplate_ver_cntl_delta       : std_logic_vector(31 downto 0):= x"00000000";
constant data_box_size                    : std_logic_vector(31 downto 0):= x"00000000";
constant data_box_color_red_y             : std_logic_vector(31 downto 0):= x"00000000";
constant data_box_color_green_u           : std_logic_vector(31 downto 0):= x"00000000";
constant data_box_color_blue_v            : std_logic_vector(31 downto 0):= x"00000000";
constant data_enable_input                : std_logic_vector(31 downto 0):= x"00000000";
constant data_pass_thru_start_x           : std_logic_vector(31 downto 0):= x"00000000";
constant data_pass_thru_start_y           : std_logic_vector(31 downto 0):= x"00000000";
constant data_pass_thru_end_x             : std_logic_vector(31 downto 0):= x"00000000";
constant data_pass_thru_end_y             : std_logic_vector(31 downto 0):= x"00000000";
constant data_dpDynamicRange              : std_logic_vector(31 downto 0):= x"00000000";
constant data_dpYUVCoef                   : std_logic_vector(31 downto 0):= x"00000000";



type awaddr_type is array (0 to 3) of STD_LOGIC_VECTOR(7 downto 0);
type awdata_type is array (0 to 3) of STD_LOGIC_VECTOR(31 downto 0);

signal awaddr : awaddr_type;
signal awdata : awdata_type;

type awstate is (idle, wr_addr_data, wait_addr_data, puc_done_check, user_wait);
signal state : awstate;

signal m_axi_CTRL_AWADDR  : STD_LOGIC_VECTOR ( 7 downto 0 );
signal m_axi_CTRL_AWVALID : STD_LOGIC;
signal m_axi_CTRL_AWREADY : STD_LOGIC;
signal m_axi_CTRL_WDATA   : STD_LOGIC_VECTOR ( 31 downto 0 );
signal m_axi_CTRL_WVALID  : STD_LOGIC;
signal m_axi_CTRL_WREADY  : STD_LOGIC;

signal wr_count        : integer range 0 to 4;

signal user_addr_reg   : STD_LOGIC_VECTOR(7 downto 0);
signal user_data_reg   : STD_LOGIC_VECTOR(31 downto 0);

signal puc_done        : STD_LOGIC;


begin

awaddr <= ( addr_active_height, addr_active_width, addr_background_pattern_id, addr_control );
awdata <= ( data_active_height, data_active_width, data_background_pattern_id, data_control );

process(clk,aresetn)
begin
   if(aresetn = '0') then
      m_axi_CTRL_AWADDR  <= (others => '0');
	  m_axi_CTRL_AWVALID <= '0';
	  m_axi_CTRL_WDATA   <= (others => '0');
	  m_axi_CTRL_WVALID  <= '0';
	  wr_count           <= 0;
	  state              <= idle;
	  puc_done           <= '0';
   elsif(rising_edge(clk)) then
       case state is
	      when idle =>
		       m_axi_CTRL_AWADDR  <= (others => '0');
	           m_axi_CTRL_AWVALID <= '0';
	           m_axi_CTRL_WDATA   <= (others => '0');
	           m_axi_CTRL_WVALID  <= '0';
	           wr_count           <= 0;
			   puc_done           <= '0';
	           state              <= wr_addr_data;

		  when wr_addr_data =>
		       if(wr_count < 4) then                         --This IP expects write address and data to be asserted together
				  m_axi_CTRL_AWADDR  <= awaddr(wr_count);
				  m_axi_CTRL_AWVALID <= '1';
				  m_axi_CTRL_WDATA   <= awdata(wr_count);
                  m_axi_CTRL_WVALID  <= '1';
				  state              <= wait_addr_data;
			   else
				  m_axi_CTRL_AWADDR  <= user_addr_reg;
				  m_axi_CTRL_AWVALID <= '1';
				  m_axi_CTRL_WDATA   <= user_data_reg;
                  m_axi_CTRL_WVALID  <= '1';
				  state              <= wait_addr_data;
			   end if;

		  when wait_addr_data =>
		       if(m_axi_CTRL_WREADY = '1') then
		          m_axi_CTRL_AWVALID <= '0';
			      m_axi_CTRL_WVALID  <= '0';
			      state              <= puc_done_check;
			      if(wr_count < 4) then
                     wr_count           <= wr_count + 1;
                  else
                    wr_count            <= wr_count;
                  end if;
			   else
			      m_axi_CTRL_AWVALID <= '1';
			      m_axi_CTRL_WVALID  <= '1';
			      state              <= wait_addr_data;
			      wr_count           <= wr_count;
			   end if;

		  when puc_done_check =>
		       if(wr_count < 4) then
		          state    <= wr_addr_data;
				  puc_done <= '0';
			   else
			      state    <= user_wait;
				  puc_done <= '1';
			   end if;

		  when user_wait =>
		       if(trigger = '1') then
			      user_addr_reg <= addr;
				  user_data_reg <= data;
				  state         <= wr_addr_data;
			   else
			      user_addr_reg <= user_addr_reg;
				  user_data_reg <= user_data_reg;
				  state         <= user_wait;
			   end if;

	   end case;
   end if;
end process;

--CPU/CTRL IF
  m_axi_aclk         <=  clk;
  m_axi_aresetn      <=  aresetn;

  m_axi_awaddr       <=  m_axi_CTRL_AWADDR;
  m_axi_awvalid      <=  m_axi_CTRL_AWVALID;
  m_axi_CTRL_AWREADY <=  m_axi_awready;

  m_axi_wdata        <=  m_axi_CTRL_WDATA;
  m_axi_wvalid       <=  m_axi_CTRL_WVALID;
  m_axi_CTRL_WREADY  <=  m_axi_wready;


  m_axi_bready       <=  '1';

  m_axi_araddr       <=  (others => '0');
  m_axi_arvalid      <=  '0';


  m_axi_rready       <=  '0';

end Behavioral;