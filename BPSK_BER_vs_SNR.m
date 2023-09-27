
%% A simple MATLAB code for Underwater VLC
% When using this code cite:
% "H. Rajahrajasingh and S. Edirisinghe, "The Feasibility of Visible Light Communication for Deep Sea Communication," 2023 IEEE 17th International Conference on Industrial and Information Systems (ICIIS), Peradeniya, Sri Lanka, 2023, pp. 152-157, doi: 10.1109/ICIIS58898.2023.10253505."

% Code uses BPSK modulation scheme and Gamma-Gamma turbulence model
% Change alpha and beta value as per need


clc;
clear all;

% Parameters
SNR_dB_min = 0;          % Minimum SNR in dB
SNR_dB_max = 60;         % Maximum SNR in dB
num_points = 30;          % Number of SNR points
num_runs = 10;           % Number of runs for averaging
num_bits = 1000000;        % Number of bits to transmit
EbN0_dB = linspace(SNR_dB_min, SNR_dB_max, num_points); % SNR points in dB

% Shape and scale parameters for gamma-gamma distribution
alpha = 4.2;   % Shape parameter
beta = 1.4;    % Scale parameter

Refractive_Index =1.5; % Refractive Index of the Lens
FOV_PD =70; % Field of View of the Photodiode
Concentrator_Gain =( Refractive_Index ^2) /(sind(FOV_PD).^2) ; % Gain of the optical concentrator

C = 0.056;  % extinction coefficient for pure sea water
% C = 0.15;  % extinction coefficient for clear ocean water
% C = 0.305;  % extinction coefficient for coastal ocean water

No_LED =10; % Total nummber of LEDs
Power_LED =1; % Transmitted Power of the LED
Pt = Power_LED*No_LED;

d = 10;  % Distance between transmitter and receiver (m)
theta =70; % Semi angle of the LED at half power illumination
m = - log10 (2) / log10 ( cosd ( theta )); % Lamberts Mode Number
Adet = 0.05; % Area of the Photodiode
phi = 40;     % Irradiance angle (assumed to be normal incidence)

% Convert SNR from dB to linear scale
SNR = 10.^(EbN0_dB / 10);

% Initialize the BER array
ber = zeros(1, num_points);

for i = 1:num_points
    % Simulation for each SNR point
    errors = 0;
    
    for j = 1:num_runs
        % Generate random bits
        tx_bits = randi([0, 1], 1, num_bits);
        
        % Generate gamma-gamma channel gain
        %Hturb = gamrnd(alpha,beta);
        Hturb = random('Gamma', alpha, 1/beta, 1, num_bits);
        Ha = exp(-C*d);
        Hg = ((m+1)*Adet*cosd(phi)^m./(2*pi*d^2))*Concentrator_Gain;
        
        H = Hg*Hturb*Ha;
        
        tx_symbols = 2*tx_bits-1;

        % Add complex AWGN noise
        noise = (1 / sqrt(2 * SNR(i))) * (randn(1, num_bits) + 1i * randn(1, num_bits));
        H2 = sqrt(H); % Channel gain
        
        rx_symbols = sqrt(Pt)*H2 .* tx_symbols + noise;

        % Equalization (Zero-Force Equalization)
        equalized_signal = rx_symbols ./ H2;

        % Demodulate the equalized signal (threshold at 0.5)
        rx_bits = real(equalized_signal) > 0.5;

        % Count errors
        errors = errors + sum(tx_bits ~= rx_bits);
    end

    % Calculate BER for the current SNR point
    ber(i) = errors / (num_bits*num_runs);
end

% Plot the results
figure;
semilogy(EbN0_dB, ber, 'o-', 'LineWidth', 2);
grid on;
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('BER vs. SNR');
xlim([SNR_dB_min, SNR_dB_max]);
ylim([1e-4, 1]);
