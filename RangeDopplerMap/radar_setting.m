function [mode,max_range,max_speed,samples,sweeps] = radar_setting(code)
% radar_setting: Identifies radar parameters based on parameter value
    switch code
        case 0; mode = '2D'; max_range = 6;   max_speed = 10;  sweeps = 64;
        case 1; mode = '2D'; max_range = 10;  max_speed = 10;  sweeps = 64;
        case 2; mode = '2D'; max_range = 30;  max_speed = 30;  sweeps = 64;
        case 3; mode = '2D'; max_range = 30;  max_speed = 50;  sweeps = 64;
        case 4; mode = '2D'; max_range = 50;  max_speed = 50;  sweeps = 64;
        case 5; mode = '2D'; max_range = 100; max_speed = 100; sweeps = 64;
        case 6; mode = '3D'; max_range = 6;   max_speed = 10;  sweeps = 32;
        case 7; mode = '3D'; max_range = 10;  max_speed = 10;  sweeps = 32;
        case 8; mode = '3D'; max_range = 30;  max_speed = 30;  sweeps = 32;
    end
    samples = 128;
end