clc; clear; close all;

% Tham số mô phỏng
N = 5;              % Số nút trong mạng
T_sim = 1000;       % Tổng thời gian mô phỏng (đơn vị: slot)
slot_time = 0.00002; % Thời gian một slot (20us, giống IEEE 802.11)
IFS = 2;            % Interframe Space (số slot)
CW_min = 4;         % Kích thước cửa sổ tranh chấp tối thiểu
CW_max = 32;        % Kích thước cửa sổ tranh chấp tối đa
packet_duration = 50; % Thời gian truyền một gói tin (số slot)

% Khởi tạo trạng thái
channel_busy = zeros(1, T_sim); % Trạng thái kênh (0: rảnh, 1: bận)
backoff = zeros(1, N);          % Thời gian backoff của mỗi nút
transmitting = zeros(1, N);     % Trạng thái truyền (0: không truyền, 1: truyền)
success = 0;                    % Số gói tin truyền thành công
collisions = 0;                 % Số va chạm

% Vòng lặp mô phỏng
for t = 1:T_sim
    % Kiểm tra trạng thái kênh tại thời điểm t
    if sum(transmitting) > 0
        channel_busy(t) = 1; % Kênh bận nếu có nút đang truyền
    else
        channel_busy(t) = 0; % Kênh rảnh
    end
    
    for n = 1:N
        % Nếu nút không truyền, quyết định truyền
        if transmitting(n) == 0
            % Kiểm tra kênh rảnh trong IFS
            if t > IFS && all(channel_busy(t-IFS:t-1) == 0)
                % Giảm backoff nếu kênh rảnh
                if backoff(n) > 0
                    backoff(n) = backoff(n) - 1;
                end
                
                % Nếu backoff = 0, bắt đầu truyền
                if backoff(n) == 0
                    transmitting(n) = packet_duration; % Thời gian truyền gói tin
                    backoff(n) = randi([0, CW_min]);   % Reset backoff ngẫu nhiên
                end
            else
                % Nếu kênh bận, chọn backoff ngẫu nhiên
                if backoff(n) == 0
                    backoff(n) = randi([0, CW_min]);
                end
            end
        else
            % Đang truyền: giảm thời gian truyền còn lại
            transmitting(n) = transmitting(n) - 1;
        end
    end
    
    % Kiểm tra va chạm
    if sum(transmitting > 0) > 1
        collisions = collisions + 1; % Có va chạm nếu >1 nút truyền cùng lúc
    elseif sum(transmitting > 0) == 1
        if transmitting(find(transmitting > 0)) == 1 % Gói tin vừa truyền xong
            success = success + 1; % Thành công nếu chỉ 1 nút truyền
        end
    end
end

% Tính toán kết quả
throughput = success * packet_duration / T_sim; % Thông lượng (tỷ lệ slot thành công)
collision_prob = collisions / (success + collisions); % Xác suất va chạm

% Hiển thị kết quả
fprintf('Số gói tin thành công: %d\n', success);
fprintf('Số va chạm: %d\n', collisions);
fprintf('Thông lượng: %.4f\n', throughput);
fprintf('Xác suất va chạm: %.4f\n', collision_prob);

% Vẽ trạng thái kênh
figure;
plot(channel_busy, 'b-', 'LineWidth', 1.5);
xlabel('Thời gian (slot)');
ylabel('Trạng thái kênh (0: rảnh, 1: bận)');
title('Mô phỏng CSMA/CA');
grid on;
