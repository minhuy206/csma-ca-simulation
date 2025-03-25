% Mô phỏng CSMA/CA với phân tích hiệu suất chi tiết
clear all;
close all;

% Tham số mô phỏng
nStations = 5;          % Số node/station
simTime = 2000;        % Thời gian mô phỏng (timeslots)
backoffMax = 16;       % Giá trị backoff tối đa
dataSize = 10;         % Kích thước gói tin
ACK = 2;              % Thời gian ACK
probTx = 0.3;          % Xác suất tạo gói tin

% Khởi tạo biến
channel = zeros(1, simTime);
stationState = zeros(nStations, simTime);
successfulTx = zeros(1, nStations);
collisions = 0;
delay = zeros(1, nStations);    % Tổng độ trễ
packetsSent = zeros(1, nStations); % Số gói tin gửi
waitingTime = cell(1, nStations); % Lưu thời gian chờ của mỗi gói

% Main simulation loop
for t = 1:simTime
    for n = 1:nStations
        if rand() < probTx && stationState(n,t) == 0
            % Carrier sensing
            if t > 1 && channel(t-1) == 0
                backoff = randi([0 backoffMax]);
                if t + backoff + dataSize + ACK <= simTime
                    % Ghi nhận thời gian bắt đầu chờ
                    startTime = t;
                    
                    % Backoff
                    if backoff > 0
                        stationState(n,t:t+backoff-1) = 1;
                    end
                    
                    % Kiểm tra va chạm
                    collision = false;
                    txStart = t + backoff;
                    txEnd = txStart + dataSize - 1;
                    if sum(channel(txStart:txEnd)) > 0
                        collision = true;
                        collisions = collisions + 1;
                        stationState(n,txStart:txEnd) = 4; % Trạng thái va chạm
                    end
                    
                    % Truyền thành công
                    if ~collision
                        channel(txStart:txEnd) = 1;
                        stationState(n,txStart:txEnd) = 2;
                        channel(txEnd+1:txEnd+ACK) = 1;
                        stationState(n,txEnd+1:txEnd+ACK) = 3;
                        successfulTx(n) = successfulTx(n) + 1;
                        packetsSent(n) = packetsSent(n) + 1;
                        totalDelay = (txEnd + ACK - startTime);
                        delay(n) = delay(n) + totalDelay;
                        waitingTime{n} = [waitingTime{n} totalDelay];
                    end
                end
            end
        end
    end
end

% Phân tích hiệu suất
channelUtilization = sum(channel) / simTime * 100;
totalCollisions = collisions;
collisionRate = collisions / sum(packetsSent) * 100;
throughput = sum(successfulTx) * dataSize / simTime;
avgDelay = delay ./ successfulTx; % Độ trễ trung bình mỗi station
fairness = std(successfulTx) / mean(successfulTx); % Chỉ số công bằng

% Hiển thị kết quả
fprintf('PHÂN TÍCH HIỆU SUẤT:\n');
fprintf('1. Tỷ lệ sử dụng kênh: %.2f%%\n', channelUtilization);
fprintf('2. Tổng số va chạm: %d\n', totalCollisions);
fprintf('3. Tỷ lệ va chạm: %.2f%%\n', collisionRate);
fprintf('4. Throughput mạng: %.2f (data units/timeslot)\n', throughput);
fprintf('5. Độ trễ trung bình theo station (timeslots):\n');
for n = 1:nStations
    if successfulTx(n) > 0
        fprintf('   Station %d: %.2f\n', n, avgDelay(n));
    else
        fprintf('   Station %d: N/A (không có truyền thành công)\n', n);
    end
end
fprintf('6. Chỉ số công bằng: %.2f (0: rất công bằng, cao: không công bằng)\n', fairness);
fprintf('7. Số lần truyền thành công theo station:\n');
for n = 1:nStations
    fprintf('   Station %d: %d\n', n, successfulTx(n));
end

% Chuẩn bị nhãn cho boxplot
groupLabels = [];
dataToPlot = [];
for n = 1:nStations
    if ~isempty(waitingTime{n})
        dataToPlot = [dataToPlot waitingTime{n}];
        groupLabels = [groupLabels repmat(n, 1, length(waitingTime{n}))];
    end
end

% Vẽ biểu đồ
figure('Position', [100 100 1000 800]);

subplot(3,2,1);
plot(channel);
title('Trạng thái kênh');
xlabel('Time slots');
ylabel('Channel State');

subplot(3,2,2);
imagesc(stationState);
title('Trạng thái các Station');
xlabel('Time slots');
ylabel('Station ID');
colorbar;
colormap([1 1 1; 0 1 0; 0 0 1; 1 0 0; 1 0 1]); % Màu trắng: channel rảnh, màu xanh: đợi backoff, màu xanh dương: Tx, màu đỏ: đợi ACK, màu tím: va chạm

subplot(3,2,3);
bar(successfulTx);
title('Số lần truyền thành công');
xlabel('Station ID');
ylabel('Số gói tin');

subplot(3,2,4);
bar(avgDelay);
title('Độ trễ trung bình');
xlabel('Station ID');
ylabel('Timeslots');

subplot(3,2,5);
pie([sum(channel) simTime-sum(channel)]);
title('Sử dụng kênh');
legend({'Busy', 'Idle'});
