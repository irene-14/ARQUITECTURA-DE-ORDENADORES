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

	signal PCplus4_IF, PCplus4_ID, PCplus4_EX : std_logic_vector(31 downto 0);
	signal IDataIn_ID, IDataIn_EX			  : std_logic_vector(31 downto 0);
	signal PC_IF		  					  : std_logic_vector(31 downto 0);
	
	signal RD1_ID, RD1_EX: std_logic_vector(31 downto 0);
	signal RD2_ID, RD2_EX, RD2_MEM: std_logic_vector(31 downto 0);
	signal ExtSigno_ID, ExtSigno_EX	  : std_logic_vector(31 downto 0);
	
	signal sumador_EX, sumador_MEM: std_logic_vector(31 downto 0);
	
	signal ALUControl: std_logic_vector(3 downto 0);
	
	signal ZFlag_EX, ZFlag_MEM: std_logic;
	signal Result_EX, Result_MEM, Result_WB : std_logic_vector (31 downto 0);
	
	signal A3_EX, A3_MEM, A3_WB: std_logic_vector(4 downto 0);
	
	signal DDataIn_WB: std_logic_vector(31 downto 0);
	
	signal Wd3_WB: std_logic_vector(31 downto 0);
	
	signal OpB_EX: std_logic_vector(31 downto 0);

	signal puertaAND_MEM  : std_logic;
	
	signal MUXPC_IF	  : std_logic_vector(31 downto 0);
	signal MUXPCJump_IF  : std_logic_vector(31 downto 0);

	signal ShiftLeft2_EX : std_logic_vector(31 downto 0);

	-- Unidad de adelantamiento (señales y multiplexores)
	signal ForwardA, ForwardB		: std_logic_vector (1 downto 0);
	signal MUXForwardA, MUXForwardB : std_logic_vector (31 downto 0);

	-- Señales para la Hazard Detection Unit
	signal PCWrite: std_logic;
	signal IFIDWrite: std_logic;
	signal Bubble: std_logic;

	--Señales de control

		-- ID/EX
		signal ALUSrc_ID, ALUSrc_EX : std_logic;
		signal ALUOp_ID, ALUOp_EX	: std_logic_vector (2 downto 0);
		signal RegDst_ID, RegDst_EX : std_logic;
		
		-- ID/EX/MEM
		signal Jump_ID, Jump_EX, Jump_MEM			  : std_logic;
		signal Branch_ID, Branch_EX, Branch_MEM		  : std_logic;
		signal MemRead_ID, MemRead_EX, MemRead_MEM	  : std_logic;
		signal MemWrite_ID, MemWrite_EX, MemWrite_MEM : std_logic;

		-- ID/EX/MEM/WB
		signal MemToReg_ID, MemToReg_EX, MemToReg_MEM, MemToReg_WB : std_logic;
		signal RegWrite_ID, RegWrite_EX, RegWrite_MEM, RegWrite_WB : std_logic;



	--------------------------------
	-- DECLARACION DE COMPONENTES --
	--------------------------------
	
	COMPONENT reg_bank PORT (
		Clk   : in  std_logic; 					   -- Reloj activo en flanco de subida
		Reset : in  std_logic; 					   -- Reset asíncrono a nivel alto
		A1    : in  std_logic_vector (4 downto 0);   -- Dirección para el puerto Rd1
		Rd1   : out std_logic_vector (31 downto 0); -- Dato del puerto Rd1
		A2    : in  std_logic_vector (4 downto 0);   -- Dirección para el puerto Rd2
		Rd2   : out std_logic_vector (31 downto 0); -- Dato del puerto Rd2
		A3    : in  std_logic_vector (4 downto 0);   -- Dirección para el puerto Wd3
		Wd3   : in  std_logic_vector (31 downto 0);  -- Dato de entrada Wd3
		We3   : in  std_logic 					   -- Habilitación de la escritura de Wd3
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
		Clk	  => Clk,
		Reset => Reset,
		A1	  => IDataIn_ID(25 downto 21),
		Rd1   => RD1_ID,
		A2	  => IDataIn_ID(20 downto 16),
		Rd2	  => RD2_ID,
		A3 	  => A3_WB,
		We3	  => RegWrite_WB,
		Wd3   => Wd3_WB
	);
	

	u2: alu PORT MAP( -- instanciacion de la alu
		OpA 	=> MUXForwardA,
		OpB 	=> OpB_EX,
		Control => ALUControl,
		Result 	=> Result_EX,
		ZFlag 	=> ZFlag_EX
	);

	u3: control_unit PORT MAP( -- instanciacion de la unidad de control
		OpCode 	 => IDataIn_ID(31 downto 26),
		Branch 	 => Branch_ID,
		Jump 	 => Jump_ID,
		MemToReg => MemToReg_ID,
		MemWrite => MemWrite_ID,
		MemRead  => MemRead_ID,
		ALUSrc 	 => ALUSrc_ID,
		ALUOp	 => ALUOp_ID,
		RegWrite => RegWrite_ID,
		RegDst 	 => RegDst_ID
	);

	u4: alu_control PORT MAP( -- instanciacion de la unidad de control de la alu
		ALUOp 	   => ALUOp_EX,
		Funct 	   => ExtSigno_EX (5 downto 0),
		ALUControl => ALUControl
	);

	------------ PC ------------------
	PC_reg: process(Clk, Reset, PCWrite, MUXPCJump_IF)
		begin
			if Reset = '1' then PC_IF <= (others => '0');
			elsif (rising_edge (Clk) AND PCWrite = '1') then PC_IF <= MUXPCJump_IF;
			end if;
	end process PC_reg;

	IAddr	   <= PC_IF;
	PCplus4_IF <= PC_IF + 4;

	------------ DATA MEMORY ------------------
	DAddr	 <= Result_MEM;
	DDataOut <= RD2_MEM;
	DRdEn 	 <= MemRead_MEM;
	DWrEn 	 <= MemWrite_MEM;
	
	----------- multiplexores -------------
	OpB_EX 		  <= MUXForwardB when ALUSrc_EX = '0' else ExtSigno_EX; -- multiplexor de la ALU
	A3_EX 		  <= IDataIn_EX(20 downto 16) when RegDst_EX = '0' else IDataIn_EX(15 downto 11); -- multiplexor banco de registros
	Wd3_WB 		  <= Result_WB when MemToReg_WB = '0' else DDataIn_WB; -- multiplexor memtoreg
	puertaAND_MEM <= Branch_MEM AND ZFlag_MEM; -- puerta AND para el branch
	MuxPC_IF 	  <= PCplus4_IF when puertaAND_MEM = '0' else sumador_MEM; -- multiplexor para el PC
	MuxPCJump_IF  <= MuxPC_IF when Jump_MEM = '0' else PCplus4_IF(31 downto 28) & IDataIn(25 downto 0) & "00"; -- multiplexor para el jump
	
	with ForwardA select -- multiplexor para el adelantamiento del OpA de la ALU
		MUXForwardA <=	RD1_EX 		when "00", 	 -- OpA viene de ID/EX
						Wd3_WB		when "01", 	 -- OpA viene de MEM/WB
						Result_MEM 	when others; -- OpA viene de EX/MEM
	with ForwardB select -- multiplexor para el adelantamiento del OpB de la ALU
		MUXForwardB <=	RD2_EX 		when "00",	 -- OpB viene de ID/EX
						Wd3_WB		when "01",	 -- OpB viene de MEM/WB
						Result_MEM 	when others; -- OpB viene de EX/MEM

	----- Implementación de la extensión de signo ------
	ExtSigno_ID(31 downto 16) <= (others => IDataIn_ID(15));
	ExtSigno_ID(15 downto 0)  <= IDataIn_ID(15 downto 0);

	----- Implementación del desplazamiento <<2 ------
	ShiftLeft2_EX <= ExtSigno_EX(29 downto 0) & "00";
	
	---------- Implementación del sumador -------
	sumador_EX <= ShiftLeft2_EX + PCplus4_EX;

	------ Forwarding Unit -------
	ForwardA <=  -- El primer operando de la ALU es adelantado desde el anterior resultado de la ALU
				"10" when (RegWrite_MEM = '1' AND A3_MEM /= "00000" AND A3_MEM = IDataIn_EX(25 downto 21)) else
				 -- El primer operando de la ALU es adelantado desde la memoria o un anterior resultado de la ALU
				"01" when (RegWrite_WB = '1' AND A3_WB /= "00000" AND NOT (RegWrite_MEM = '1' AND (A3_MEM /= "00000") AND (A3_MEM /= IDataIn_EX(25 downto 21))) AND A3_WB = IDataIn_EX(25 downto 21)) else
				-- El primer operando de la ALU llega desde el banco de registros
				"00";

	ForwardB <= -- El segundo operando de la ALU es adelantado desde el anterior resultado de la ALU
				"10" when (RegWrite_MEM = '1' AND A3_MEM /= "00000" AND A3_MEM = IDataIn_EX(20 downto 16)) else
				-- El segundo operando de la ALU es adelantado desde la memoria o un anterior resultado de la ALU
				"01" when (RegWrite_WB = '1' AND A3_WB /= "00000" AND NOT (RegWrite_MEM = '1' AND (A3_MEM /= "00000") AND (A3_MEM /= IDataIn_EX(20 downto 16))) AND A3_WB = IDataIn_EX(20 downto 16)) else
				-- El segundo operando de la ALU llega desde el banco de registros
				"00";

	------ Hazard Detection Unit -------

	PCWrite <=  '0' when (
							MemRead_EX = '1' AND ( -- comprueba si la instruccion es un load
							(IDataIn_EX(20 downto 16) = IDataIn_ID(25 downto 21)) OR  -- comprueba si el registro destino del load en EX es igual que el registro RS en ID
							(IDataIn_EX(20 downto 16) = IDataIn_ID(20 downto 16))) -- comprueba si el registro destino del load en EX es igual que el registro RT en ID
						) else
				'1';

	IFIDWRite <=  '0' when (
							MemRead_EX = '1' AND ( -- comprueba si la instruccion es un load
							(IDataIn_EX(20 downto 16) = IDataIn_ID(25 downto 21)) OR  -- comprueba si el registro destino del load en EX es igual que el registro RS en ID
							(IDataIn_EX(20 downto 16) = IDataIn_ID(20 downto 16))) -- comprueba si el registro destino del load en EX es igual que el registro RT en ID
						) else
				'1';

	Bubble <=  '1' when (
							MemRead_EX = '1' AND ( -- comprueba si la instruccion es un load
							(IDataIn_EX(20 downto 16) = IDataIn_ID(25 downto 21)) OR  -- comprueba si el registro destino del load en EX es igual que el registro RS en ID
							(IDataIn_EX(20 downto 16) = IDataIn_ID(20 downto 16))) -- comprueba si el registro destino del load en EX es igual que el registro RT en ID
						) else
				'0';

	-- REGISTROS

	REG_IF_ID: process(Clk, Reset, IFIDWRite, PCplus4_IF, IDataIn)
		begin
			if Reset = '1' then
				PCplus4_ID <= (others => '0');
				IDataIn_ID <= (others => '0');
			elsif (rising_edge (Clk) AND IFIDWRite = '1') then
				PCplus4_ID <= PCplus4_IF;
				IDataIn_ID <= IDataIn;
			end if;
	end process REG_IF_ID;
	
	REG_ID_EX: process(Clk, Reset)
		begin
			if Reset = '1' then
				ALUSrc_EX <= '0';
				ALUOp_EX <= "000";
				RegDst_EX <= '0';
				Jump_EX <= '0';
				Branch_EX <= '0';
				MemRead_EX <= '0';
				MemWrite_EX <= '0';
				MemToReg_EX <= '0';
				RegWrite_EX <= '0';
				PCplus4_EX <= (others => '0');
				RD1_EX <= (others => '0');
				RD2_EX <= (others => '0');
				ExtSigno_EX <= (others => '0');
				IDataIn_EX <= (others => '0');
			elsif rising_edge (Clk) then
				if Bubble = '1' then -- hacemos el stalling
					ALUSrc_EX <= '0';
					ALUOp_EX <= "000";
					RegDst_EX <= '0';
					Jump_EX <= '0';
					Branch_EX <= '0';
					MemRead_EX <= '0';
					MemWrite_EX <= '0';
					MemToReg_EX <= '0';
					RegWrite_EX <= '0';
					PCplus4_EX <= (others => '0');
					RD1_EX <= (others => '0');
					RD2_EX <= (others => '0');
					ExtSigno_EX <= (others => '0');
					IDataIn_EX <= (others => '0');
				else
					ALUSrc_EX <= ALUSrc_ID;
					ALUOp_EX <= ALUOp_ID;
					RegDst_EX <= RegDst_ID;
					Jump_EX <= Jump_ID;
					Branch_EX <= Branch_ID;
					MemRead_EX <= MemRead_ID;
					MemWrite_EX <= MemWrite_ID;
					MemToReg_EX <= MemToReg_ID;
					RegWrite_EX <= RegWrite_ID;
					PCplus4_EX <= PCplus4_ID;
					RD1_EX <= RD1_ID;
					RD2_EX <= RD2_ID;
					ExtSigno_EX <= ExtSigno_ID;
					IDataIn_EX <= IDataIn_ID;
				end if;
			end if;
	end process REG_ID_EX;
	
	REG_EX_MEM: process(Clk, Reset)
		begin
			if Reset = '1' then
				Jump_MEM <= '0';
				Branch_MEM <= '0';
				MemRead_MEM <= '0';
				MemWrite_MEM <= '0';
				MemToReg_MEM <= '0';
				RegWrite_MEM <= '0';
				sumador_MEM <= (others => '0');
				ZFlag_MEM <= '0';
				Result_MEM <= (others => '0');
				RD2_MEM <= (others => '0');
				A3_MEM <= (others => '0');
			elsif rising_edge (Clk) then
				Jump_MEM <= Jump_EX;
				Branch_MEM <= Branch_EX;
				MemRead_MEM <= MemRead_EX;
				MemWrite_MEM <= MemWrite_EX;
				MemToReg_MEM <= MemToReg_EX;
				RegWrite_MEM <= RegWrite_EX;
				sumador_MEM <= sumador_EX;
				ZFlag_MEM <= ZFlag_EX;
				Result_MEM <= Result_EX;
				RD2_MEM <= RD2_EX;
				A3_MEM <= A3_EX;
			end if;
	end process REG_EX_MEM;
	
	REG_MEM_WB: process(Clk, Reset)
		begin
			if Reset = '1' then
				MemToReg_WB <= '0';
				RegWrite_WB <= '0';
				DDataIn_WB <= (others => '0');
				Result_WB <= (others => '0');
				A3_WB <= (others => '0');
			elsif rising_edge (Clk) then
				MemToReg_WB <= MemToReg_MEM;
				RegWrite_WB <= RegWrite_MEM;
				DDataIn_WB <= DDataIn;
				Result_WB <= Result_MEM;
				A3_WB <= A3_MEM;
			end if;
	end process REG_MEM_WB;

end architecture;