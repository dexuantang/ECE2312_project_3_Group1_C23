clear;
%% Global variable declaration
FS = 44100;
FS_target = 22050;
nBits = 8;
nChannels = 1;
record_length = 7;                                                               %end
%% filter parameters, F is a vector of normalized frequencies
FLP0 = [0 0.272 0.363 1]; % F_pass = F_pass_target/FS, F_stop = F_stop_target/FS
ALP0 = [1 1 0 0];

%% Select audio devices
[user_selected_input_ID, user_slected_output_ID] = get_user_selected_device();


%% load audio
[audio_data_loaded_1,FS_loaded] = load_audio_from_wav();
plot_spectrogram(audio_data_loaded_1, FS_loaded, 15, "Spectrogram of original audio");

%% 3 pass the above audio through a LPF and downsampler
filtered_audio = my_filter(FLP0, ALP0, audio_data_loaded_1);
plot_spectrogram(filtered_audio, FS_loaded, 15, "Spectrogram of LPF output audio");

downsampled_audio = my_downsample(FS_loaded, FS_target, filtered_audio);
plot_spectrogram(downsampled_audio, FS_target, 8, "Spectrogram of downsampled audio");

%% 4 first frequency decomposition




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

%% LPF using firls
function filtered = my_filter(F,A,audio)
    lpf = firls(255, F, A);                                                    %255 order
    filtered = filter(lpf, A, audio);
end

%% Downsample
function downsampled = my_downsample(FS, target_FS, audio)
    R = round(FS/target_FS);
    downsampled = downsample(audio, R);

end


%% A function that plots the spectrogram of a given audio data
function plot_spectrogram(audio_data, FS, fmax, my_title)
    figure;
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

function sound_blocking(audio, FS, audio_length)
    sound(audio, FS);
    pause(audio_length)
end
