module heart_risk_minimal(
    input clk,
    input reset,
    input btn_enter,
    input [7:0] sw,
    output reg red_led,
    output reg green_led,
    output reg buzzer,
    output reg [6:0] seg,
    output reg [3:0] an
);

    // =========================
    // INPUT STORAGE
    // =========================
    reg [2:0] stage = 0;
    reg [7:0] x1=0,x2=0,x3=0,x4=0,x5=0,x6=0,x7=0,x8=0;

    reg [7:0] display_value = 0;
    reg [1:0] risk = 0;
    reg result_mode = 0;

    // =========================
    // CLOCK + DISPLAY
    // =========================
    reg [25:0] counter = 0;
    reg [15:0] refresh_counter = 0;
    reg [1:0] mux_sel = 0;

    wire blink_fast = counter[21];
    wire blink_slow = counter[24];

    reg btn_prev = 0;
    wire enter_pulse = btn_enter & ~btn_prev;

    reg [7:0] char0, char1, char2, char3;

    // =========================
    // CLOCK
    // =========================
    always @(posedge clk) begin
        counter <= counter + 1;
        refresh_counter <= refresh_counter + 1;
        mux_sel <= refresh_counter[15:14];
        btn_prev <= btn_enter;
    end

    // =========================
    // FSM + RISK LOGIC
    // =========================
    integer abnormal;

    always @(posedge clk) begin
        if(reset) begin
            stage <= 0;
            x1<=0; x2<=0; x3<=0; x4<=0;
            x5<=0; x6<=0; x7<=0; x8<=0;
            display_value <= 0;
            result_mode <= 0;
            risk <= 0;
        end
        else begin

            if(!result_mode)
                display_value <= sw;

            if(enter_pulse) begin
                case(stage)
                    3'd0: begin x1 <= sw; stage <= 1; end // Age
                    3'd1: begin x2 <= sw; stage <= 2; end // Chol
                    3'd2: begin x3 <= sw; stage <= 3; end // SysBP
                    3'd3: begin x4 <= sw; stage <= 4; end // DiaBP
                    3'd4: begin x5 <= sw; stage <= 5; end // HR
                    3'd5: begin x6 <= sw; stage <= 6; end // BMI
                    3'd6: begin x7 <= sw; stage <= 7; end // Trig

                    3'd7: begin
                        x8 <= sw; // Smoking
                        stage <= 0;
                        result_mode <= 1;

                        abnormal = 0;

                        // =========================
                        // CORRECT MEDICAL RANGES
                        // =========================

                        // Age (normal adult)
                        if(x1 > 60 || x1 < 18) abnormal = abnormal + 1;

                        // Cholesterol
                        if(x2 > 200) abnormal = abnormal + 1;

                        // Systolic BP
                        if(x3 > 140 || x3 < 90) abnormal = abnormal + 1;

                        // Diastolic BP
                        if(x4 > 90 || x4 < 60) abnormal = abnormal + 1;

                        // Heart Rate
                        if(x5 > 100 || x5 < 60) abnormal = abnormal + 1;

                        // BMI
                        if(x6 > 30 || x6 < 18) abnormal = abnormal + 1;

                        // Triglycerides
                        if(x7 > 150) abnormal = abnormal + 1;

                        // Smoking
                        if(sw == 1) abnormal = abnormal + 1;

                        // =========================
                        // RISK DECISION
                        // =========================
                        if(abnormal >= 6)
                            risk <= 2'b11;   // HIGH
                        else if(abnormal >= 4)
                            risk <= 2'b10;   // LOW
                        else if(abnormal >= 2)
                            risk <= 2'b01;   // AVG
                        else
                            risk <= 2'b00;   // GOOD
                    end
                endcase
            end
        end
    end

    // =========================
    // ALERT OUTPUT
    // =========================
    always @(*) begin
        case(risk)
            2'b11: begin
                red_led = blink_fast;
                green_led = 0;
                buzzer = blink_fast;
            end
            2'b10: begin
                red_led = blink_slow;
                green_led = 0;
                buzzer = blink_slow;
            end
            2'b01: begin
                red_led = 0;
                green_led = blink_slow;
                buzzer = 0;
            end
            default: begin
                red_led = 0;
                green_led = 1;
                buzzer = 0;
            end
        endcase
    end

    // =========================
    // DISPLAY
    // =========================
    always @(*) begin
        if(result_mode) begin
            case(risk)
                2'b11: begin char3="H"; char2="I"; char1="G"; char0="H"; end
                2'b10: begin char3="L"; char2="O"; char1="W"; char0=" "; end
                2'b01: begin char3="A"; char2="V"; char1="G"; char0=" "; end
                default: begin char3="G"; char2="O"; char1="O"; char0="D"; end
            endcase
        end
        else begin
            char0 = display_value % 10;
            char1 = (display_value / 10) % 10;
            char2 = (display_value / 100) % 10;
            char3 = " ";
        end
    end

    // =========================
    // MUX
    // =========================
    always @(*) begin
        case(mux_sel)
            2'b00: begin an=4'b1110; seg=seven_seg(char0); end
            2'b01: begin an=4'b1101; seg=seven_seg(char1); end
            2'b10: begin an=4'b1011; seg=seven_seg(char2); end
            2'b11: begin an=4'b0111; seg=seven_seg(char3); end
        endcase
    end

    // =========================
    // 7 SEG
    // =========================
    function [6:0] seven_seg;
        input [7:0] digit;
        begin
            case(digit)
                0: seven_seg=7'b1000000;
                1: seven_seg=7'b1111001;
                2: seven_seg=7'b0100100;
                3: seven_seg=7'b0110000;
                4: seven_seg=7'b0011001;
                5: seven_seg=7'b0010010;
                6: seven_seg=7'b0000010;
                7: seven_seg=7'b1111000;
                8: seven_seg=7'b0000000;
                9: seven_seg=7'b0010000;

                "H": seven_seg=7'b0001001;
                "I": seven_seg=7'b1111001;
                "G": seven_seg=7'b0000010;
                "L": seven_seg=7'b1000111;
                "O": seven_seg=7'b1000000;
                "W": seven_seg=7'b1010101;
                "A": seven_seg=7'b0001000;
                "V": seven_seg=7'b1100011;
                "D": seven_seg=7'b0100001;

                " ": seven_seg=7'b1111111;
                default: seven_seg=7'b1111111;
            endcase
        end
    endfunction

endmodule