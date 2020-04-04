--------------------------------------------------------------------------------
-- Bloque de control para la ALU. Arq0 2019-2020.
--
-- Autor: Irene Truchado Mazzoli
-- Grupo: 1362
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity alu_control is
   port (
      -- Entradas:
      ALUOp  : in std_logic_vector (2 downto 0); -- Codigo de control desde la unidad de control
      Funct  : in std_logic_vector (5 downto 0); -- Campo "funct" de la instruccion
      -- Salida de control para la ALU:
      ALUControl : out std_logic_vector (3 downto 0) -- Define operacion a ejecutar por la ALU
   );
end alu_control;

architecture rtl of alu_control is

   signal salida : std_logic_vector (3 downto 0); -- operacion de salida de ALU Control

begin

	ALUControl <= salida;

	LecturaALUOp: process(ALUOp, Funct)
		begin
			case ALUOp is
				when "000" => salida <= "0000"; -- LW, SW, ADDI
				when "001" => salida <= "0001"; -- BEQ
				when "011" => salida <= "1101"; -- LUI
				when "100" => salida <= "1010"; -- SLTI
				when "010" => -- R-TYPE
					case Funct is
						when "100110" => salida <= "0110"; -- XOR
						when "100000" => salida <= "0000"; -- ADD
						when "100010" => salida <= "0001"; -- SUB
						when "100100" => salida <= "0100"; -- AND
						when "100101" => salida <= "0111"; -- OR
						when "101010" => salida <= "1010"; -- SLT
						when others   => salida <= "1111"; -- NOP
					end case;
				when others => salida <= "1111";
			end case;
	end process LecturaALUOp;

end architecture;