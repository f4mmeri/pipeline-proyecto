module decompressor(
    input  [31:0] instr_in,      // Entrada cruda desde la memoria de instrucciones
    output reg [31:0] instr_out  // Salida expandida a 32 bits (RV32I estándar)
);

    // Variables internas para extraer campos RVC comunes
    wire [4:0] rd_ci   = instr_in[11:7];               // Registro destino en formato CI/CR
    wire [4:0] rs2_cr  = instr_in[6:2];                // Registro fuente 2 en formato CR
    wire [4:0] r_prime_rd  = {2'b01, instr_in[9:7]};   // Mapeo de r' (x8-x15) para destino
    wire [4:0] r_prime_rs2 = {2'b01, instr_in[4:2]};   // Mapeo de r' (x8-x15) para fuente 2
    
    // Reconstrucción de inmediatos y shamt (Shift Amount)
    wire [11:0] imm_ci  = { {6{instr_in[12]}}, instr_in[12], instr_in[6:2] }; 
    wire [11:0] imm_cb  = { {7{instr_in[12]}}, instr_in[6:2] };
    wire [19:0] nzimm_lui = { {14{instr_in[12]}}, instr_in[12], instr_in[6:2] };
    wire [4:0]  shamt   = { instr_in[12], instr_in[6:2] };

    always @(*) begin
        // Valores por defecto (NOP estándar de RISC-V: addi x0, x0, 0)
        instr_out = 32'h00000013; 

        // DETECCIÓN: Si los dos bits menos significativos NO son 2'b11, es RVC (16 bits)
        if (instr_in[1:0] != 2'b11) begin
            
            case (instr_in[1:0])
                
                // --- cuadrante 01 ---
                2'b01: begin
                    case (instr_in[15:13])
                        // c.addi
                        3'b000: begin
                            if (rd_ci != 5'd0) begin
                                // Formato RV32I: imm[11:0] | rs1[4:0] | funct3 | rd[4:0] | opcode
                                instr_out = { imm_ci, rd_ci, 3'b000, rd_ci, 7'b0010011 };
                            end
                        end
                        
                        // c.lui
                        3'b011: begin
                            // Excluye x0 y x2 (Stack Pointer usado por c.li/c.addi16sp)
                            if (rd_ci != 5'd0 && rd_ci != 5'd2) begin
                                // Formato RV32I: imm[31:12] | rd[4:0] | opcode
                                instr_out = { nzimm_lui, rd_ci, 7'b0110111 };
                            end
                        end
                        
                        // Grupo mixto (c.srli, c.srai, c.andi, c.sub, c.xor, c.or, c.and)
                        3'b100: begin
                            case (instr_in[11:10])
                                // c.srli
                                2'b00: begin
                                    instr_out = { 7'b0000000, shamt, r_prime_rd, 3'b101, r_prime_rd, 7'b0010011 };
                                end
                                // c.srai
                                2'b01: begin
                                    instr_out = { 7'b0100000, shamt, r_prime_rd, 3'b101, r_prime_rd, 7'b0010011 };
                                end
                                // c.andi
                                2'b10: begin
                                    instr_out = { imm_cb, r_prime_rd, 3'b111, r_prime_rd, 7'b0010011 };
                                end
                                // Subgrupo de operaciones Registro-Registro (CA Format)
                                2'b11: begin
                                    if (instr_in[12] == 1'b0) begin
                                        case (instr_in[6:5])
                                            3'b00: instr_out = { 7'b0100000, r_prime_rs2, r_prime_rd, 3'b000, r_prime_rd, 7'b0110011 }; // c.sub
                                            3'b01: instr_out = { 7'b0000000, r_prime_rs2, r_prime_rd, 3'b100, r_prime_rd, 7'b0110011 }; // c.xor
                                            3'b10: instr_out = { 7'b0000000, r_prime_rs2, r_prime_rd, 3'b110, r_prime_rd, 7'b0110011 }; // c.or
                                            3'b11: instr_out = { 7'b0000000, r_prime_rs2, r_prime_rd, 3'b111, r_prime_rd, 7'b0110011 }; // c.and
                                        endcase
                                    end
                                end
                            endcase
                        end
                    endcase
                end

                // --- cuadrante 10 ---
                2'b10: begin
                    case (instr_in[15:13])
                        // c.slli
                        3'b000: begin
                            if (rd_ci != 5'd0) begin
                                instr_out = { 7'b0000000, shamt, rd_ci, 3'b001, rd_ci, 7'b0010011 };
                            end
                        end
                        // c.add
                        3'b100: begin
                            // Bit 12 debe ser 0, y rs2 != 0 (si rs2==0 es un salto c.jalr/c.jr)
                            if (instr_in[12] == 1'b0 && rs2_cr != 5'd0) begin
                                instr_out = { 7'b0000000, rs2_cr, rd_ci, 3'b000, rd_ci, 7'b0110011 };
                            end
                        end
                    endcase
                end
                
                default: instr_out = 32'h00000013; // Seguridad NOP
            endcase

        end else begin
            // Si termina en 2'b11, es una instrucción nativa de 32 bits (Pasa directa)
            instr_out = instr_in;
        end
    end

endmodule
