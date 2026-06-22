module decompressor(
    input  [31:0] instr_in,      //instrucción viene de la memoria
    output reg [31:0] instr_out  //instrucción descomprimida de 32 bits
);

    always @(*) begin
        //si los dos últimos bits son distintos de 2'b11 -> es comprimida
        if (instr_in[1:0] != 2'b11) begin
            
            //campos principales de la instrucción comprimida
            case (instr_in[15:13]) 
                // Ejemplo: c.addi (Formato CI)
                3'b000: begin
                    if (instr_in[1:0] == 2'b01) begin
                        // c.addi rd, imm  -> addi rd, rd, imm
                        // rd = instr_in[11:7]
                        // imm = {instr_in[12], instr_in[6:2]}
                        // opcode del addi = 7'b0010011, funct3 = 3'b000
                        instr_out = { {6{instr_in[12]}}, instr_in[12], instr_in[6:2], instr_in[11:7], 3'b000, instr_in[11:7], 7'b0010011 };
                    end else begin
                        instr_out = 32'h00000013; // NOP por defecto si no coincide
                    end
                end

                //demás cases para c.add, c.sub, c.and, etc.
                // ...

                default: instr_out = 32'h00000013; // NOP de seguridad
            endcase

        end else begin
            // Si instr_in[1:0] == 2'b11, NO es comprimida. Pasa directo.
            instr_out = instr_in;
        end
    end

endmodule
