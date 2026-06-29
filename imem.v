module imem(input  [31:0] a,
            output [31:0] rd);
  
  reg [31:0] RAM[63:0]; 

  initial begin
      $readmemh("test_e2p2.mem", RAM);   // para probar Parte 2
// $readmemh("memfile.mem", RAM);  // para probar Parte 1 
  end

  assign rd = RAM[a[31:2]]; // word aligned
endmodule
