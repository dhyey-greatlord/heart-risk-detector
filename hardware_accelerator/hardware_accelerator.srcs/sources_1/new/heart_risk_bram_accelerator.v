module heart_risk_bram_accelerator(
    input clk,
    input reset,
    input btn_prev,
    input btn_next,
    output reg red_led,
    output reg green_led,
    output reg buzzer,
    output reg [6:0] seg,
    output reg [3:0] an
);

    // =========================
    // WEIGHTS
    // =========================
    parameter signed W1 = 103;
    parameter signed W2 = -11;
    parameter signed W3 = 44;
    parameter signed W4 = -317;
    parameter signed W5 = 201;
    parameter signed W6 = -210;
    parameter signed W7 = -361;
    parameter signed W8 = -255;
    parameter signed BIAS = -193;

    localparam signed TH_AUG  = 0;
    localparam signed TH_LOU  = 4000;
    localparam signed TH_HIGH = 12000;

    // =========================
    // BRAM DATA
    // =========================
    reg [7:0] bram [0:31];
    initial begin
        // GOOD
        bram[0]=25;  bram[1]=80;  bram[2]=100; bram[3]=80;
        bram[4]=70;  bram[5]=22;  bram[6]=80;  bram[7]=0;

        // AUG
        bram[8]=60;  bram[9]=80;  bram[10]=220; bram[11]=60;
        bram[12]=205;bram[13]=18; bram[14]=90;  bram[15]=0;

        // LOU
        bram[16]=60; bram[17]=80; bram[18]=220; bram[19]=60;
        bram[20]=225;bram[21]=18; bram[22]=90;  bram[23]=0;

        // HIGH
        bram[24]=90; bram[25]=50; bram[26]=255; bram[27]=40;
        bram[28]=255;bram[29]=10; bram[30]=20;  bram[31]=0;
    end

    reg [1:0] patient_id = 0;
    reg btn_prev_d = 0, btn_next_d = 0;
    wire prev_pulse = btn_prev & ~btn_prev_d;
    wire next_pulse = btn_next & ~btn_next_d;

    reg [25:0] counter = 0;
    reg [15:0] refresh_counter = 0;
    reg [1:0] mux_sel = 0;
    reg [1:0] risk = 0;

    reg signed [31:0] x1,x2,x3,x4,x5,x6,x7,x8;
    reg signed [63:0] score;
    reg [7:0] char0,char1,char2,char3;

    wire blink_fast = counter[21];
    wire blink_slow = counter[24];

    // =========================
    // CLOCK
    // =========================
    always @(posedge clk) begin
        btn_prev_d <= btn_prev;
        btn_next_d <= btn_next;
        counter <= counter + 1;
        refresh_counter <= refresh_counter + 1;
        mux_sel <= refresh_counter[15:14];
    end

    // =========================
    // ADDRESS CONTROL
    // =========================
    always @(posedge clk) begin
        if(reset)
            patient_id <= 0;
        else if(next_pulse)
            patient_id <= (patient_id == 3) ? 0 : patient_id + 1;
        else if(prev_pulse)
            patient_id <= (patient_id == 0) ? 3 : patient_id - 1;
    end

    // =========================
    // FETCH + COMPUTE (FIXED SIGNED)
    // =========================
    always @(*) begin
        x1 = bram[patient_id*8 + 0];
        x2 = bram[patient_id*8 + 1];
        x3 = bram[patient_id*8 + 2];
        x4 = bram[patient_id*8 + 3];
        x5 = bram[patient_id*8 + 4];
        x6 = bram[patient_id*8 + 5];
        x7 = bram[patient_id*8 + 6];
        x8 = bram[patient_id*8 + 7];

        score =
            x1*W1 + x2*W2 + x3*W3 + x4*W4 +
            x5*W5 + x6*W6 + x7*W7 + x8*W8 + BIAS;

        if(x1 > 100)
            risk = 2'b11;
        else if(score > TH_HIGH)
            risk = 2'b11;
        else if(score > TH_LOU)
            risk = 2'b10;
        else if(score > TH_AUG)
            risk = 2'b01;
        else
            risk = 2'b00;
    end

    // =========================
    // ALERTS
    // =========================
    always @(*) begin
        case(risk)
            2'b11: begin red_led=blink_fast; green_led=0; buzzer=blink_fast; end
            2'b10: begin red_led=blink_slow; green_led=0; buzzer=blink_slow; end
            2'b01: begin red_led=0; green_led=blink_slow; buzzer=0; end
            default: begin red_led=0; green_led=1; buzzer=0; end
        endcase
    end

    // =========================
    // DISPLAY ONLY RESULT (FIXED)
    // =========================
    always @(*) begin
        case(risk)
            2'b11: begin char3="H"; char2="I"; char1="G"; char0="H"; end
            2'b10: begin char3="L"; char2="O"; char1="U"; char0=" "; end
            2'b01: begin char3="A"; char2="U"; char1="G"; char0=" "; end
            default: begin char3="G"; char2="O"; char1="O"; char0="D"; end
        endcase
    end

    always @(*) begin
        case(mux_sel)
            2'b00: begin an = 4'b1110; seg = seven_seg(char0); end
            2'b01: begin an = 4'b1101; seg = seven_seg(char1); end
            2'b10: begin an = 4'b1011; seg = seven_seg(char2); end
            2'b11: begin an = 4'b0111; seg = seven_seg(char3); end
        endcase
    end

    function [6:0] seven_seg;
        input [7:0] c;
        begin
            case(c)
                "H": seven_seg = 7'b0001001;
                "I": seven_seg = 7'b1111001;
                "G": seven_seg = 7'b0000010;
                "L": seven_seg = 7'b1000111;
                "O": seven_seg = 7'b1000000;
                "U": seven_seg = 7'b1000001;
                "A": seven_seg = 7'b0001000;
                "D": seven_seg = 7'b0100001;
                default: seven_seg = 7'b1111111;
            endcase
        end
    endfunction

endmodule