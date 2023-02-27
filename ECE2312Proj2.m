clear;
%% Global variable declaration
FS = 44100;
nBits = 8;
nChannels = 1;
record_length = 7;
%% chirp fquencies
FI = 0;                                                                      %start
FF = 8000;                                                                   %end
%% filter parameters, F is a vector of are normalized frequencies
F = [0 0.18 0.18001 1];
A = [1 1 0 0];

%% Select audio devices
[user_selected_input_ID, user_slected_output_ID] = get_user_selected_device();

%% 2 generate, save and plot the 5000Hz sine
sine = sinewave(record_length, 5000, FS);
sound_blocking(sine, FS, record_length);
disp('please save the sine wave')
save_audio_to_wav(sine, FS);
plot_spectrogram(sine, FS, "Spectrogram of 5000Hz sine");

%% 3 generate and plot 0 to 8000Hz chirp
chirp = sine_chirp(record_length, FI, FF, FS);
sound_blocking(chirp, FS, record_length);
disp('please save the chirp')
save_audio_to_wav(chirp, FS);
plot_spectrogram(chirp, FS, "Spectrogram of chirp");


%% 4 generate, save, and plot cetk sounds
cetk_sound = cetk(record_length, FS);
sound_blocking(cetk_sound, FS, record_length);
disp('please save the cetk sound')
save_audio_to_wav(cetk_sound, FS);
plot_spectrogram(cetk_sound, FS, "Spectrogram of cetk");


%% 5 load fox
[audio_data_loaded_1,FS_loaded] = load_audio_from_wav();

%% 6 add sine wave to loaded data, save file, and plot
sine_added = add_sine(audio_data_loaded_1, sine');
sound_blocking(sine_added, FS, record_length);
disp('please save the audio with sine added to it')
save_audio_to_wav(sine_added, FS);
plot_spectrogram(sine_added, FS_loaded, "Spectrogram of sine added to brown fox");

%% 7 pass the above audio through a LPF
filtered_audio = LPF(F, A, sine_added);
sound_blocking(filtered_audio, FS, record_length);
disp('please save the sine wave')
save_audio_to_wav(filtered_audio, FS);
plot_spectrogram(filtered_audio, FS_loaded, "Spectrogram of LPF output audio");

%% 8 stereo audio
stereo = mono2stereo(audio_data_loaded_1, sine_added);
sound_blocking(stereo, FS, record_length);
disp('please save the stereo audio')
save_audio_to_wav(stereo, FS);
plot_spectrogram(stereo(:,1), FS, "Spectrogram of stereo left channel");
plot_spectrogram(stereo(:,2), FS, "Spectrogram of stereo right channel");



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

%% function that generates chirp
function [chirp] = sine_chirp(record_length, FI, FF, FS)
    chirp = zeros;
    n = 0:(1/FS):(record_length);
    f = linspace (FI, FF, length(n));   
    for i = 1:length(n)
        chirp(i) = sin(pi*f(i)*n(i));
    end
end

%% function that makes constant frequence sine
function [output] = sinewave(record_length, F, FS)
    n = 0:(1/FS):(record_length);
    output = sin(2*pi*n*F);
end

%% function that makes alien sounds
function [cetk] = cetk(record_length, FS)
    %% initiate variables
    cetk = zeros;
    note_durations = [0.5 0.7 1 0.7 3];
    n = 0:(1/FS):(record_length);
    f = zeros;
    %% note defination(D6, E6, C6, C5, G5)
    f(1:(FS*note_durations(1))) = 2349.32;
    f((1+FS*note_durations(1)):...
        (FS*note_durations(2)+ FS*note_durations(1))) = 2637.02;
    f((1+FS*(note_durations(1)+note_durations(2))):FS*...
        (note_durations(1)+note_durations(2)+note_durations(3))) = 2093;
    f((1+FS*(note_durations(1)+note_durations(2)+note_durations(3))):FS*...
        (note_durations(1)+note_durations(2)+...
        note_durations(3)+note_durations(4))) = 1046.5;
    f((1+FS*(note_durations(1)+note_durations(2)+note_durations(3)+note_durations(4))):FS*...
        (note_durations(1)+note_durations(2)+...
        note_durations(3)+note_durations(4)+note_durations(5))) = 1567.98;
    %% Variable frequency sine
    for i = 1:length(f)
        cetk(i) = sin(pi*f(i)*n(i));
    end
end

%% function that adds two signals together elementwise
function [sine_added] = add_sine(voice, sine)
    %% chop the signal incase they are different length
    if length(voice) > length(sine)
        voice = voice(1:length(sine));
    elseif length(voice) < length(sine)
        sine = sine(1:length(voice));
    end
    voice = voice(1:length(sine));
    sine_added = voice + sine;
end

%% LPF using firls
function filtered = LPF(F,A,audio)
    lpf = firls(255, F, A);                                                    %255 order
    filtered = filter(lpf, A, audio);
end


%% A function that plots the spectrogram of a given audio data
function plot_spectrogram(audio_data, FS, my_title)
    figure;
    window = hamming(512);                                                     %set parameters
    N_overlap = 256;
    N_fft = 1024;
    spectrogram(audio_data, window, N_overlap, N_fft, FS, 'yaxis');            %plot it
    ylim([0 8]);                                                               %limit to 8kHz
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
%% A function that converts the mono audio to stereo by stacking two mono audios
function audio_data_stereo =  mono2stereo(ch1, ch2)
    if length(ch1) > length(ch2)
        ch1 = ch1(1:length(ch2));
    elseif length(ch1) < length(ch2)
        ch2 = ch2(1:length(ch1));
    end
    audio_data_stereo(:, 1) = ch1;
    audio_data_stereo(:, 2) = ch2;
end
