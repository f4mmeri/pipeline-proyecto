`timescale 1ns/1ps
module testbench;
    reg clk;
    reg reset;
    wire [31:0] WriteData, DataAdr;
    wire MemWrite;

    // Instancia del módulo TOP
    top dut(
        .clk(clk), 
        .reset(reset), 
        .WriteData(WriteData), 
        .DataAdr(DataAdr), 
        .MemWrite(MemWrite)
    );

    // Generador de reloj (Periodo de 10ns)
    always #5 clk = ~clk;

    initial begin
        // Inicializar reloj y reset
        clk = 0;
        reset = 1;
        #15; // Mantenemos el reset en alto un rato
        reset = 0; // Soltamos el reset, el procesador arranca
        
        // Corremos por 400ns y detenemos
        #400;
        $finish;
    end
endmodule