clear;
close all;
%% Global variable declaration
FS = 44100;
FS_target = 16000;
nBits = 8;
nChannels = 1;
record_length = 7;
%% filter parameters, F is a vector of normalized frequencies
FLP0P = 7800;
FLP0S = 8000;
FLP0 = [0 (2*FLP0P)/FS (2*FLP0S)/FS 1];
ALP0 = [1 1 0 0];

%% Select audio devices
[user_selected_input_ID, user_slected_output_ID] = get_user_selected_device();

%% load audio
[audio_data_loaded_1,FS_loaded] = load_audio_from_wav();
figure;
plot_spectrogram(audio_data_loaded_1, FS_loaded, 15, "Spectrogram of original audio");

%% 3 pass the above audio through a LPF and downsampler, downsample to nyquist frequency of LPF
filtered_audio = my_filter(FLP0, ALP0, audio_data_loaded_1);
figure;
plot_spectrogram(filtered_audio, FS_loaded, 15, "Spectrogram of LPF output audio");

downsampled_audio = my_downsample(FS_loaded, FS_target, filtered_audio);
figure;
plot_spectrogram(downsampled_audio, FS_target, 8, "Spectrogram of downsampled audio");

%% 4 first frequency decomposition
% filter parameters
F1P = 3800;
F1S = 4000;
FLP1 = [0 (2*F1P)/FS_target (2*F1S)/FS_target 1]; 
ALP1 = [1 1 0 0];
FHP1 = [0 (2*F1P)/FS_target (2*F1S)/FS_target 1]; 
AHP1 = [0 0 1 1];
% pass through lpf and hpf, both filters have the same cut-off frequency
LP1 = my_filter(FLP1, ALP1, downsampled_audio);
HP1 = my_filter(FHP1, AHP1, downsampled_audio);
% downsample again
FSD1 = FS_target/2;
DS1A = my_downsample(FS_target, FSD1, LP1);
DS1B = my_downsample(FS_target, FSD1, HP1);
%plotting
figure;
subplot(2,1,1);
plot_spectrogram(DS1B, FSD1, 4, "X_H");
subplot(2,1,2);
plot_spectrogram(DS1A, FSD1, 4, "X_L");

%% 5 second frequency decomposition
% filter parameters
F2P = 1800;
F2S = 2000;
FLP2 = [0 (2*F2P)/FSD1 (2*F2S)/FSD1 1]; 
ALP2 = [1 1 0 0];
FHP2 = [0 (2*F2P)/FSD1 (2*F2S)/FSD1 1]; 
AHP2 = [0 0 1 1];
% pass the lower and upper half through lpf and hpf, resulting in 4 signals
LP2A = my_filter(FLP2, ALP2, DS1A);
LP2B = my_filter(FLP2, ALP2, DS1B);
HP2A = my_filter(FHP2, AHP2, DS1A);
HP2B = my_filter(FHP2, AHP2, DS1B);
% downsample again
FSD2 = FSD1/2;
DSHP2B = my_downsample(FSD1, FSD2, HP2B);
DSLP2B  = my_downsample(FSD1, FSD2, LP2B);
DSHP2A  = my_downsample(FSD1, FSD2, HP2A);
DSLP2A  = my_downsample(FSD1, FSD2, LP2A);
% plotting
figure;
subplot(4,1,1);
plot_spectrogram(DSHP2B, FSD2, 2, "X_H_H");
subplot(4,1,2);
plot_spectrogram(DSLP2B, FSD2, 2, "X_H_L");
subplot(4,1,3);
plot_spectrogram(DSHP2A, FSD2, 2, "X_L_H");
subplot(4,1,4);
plot_spectrogram(DSLP2A, FSD2, 2, "X_L_L");

%% 6 reassembling the signal 
% first upsample
RHP2B = upsample(DSHP2B, 2);
RLP2B = upsample(DSLP2B, 2);
RHP2A = upsample(DSHP2A, 2);
RLP2A = upsample(DSLP2A, 2);
RFS1 = 2* FSD2;                                   %new sample rate
% assemble signals using the same set of filters
R2B = my_filter(FHP2, AHP2, RHP2B) + my_filter(FLP2, ALP2, RLP2B);
R2A = my_filter(FHP2, AHP2, RHP2A) + my_filter(FLP2, ALP2, RLP2A);
% second upsample
R1A = upsample(R2A, 2);
R1B = upsample(R2B, 2);
reconstructed = my_filter(FLP1, ALP1, R1A) + my_filter(FHP1, AHP1, R1B);
RFS = 2* RFS1;                                   %new restored sample rate
% plotting
figure;
plot_spectrogram(reconstructed, RFS, 8, "Reassembled audio signal");
sound_blocking(reconstructed, RFS, record_length);
save_audio_to_wav(reconstructed, RFS);

%% Functions:
%% A function that lets the user select their audio device by typing them in the command window
function [input_device_ID, output_device_ID] = get_user_selected_device()
    devices = audiodevinfo;                                                    %get all devices
    input_devices = struct2table(devices.input, 'AsArray', true);              %put them in printable formats
    output_devices = struct2table(devices.output, 'AsArray', true);
    disp ('list of input devices')
    disp(input_devices)                                                        %print out all input devices
    input_device_ID = input ('please select input device by typing its ID');   %get user input
    disp ('list of output devices')
    disp(output_devices)                                                       %print out all output devices
    output_device_ID = input ('please select output device by typing its ID'); %get user input
end

%% LPF or HPF using firls
function filtered = my_filter(F,A,audio)
    f = firls(500, F, A);                                                    %256th order
    filtered = filter(f, 1, audio);
end

%% Downsample given sample speed and target sample speed
function downsampled = my_downsample(FS, target_FS, audio)
    R = round(FS/target_FS);
    downsampled = downsample(audio, R);
end


%% A function that plots the spectrogram of a given audio data
function plot_spectrogram(audio_data, FS, fmax, my_title)
    window = hamming(512);                                                     %set parameters
    N_overlap = 256;
    N_fft = 1024;
    spectrogram(audio_data, window, N_overlap, N_fft, FS, 'yaxis');            %plot it
    ylim([0 fmax]);                                                               %limit to 8kHz
    title(my_title);                                                           %add custom title
end

%% A fucntion that saves audio as a WAV file with GUI
function save_audio_to_wav(audio_data, FS)
    disp("Please save the audio")
    [filename, pathname] = uiputfile('*.wav', 'Save recorded audio as');      %get file and path
    savepath = fullfile(pathname, filename);                                  %combine to get full path
    audiowrite(savepath, audio_data, FS);                                     %save with specified sample rate
    disp("done saving")
end

%% A fucntion that loads WAV audio with GUI
function [y,FS] = load_audio_from_wav()
    disp("Please open an audio clip")
    [filename, pathname] = uigetfile('*.wav');                                %get file and path
    loadpath = fullfile(pathname, filename);                                  %get full path
    [y,FS] = audioread(loadpath);                                             %read audio data and sample rate 
    disp("done loading")
end

%% Play sound and pause script execution
function sound_blocking(audio, FS, audio_length)
    sound(audio, FS);
    pause(audio_length)
end


