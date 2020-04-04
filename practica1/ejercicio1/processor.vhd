--------------------------------------------------------------------------------
-- Procesador MIPS con pipeline curso Arquitectura 2019-2020
--
-- Autor: Irene Truchado Mazzoli
-- Grupo: 1362
--
-- instancia el banco de registros (reg_bank), la ALU (alu), la unidad de control
-- (control_unit) y el bloque para el control de la ALU (alu_control)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity processor is
   port(
      Clk         : in  std_logic; -- Reloj activo en flanco subida
      Reset       : in  std_logic; -- Reset asincrono activo nivel alto
      -- Instruction memory
      IAddr      : out std_logic_vector(31 downto 0); -- Direccion Instr
      IDataIn    : in  std_logic_vector(31 downto 0); -- Instruccion leida
      -- Data memory
      DAddr      : out std_logic_vector(31 downto 0); -- Direccion
      DRdEn      : out std_logic;                     -- Habilitacion lectura
      DWrEn      : out std_logic;                     -- Habilitacion escritura
      DDataOut   : out std_logic_vector(31 downto 0); -- Dato escrito
      DDataIn    : in  std_logic_vector(31 downto 0)  -- Dato leido
   );
end processor;

architecture rtl of processor is 

	------------------------------------------------
	-- DECLARACION DE SENIALES DE LOS COMPONENTES --
	------------------------------------------------

	-- seniales para reg_bank
	signal A1, A2, A3    : std_logic_vector(4 downto 0);
	signal Rd1, Rd2, Wd3 : std_logic_vector(31 downto 0);
	signal We3			 : std_logic;
	
	-- seniales para alu
	signal OpA, OpB, Result : std_logic_vector (31 downto 0);
	signal Control 			: std_logic_vector ( 3 downto 0);
	signal ZFlag   			: std_logic;

	-- seniales para control_unit
	signal OpCode  															   : std_logic_vector (5 downto 0);
	signal Branch, MemToReg, MemWrite, MemRead, ALUSrc, RegWrite, RegDst, Jump : std_logic;
	signal ALUOp   														   	   : std_logic_vector (2 downto 0);
	
	-- seniales para alu_control
	signal Funct      : std_logic_vector (5 downto 0);
	signal ALUControl : std_logic_vector (3 downto 0);
	
	----------------------------------------
	-- DECLARACION DE SENIALES AUXILIARES --
	----------------------------------------
	
	signal MUXPC	  : std_logic_vector(31 downto 0);
	signal MUXPCJump  : std_logic_vector(31 downto 0);

	signal PC		  : std_logic_vector(31 downto 0);
	signal PCplus4	  : std_logic_vector(31 downto 0);

	signal ExtSigno	  : std_logic_vector(31 downto 0);
	signal ShiftLeft2 : std_logic_vector(31 downto 0);

	signal sumador	  : std_logic_vector(31 downto 0);

	signal puertaAND  : std_logic;

	--------------------------------
	-- DECLARACION DE COMPONENTES --
	--------------------------------
	
	COMPONENT reg_bank PORT (
		Clk   : in std_logic; 					   -- Reloj activo en flanco de subida
		Reset : in std_logic; 					   -- Reset asíncrono a nivel alto
		A1    : in std_logic_vector(4 downto 0);   -- Dirección para el puerto Rd1
		Rd1   : out std_logic_vector(31 downto 0); -- Dato del puerto Rd1
		A2    : in std_logic_vector(4 downto 0);   -- Dirección para el puerto Rd2
		Rd2   : out std_logic_vector(31 downto 0); -- Dato del puerto Rd2
		A3    : in std_logic_vector(4 downto 0);   -- Dirección para el puerto Wd3
		Wd3   : in std_logic_vector(31 downto 0);  -- Dato de entrada Wd3
		We3   : in std_logic 					   -- Habilitación de la escritura de Wd3
	); END COMPONENT;

	COMPONENT alu PORT (
		OpA     : in  std_logic_vector (31 downto 0); -- Operando A
		OpB     : in  std_logic_vector (31 downto 0); -- Operando B
		Control : in  std_logic_vector ( 3 downto 0); -- Codigo de control=op. a ejecutar
		Result  : out std_logic_vector (31 downto 0); -- Resultado
		ZFlag   : out std_logic                       -- Flag Z
	); END COMPONENT;

	COMPONENT control_unit PORT (
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
		Jump	: out std_logic
	); END COMPONENT;

	COMPONENT alu_control PORT (
		-- Entradas:
		ALUOp  : in std_logic_vector (2 downto 0); -- Codigo de control desde la unidad de control
		Funct  : in std_logic_vector (5 downto 0); -- Campo "funct" de la instruccion
		-- Salida de control para la ALU:
		ALUControl : out std_logic_vector (3 downto 0) -- Define operacion a ejecutar por la ALU
	); END COMPONENT;
	
	
	
---------------------------------------------------------------------------
--------------------------- INICIO DEL PROGRAMA ---------------------------
---------------------------------------------------------------------------
	
	begin
	
	--------------------------------------
	-- INSTANCIACION DE LOS COMPONENTES --
	--------------------------------------
	
	u1: reg_bank PORT MAP( -- instanciacion del banco de registros
		Clk => Clk,
		Reset => Reset,
		A1 => IDataIn(25 downto 21),
		Rd1 => Rd1,
		A2 => IDataIn(20 downto 16),
		Rd2 => Rd2,
		A3 => A3,
		We3 => RegWrite,
		Wd3 => Wd3
	);
	

	u2: alu PORT MAP( -- instanciacion de la alu
		OpA => RD1,
		OpB => OpB,
		Control => ALUControl,
		Result => Result,
		ZFlag => ZFlag
	);

	u3: control_unit PORT MAP( -- instanciacion de la unidad de control
		OpCode => IDataIn(31 downto 26),
		Branch => Branch,
		Jump => Jump,
		MemToReg => MemToReg,
		MemWrite => MemWrite,
		MemRead => MemRead,
		ALUSrc => ALUSrc,
		ALUOp => ALUOp,
		RegWrite => RegWrite,
		RegDst => RegDst
	);

	u4: alu_control PORT MAP( -- instanciacion de la unidad de control de la alu
		ALUOp => ALUOp,
		Funct => IDataIn(5 downto 0),
		ALUControl => ALUControl
	);

	------------ PC ------------------
	PC_reg: process(Clk, Reset)
		begin
			if Reset = '1' then PC <= (others => '0');
			elsif rising_edge (Clk) then PC <= MUXPCJump;
			end if;
	end process PC_reg;

	IAddr   <= PC;
	PCplus4 <= PC+4;

	------------ DATA MEMORY ------------------
	DAddr <= Result;
	DDataOut <= RD2;
	DRdEn <= MemRead;
	DWrEn <= MemWrite;
	
	----------- multiplexores -------------
	OpB <= Rd2 when ALUSrc = '0' else ExtSigno; -- multiplexor de la ALU
	A3 <= IDataIn(20 downto 16) when RegDst = '0' else IDataIn(15 downto 11); -- multiplexor banco de registros
	Wd3 <= Result when MemToReg = '0' else DDataIn; -- multiplexor memtoreg
	puertaAND <= Branch AND ZFlag; -- puerta AND para el branch
	MuxPC <= PCplus4 when puertaAND = '0' else sumador; -- multiplexor para el PC
	MuxPCJump <= MuxPC when Jump = '0' else PCplus4(31 downto 28) & IDataIn(25 downto 0) & "00"; -- multiplexor para el jump

	----- Implementación de la extensión de signo ------
	ExtSigno(31 downto 16) <= (others => IDataIn(15));
	ExtSigno(15 downto 0) <= IDataIn(15 downto 0);

	----- Implementación del desplazamiento <<2 ------
	ShiftLeft2 <= ExtSigno(29 downto 0) & "00";
	
	---------- Implementación del sumador -------
	sumador <= ShiftLeft2 + PCplus4;

end architecture;