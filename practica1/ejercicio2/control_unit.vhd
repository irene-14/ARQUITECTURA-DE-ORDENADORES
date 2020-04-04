--------------------------------------------------------------------------------
-- Unidad de control principal del micro. Arq0 2019-2020
--
-- Autor: Irene Truchado Mazzoli
-- Grupo: 1362
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity control_unit is
	port (
		-- Entrada = codigo de operacion en la instruccion:
		OpCode  : in  std_logic_vector (5 downto 0);
		-- Seniales para el PC
		Branch : out  std_logic; -- 1 = Ejecutandose instruccion branch
		-- Seniales relativas a la memoria
		MemToReg : out  std_logic; -- 1 = Escribir en registro la salida de la mem.
		MemWrite : out  std_logic; -- Escribir la memoria
		MemRead  : out  std_logic; -- Leer la memoria
		-- Seniales para la ALU
		ALUSrc : out  std_logic;                     -- 0 = oper.B es registro, 1 = es valor inm.
		ALUOp  : out  std_logic_vector (2 downto 0); -- Tipo operacion para control de la ALU
		-- Seniales para el GPR
		RegWrite : out  std_logic; -- 1=Escribir registro
		RegDst   : out  std_logic;  -- 0=Reg. destino es rt, 1=rd
		-- Senial aniadida para el JUMP
		Jump : out std_logic
	);
end control_unit;

architecture rtl of control_unit is

	-- declaramos una senial para almacenar el valor de cada salida de la unidad de control
	signal controlFlags: std_logic_vector(10 downto 0);

	-- Tipo para los codigos de operacion:
	subtype t_opCode is std_logic_vector (5 downto 0);

	-- Codigos de operacion para las diferentes instrucciones:
	constant OP_RTYPE  : t_opCode := "000000";
	constant OP_BEQ    : t_opCode := "000100";
	constant OP_SW     : t_opCode := "101011";
	constant OP_LW     : t_opCode := "100011";
	constant OP_LUI    : t_opCode := "001111";
	constant OP_J      : t_opCode := "000010";
	constant OP_SLTI   : t_opCode := "001010";
	constant OP_ADDI   : t_opCode := "001000";


begin

	-- concatenamos cada una de las salidas en la señal que hemos declarado anteriormente	
	RegDst   <= controlFlags (10);
	ALUSrc   <= controlFlags(9);
	MemToReg <= controlFlags(8);
	RegWrite <= controlFlags(7);
	MemRead  <= controlFlags(6);
	MemWrite <= controlFlags(5);
	Branch   <= controlFlags(4);
	ALUOp    <= controlFlags(3 downto 1);
	Jump     <= controlFlags(0);
	
	-- declaramos un proceso que depende de la entrada OPCode
	AsignarValores: process(OPCode)
		begin -- asignamos a la señal que hemos declarado el valor de las salidas segun la operacion que queremos hacer
			if    OPCode = OP_RTYPE then controlFlags <= "10010000100"; -- tipo R		
			elsif OPCode = OP_J     then controlFlags <= "00000000001"; -- j
			elsif OPCode = OP_BEQ   then controlFlags <= "00000010010"; -- beq
			elsif OPCode = OP_ADDI  then controlFlags <= "01010000000"; -- addi		
			elsif OPCode = OP_SLTI  then controlFlags <= "01010001000"; -- slti		
			elsif OPCode = OP_LW    then controlFlags <= "01111000000"; -- lw
			elsif OPCode = OP_SW    then controlFlags <= "01000100000"; -- sw
			elsif OPCode = OP_LUI   then controlFlags <= "01010000110"; -- lui
			else 						 controlFlags <= "00000000000"; -- nop
			end if;
	end process AsignarValores;

end architecture;
