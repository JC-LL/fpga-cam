----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:25:52 03/03/2012 
-- Design Name: 
-- Module Name:    sobel3x3 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK ;
USE WORK.image_pack.ALL ;
USE WORK.utils_pack.ALL ;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity gauss3x3_pixel_pipeline is
generic(WIDTH: natural := 640;
		  HEIGHT: natural := 480);
port(
 		resetn : in std_logic; 
 		pixel_clock, hsync, vsync : in std_logic; 
 		pixel_clock_out, hsync_out, vsync_out : out std_logic; 
 		pixel_data_in : in std_logic_vector(7 downto 0 ); 
 		pixel_data_out : out std_logic_vector(7 downto 0 )

);
end gauss3x3_pixel_pipeline;

architecture RTL of gauss3x3_pixel_pipeline is
	type mat33_16s is array (0 to 2,0 to 2) of signed(15 downto 0);
	type vec3_16s is array (0 to 2) of signed(15 downto 0);
	
	signal pixel_from_conv_latched : signed(15 downto 0);
	signal block3x3_sig : matNM(0 to 2, 0 to 2) ;
	signal new_block, pxclk_state : std_logic ;
	
	signal mult_scal : mat33_16s ;
	signal add_vec : vec3_16s ;
	signal pipeline_add_stages: mat33_16s ;
begin

		block0:  block3X3_pixel_pipeline
		generic map(WIDTH =>  WIDTH, HEIGHT => HEIGHT)
		port map(
			resetn => resetn , 
			pixel_clock => pixel_clock , hsync => hsync , vsync => vsync,
			pixel_data_in => pixel_data_in ,
			block_out => block3x3_sig);
		
		mult_scal(0, 0) <= resize(block3x3_sig(0,0), 16);
		mult_scal(0, 1) <= SHIFT_LEFT(resize(block3x3_sig(0,1), 16),1);
		mult_scal(0, 2) <= resize(block3x3_sig(0,2), 16);
		
		mult_scal(1, 0) <= SHIFT_LEFT(resize(block3x3_sig(1,0), 16),1);
		mult_scal(1, 1) <= SHIFT_LEFT(resize(block3x3_sig(1,1), 16),2);
		mult_scal(1, 2) <= SHIFT_LEFT(resize(block3x3_sig(1,2), 16),1);
		
		mult_scal(2, 0) <= resize(block3x3_sig(2,0), 16);
		mult_scal(2, 1) <= SHIFT_LEFT(resize(block3x3_sig(2,1), 16),1);
		mult_scal(2, 2) <= resize(block3x3_sig(2,2), 16);
				
		add_vec(0) <= mult_scal(0, 0) + mult_scal(1, 0) + mult_scal(2, 0) ;
		add_vec(1) <=  mult_scal(0, 1) + mult_scal(1, 1) + mult_scal(2, 1) ;
		add_vec(2) <=  mult_scal(0, 2) + mult_scal(1, 2) + mult_scal(2, 2) ;
		
		process(pixel_clock, resetn)
		begin
			if resetn = '0' then
				pipeline_add_stages(0,0) <= (others => '0') ;
				pipeline_add_stages(0,1) <= (others => '0') ;
				pipeline_add_stages(0,2) <= (others => '0') ;
				pipeline_add_stages(1,0) <= (others => '0') ;
				pipeline_add_stages(1,1) <= (others => '0') ;
				pipeline_add_stages(1,2) <= (others => '0') ;
				pipeline_add_stages(2,0) <= (others => '0') ;
				pipeline_add_stages(2,1) <= (others => '0') ;
				pipeline_add_stages(2,2) <= (others => '0') ;
			elsif pixel_clock'event and pixel_clock = '1' then
				pipeline_add_stages(0,0) <=  add_vec(0) ;
				pipeline_add_stages(0,1) <=  add_vec(1) ;
				pipeline_add_stages(0,2) <=  add_vec(2) ;
				
				pipeline_add_stages(1,1) <=  pipeline_add_stages(0,0) + pipeline_add_stages(0,1);
				pipeline_add_stages(1,2) <=  pipeline_add_stages(0,2) ;
				
				pipeline_add_stages(2,2) <=  pipeline_add_stages(1,2) + pipeline_add_stages(1,1) ;
			end if ;
		end process;
	
		pixel_clock_out <= pixel_clock  ;
		
		delay_sync: generic_delay
		generic map( WIDTH =>  2 , DELAY => 4)
		port map(
			clk => (pixel_clock), resetn => resetn ,
			input(0) => hsync ,
			input(1) => vsync ,
			output(0) => hsync_out ,
			output(1) => vsync_out
		);	
		
		process(pixel_clock, resetn)
		begin
			if resetn = '0' then
				pixel_from_conv_latched <= (others => '0') ;
			elsif pixel_clock'event and pixel_clock = '1' then
				pixel_from_conv_latched <= pipeline_add_stages(2,2) ;
			end if ;
		end process ;
		
		
		pixel_data_out <= std_logic_vector(pixel_from_conv_latched(11 downto 4)) ; -- divide by 16

end RTL;


