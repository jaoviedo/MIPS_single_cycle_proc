// single-cycle MIPS processor
// instantiates a controller and a datapath module

module mips(input          clk, reset,
            output  [31:0] pc,
            input   [31:0] instr,
            output         memwrite,
            output  [31:0] aluout, writedata,
            input   [31:0] readdata);

  wire        memtoreg, branch,
               pcsrc, zero,
               alusrc, regdst, regwrite, jump;

  wire [2:0]  alucontrol;

  controller c(instr[31:26], instr[5:0], zero,
               memtoreg, memwrite, pcsrc,
               alusrc, regdst, regwrite, jump,
               alucontrol);
  datapath dp(clk, reset, memtoreg, pcsrc,
              alusrc, regdst, regwrite, jump,
              alucontrol,
              zero, pc, instr,
              aluout, writedata, readdata);
endmodule


// Todo: Implement controller module
module controller(input   [5:0] op, funct,
                  input         zero,
                  output        memtoreg, memwrite,
                  output        pcsrc, alusrc,
                  output        regdst, regwrite,
                  output        jump, eqorne,
                  output        signzero,
                  output  [2:0] alucontrol);

// **PUT YOUR CODE HERE**

    wire branch;
    wire [1:0] aluop;

    maindec md(op, memtoreg, memwrite, branch,
               alusrc, regdst, regwrite, jump, eqorne,
               signzero, aluop);

    aludec ad(funct, aluop, alucontrol);

    assign pcsrc = branch & zero; // TODO : FIX WITH MUX

endmodule

module maindec(input [5:0] op,
               output memtoreg, memwrite,
               output branch, alusrc,
               output regdst, regwrite,
               output jump, eqorne,
               output signzero,
               output [1:0] aluop);
    
    reg [10:0] controls;

    assign {regwrite, regdst, alusrc, branch, memwrite, aluop,
            jump,eqorne,signzero} = controls;

    always @(*) begin
        case(op)
            6'b000000: controls <= 11'b11000010000; // RTYPE
            6'b100011: controls <= 11'b10100100000; // LW
            6'b101011: controls <= 11'b00101000000; // SW
            6'b000100: controls <= 11'b00010001000; // BEQ
            6'b001000: controls <= 11'b10100000000; // ADDI
            6'b000010: controls <= 11'b00000000100; // J
            6'b001101: controls <= 11'b10100011001; // ORI
            6'b000101: controls <= 11'b00010001010; // BNE
            default:   controls <= 11'bxxxxxxxxxxx; // Illegal OP
        endcase
    end
endmodule

module aludec(input [5:0] funct,
              input [1:0] aluop,
              output [2:0] alucontol);
    
    always@(*)begin
        case(aluop)
            2'b00: alucontrol <= 3'b010; // ADD
            2'b01: alucontrol <= 3'b110; // SUB
            2'b11: alucontrol <= 3'b001; // OR 
            default: case(funct) // R-TYPE
                6'b100000: alucontrol <= 3'b010; // ADD
                6'b100010: alucontrol <= 3'b110; // SUB
                6'b100100: alucontrol <= 3'b000; // AND
                6'b100101: alucontrol <= 3'b001; // OR
                6'b101010: alucontrol <= 3'b111; // SLT
                default: alucontrol <= 3'bxxx; // Unknown
            endcase
        endcase
    end
endmodule

// Todo: Implement datapath
module datapath(input          clk, reset,
                input          memtoreg, pcsrc,
                input          alusrc, regdst,
                input          regwrite, jump,
                input   [2:0]  alucontrol,
                output         zero,
                output  [31:0] pc,
                input   [31:0] instr,
                output  [31:0] aluout, writedata,
                input   [31:0] readdata);

// **PUT YOUR CODE HERE**                
                
endmodule

module regfile(input clk,
               input we3,
               input [4:0] ra1, ra2, wa3,
               output [31:0] wd3,
               output [31:0] rd1, rd2);

    reg [31:0] rf[31:0];

    always @ (posedge clk) begin
        if(we3) begin
            rf[wa3] <= wd3;
        end
    end

    assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
    assign rd2 = (ra2 != 0) ? rf[ra2] : 0;

endmodule

