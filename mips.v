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
               alusrc, regdst, regwrite, jump,
               eqorne, signzero;

  wire [2:0]  alucontrol;

  controller c(instr[31:26], instr[5:0], zero,
               memtoreg, memwrite, pcsrc,
               alusrc, regdst, regwrite, jump,
               eqorne, signzero,
               alucontrol);
  datapath dp(clk, reset, memtoreg, pcsrc,
              alusrc, regdst, regwrite, jump,
              signzero,
              alucontrol,
              zero, pc, instr,
              aluout, writedata, readdata);
endmodule


module controller(input   [5:0] op, funct,
                  input         zero,
                  output        memtoreg, memwrite,
                  output        pcsrc, alusrc,
                  output        regdst, regwrite,
                  output        jump, eqorne,
                  output        signzero,
                  output  [2:0] alucontrol);


    wire branch;
    reg bne, beq;
    wire [1:0] aluop;

    aludec      ad(funct, aluop, alucontrol);

    maindec     md(op, memtoreg, memwrite, branch,
                   alusrc, regdst, regwrite, jump, eqorne,
                   signzero, aluop);
////////////////////// BNE MODIFICATIONS ///////////////////////////////
    mux2 #(1)   pcsrcmux(beq,bne,eqorne,pcsrc);

    always@(branch)begin
        beq = branch ? (branch & zero):0;
        bne = branch ? (branch & ~zero):0;
    end
    
endmodule

module maindec(input [5:0] op,
               output memtoreg, memwrite,
               output branch, alusrc,
               output regdst, regwrite,
               output jump, eqorne,
               output signzero,
               output  [1:0] aluop);
    
    reg [10:0] controls;

    assign {regwrite, regdst, alusrc, branch, memwrite, memtoreg, aluop,
            jump,eqorne,signzero} = controls;

    always @(op) begin
        case(op)
            6'b000000: controls = 11'b11000010000; // R-TYPE
            6'b100011: controls = 11'b10100100000; // LW
            6'b101011: controls = 11'b00101000000; // SW
            6'b000100: controls = 11'b00010001000; // BEQ
            6'b001000: controls = 11'b10100000000; // ADDI
            6'b000010: controls = 11'b00000000100; // J
            6'b001101: controls = 11'b10100011001; // ***ORI***
            6'b000101: controls = 11'b00010001010; // ***BNE***
            default:   controls = 11'bxxxxxxxxxxx; // Illegal OP
        endcase
    end
endmodule

module aludec(input [5:0] funct,
              input [1:0] aluop,
              output reg [2:0] alucontrol);
    
    wire [5:0] ALUControlIn;
    assign ALUControlIn = {aluop, funct};
    always@(aluop, funct)begin
        case(aluop)
            2'b00: alucontrol = 3'b010; // ADD
            2'b01: alucontrol = 3'b110; // SUB
            2'b11: alucontrol = 3'b001; // OR 
            default: begin 
               case(funct) // R-TYPE
                  6'b100000: alucontrol = 3'b010; // ADD
                  6'b100010: alucontrol = 3'b110; // SUB
                  6'b100100: alucontrol = 3'b000; // AND
                  6'b100101: alucontrol = 3'b001; // OR
                  6'b101010: alucontrol = 3'b111; // SLT
                  //default: alucontrol = 3'bxxx; // Unknown
              endcase
           end
        endcase
    end
endmodule


module datapath(input          clk, reset,
                input          memtoreg, pcsrc,
                input          alusrc, regdst,
                input          regwrite, jump,
                input          signzero, 
                input   [2:0]  alucontrol,
                output         zero,
                output  [31:0] pc,
                input   [31:0] instr,
                output  [31:0] aluout, writedata,
                input   [31:0] readdata);


wire [4:0] writereg;
wire [31:0] pcnext, pcnextbr, pcplus4, pcbranch;
wire [31:0] signimm, signimmsh, zeroimm, aluimm;
wire [31:0] srca, srcb;
wire [31:0] result;        

// next PC logic
flopr #(32)     pcreg(clk, reset, pcnext, pc); // PC' and PC register
adder           pcaddl(pc,32'b100,pcplus4); // PCPlus4 calculated
sl2             immsh(signimm,signimmsh); // Word allign the sign extended imm
adder           pcadd2(pcplus4, signimmsh, pcbranch); // PCBranch calculated 
mux2 #(32)      pcbrmux(pcplus4, pcbranch, pcsrc, pcnextbr); // Where the branch PC' is
mux2 #(32)      pcmux(pcnextbr, {pcplus4[31:28],
                      instr[25:0],2'b00}, jump, pcnext); // This is where the jump is handled

// register file logic
regfile         rf(clk, regwrite, instr[25:21], instr[20:16],
                   writereg, result, srca, writedata); // RS register read into srca, RT register read into writedata
mux2 #(5)       wrmux(instr[20:16], instr[15:11],
                      regdst, writereg);
mux2 #(32)      resmux(aluout,readdata,memtoreg, result);
signextend      se(instr[15:0], signimm);
zeroextend      ze(instr[15:0], zeroimm); ///////////////// *** MODIFICATION FOR ORI ***

// ALU Logic *** MODIFICATIONS FOR ORI ***
mux2 #(32)      aluimmmux(signimm, zeroimm, signzero, aluimm);
mux2 #(32)      srcbmux(writedata, aluimm, alusrc, srcb);
ALU             bigboyalu(.a(srca),.b(srcb), .f(alucontrol), .y(aluout), .zero(zero));
                
endmodule

module regfile(input clk,
               input we3,
               input [4:0] ra1, ra2, wa3,
               input  [31:0] wd3,
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

module sl2(input [31:0] a,
           output [31:0] y);

    assign y = a << 2;

endmodule

module signextend(input [15:0] a,
                  output [31:0] y);

    assign y = {{16{a[15]}},a};

endmodule

module zeroextend(input [15:0] a,
                  output [31:0] y);

    assign y = {{16{1'b0}},a};

endmodule

module flopr #(parameter WIDTH=8)
              (input clk, reset,
               input [WIDTH-1:0] d,
               output reg [WIDTH-1:0] q);
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            q <= 0;
        end
        else begin
            q <= d;
        end
    end

endmodule

module mux2 #(parameter WIDTH = 8)
             (input [WIDTH-1:0] d0, d1,
              input s,
              output [WIDTH-1:0] y);

    assign y = s ? d1: d0;              
endmodule

module adder (input [31:0] a, b,
	      output [31:0] y);
	
	assign y = a + b;
endmodule


