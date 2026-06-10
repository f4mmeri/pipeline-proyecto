//agregar los 4 registros del pipeline, el registro de IF/ID, 
//el registro de ID/EX, el registro de EX/MEM y el registro de MEM/WB. 
// Cada uno de estos registros debe almacenar la información relevante 
//para cada etapa del pipeline, como la instrucción, los operandos, 
//los resultados intermedios, etc. Además, se deben agregar las señales 
//de control necesarias para manejar el flujo de datos entre las etapas 
//del pipeline y evitar conflictos de datos (hazards).

module datapath(
    input  clk, reset,
 
    input  [1:0] ResultSrcD,
    input  MemWriteD, MemReadD,
    input  BranchD, JumpD,
    input  ALUSrcD,
    input  RegWriteD,
    input  [1:0]  ImmSrcD,
    input  [2:0]  ALUControlD,
 
    input  StallF, StallD, FlushE, FlushD,
    input  [1:0] ForwardAE, ForwardBE,
 
    output [31:0] PC,
    input  [31:0] Instr,        
    output [31:0] ALUResultM,   
    output [31:0] WriteDataM,  
    input  [31:0] ReadDataM,   
    output        MemWriteM,   
 
    output [4:0]  Rs1E, Rs2E, RdE, RdM, RdW,
    output        RegWriteM, RegWriteW,
    output        MemReadE
);
  
  localparam WIDTH = 32; // Define a local parameter for bus width

  wire [31:0] PCNext, PCPlus4, PCTarget; 
  wire [31:0] ImmExt; 
  wire [31:0] SrcA, SrcB; 
  wire [31:0] Result; 

  // next PC logic
  flopr #(WIDTH) pcreg(
    .clk(clk), 
    .reset(reset), 
    .d(PCNext), 
    .q(PC)
  ); 

  adder       pcadd4(
    .a(PC), 
    .b({WIDTH{1'b0}} + 4), // Using WIDTH parameter for constant 4
    .y(PCPlus4)
  ); 

  adder       pcaddbranch(
    .a(PC), 
    .b(ImmExt), 
    .y(PCTarget)
  ); 

  mux2 #(WIDTH)  pcmux(
    .d0(PCPlus4), 
    .d1(PCTarget), 
    .s(PCSrc), 
    .y(PCNext)
  ); 
 
  // register file logic
  regfile     rf(
    .clk(clk), 
    .we3(RegWrite), 
    .a1(Instr[19:15]), 
    .a2(Instr[24:20]), 
    .a3(Instr[11:7]), 
    .wd3(Result), 
    .rd1(SrcA), 
    .rd2(WriteData)
  ); 

  extend      ext(
    .instr(Instr[31:7]), 
    .immsrc(ImmSrc), 
    .immext(ImmExt)
  ); 

  // ALU logic
  mux2 #(WIDTH)  srcbmux(
    .d0(WriteData), 
    .d1(ImmExt), 
    .s(ALUSrc), 
    .y(SrcB)
  ); 

  alu         alu(
    .a(SrcA), 
    .b(SrcB), 
    .alucontrol(ALUControl), 
    .result(ALUResult), 
    .zero(Zero)
  ); 

  mux3 #(WIDTH)  resultmux(
    .d0(ALUResult), 
    .d1(ReadData), 
    .d2(PCPlus4), 
    .s(ResultSrc), 
    .y(Result)
  ); 
endmodule