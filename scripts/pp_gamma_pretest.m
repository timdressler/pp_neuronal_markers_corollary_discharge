% pp_gamma_pretest.m
%
% Pretest to identify the presence (or non-presence) of gamma activity. 
% Using pre-processed data.
% ICA preprocessing done by Suong Welp. Further Preprocessing done in this script.
% All Conditions merged.
% Only for one subject. 125 and 136 chosen for preliminary analysis.
%
% Tim Dressler, 12.08.2024

clear
close all
clc

%setup paths
SCRIPTPATH = cd;
%check if correct path is openend
if regexp(SCRIPTPATH, regexptranslate('wildcard','*neucodis\scripts')) == 1
    disp('Path OK')
else
    error('Path not OK')
end
MAINPATH = erase(SCRIPTPATH, 'neucodis\scripts');
INPATH = fullfile(MAINPATH, 'data\proc_data\pp_data_gamma_pretest_proc\'); %place 'data' folder in the same folder as the 'neucodis' folder %don't change names
OUTPATH = fullfile(MAINPATH, 'data\analysis_data\'); %place 'data' folder in the same folder as the 'neucodis' folder %don't change names
FUNPATH = fullfile(MAINPATH, 'neucodis\functions\');
addpath(FUNPATH);

%variables to edit
SUBJ = '136'; %122, 125 or 127 (500Hz); 132, 134 and 136 (1000Hz downsampled to 500Hz)
CHAN = 'Cz';
EVENTS = {'S 1', 'S 2', 'S 3', 'S 4', 'S 5'};
EPO_FROM = -0.4;
EPO_TILL = 0.6;
LCF = 5;
HCF = 60;
BL_FROM = -400;
BL_TILL= -200;
TF_FROM = -400;
TF_TILL = 500;
TF_BL_FROM = -200;
TF_BL_TILL = -100;
THRESH = 50;
SD_PROB = 2.5;

%start eeglab & load data
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
load(fullfile(INPATH, ['Prep3_P' SUBJ '_ICA_rejected.mat']));
%get channel ID
chani = find(strcmp({EEG.chanlocs.labels}, CHAN));
%remove not needed channel
EEG = pop_select( EEG, 'rmchannel',{'Lip'});
%automatic ICA rejection
EEG = pop_iclabel(EEG, 'default');
EEG = pop_icflag(EEG, [0 0.2;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1]);
EEG = pop_subcomp( EEG, [], 0);
%filter
EEG = pop_eegfiltnew(EEG, 'locutoff',LCF);
EEG = pop_eegfiltnew(EEG, 'hicutoff',HCF);
%epoch
EEG = pop_epoch( EEG, EVENTS, [EPO_FROM          EPO_TILL], 'newname', ['P' SUBJ '_ICA_rejected epochs'], 'epochinfo', 'yes');
%baseline
EEG = pop_rmbase( EEG, [BL_FROM BL_TILL] ,[]);
%treshhold & probability
EEG = pop_eegthresh(EEG,1,[1:EEG.nbchan] ,-THRESH,THRESH,-0.2,0.798,2,0);
EEG = pop_jointprob(EEG,1,[1:EEG.nbchan] ,SD_PROB,0,0,0,[],0);
EEG = pop_rejkurt(EEG,1,[1:EEG.nbchan] ,SD_PROB,0,0,0,[],0);
EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
EEG = pop_rejepoch( EEG, EEG.reject.rejglobal ,0);
%ERSP (Wavelet)
figure; pop_newtimef( EEG, 1, chani, [TF_FROM  TF_TILL], [3         0.8] , 'topovec', chani, ...
    'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', CHAN, 'baseline',[TF_BL_FROM TF_BL_TILL], ...
    'plotphase', 'off', 'scale', 'abs', 'padratio', 1, 'winsize', 200);
%TF-topoplots
for elec = 1:EEG.nbchan
    [ersp,itc,powbase,times,freqs,erspboot,itcboot] = pop_newtimef(EEG, ...
    1, elec, [EEG.xmin EEG.xmax]*1000, [3 0.5], 'maxfreq', 60, 'padratio', 16, ...
    'plotphase', 'off', 'timesout', 60, 'alpha', .05, 'plotersp','off', 'plotitc','off');
    %create empty arrays if first electrode
    if elec == 1  
        allersp = zeros([ size(ersp) EEG.nbchan]);
        allitc = zeros([ size(itc) EEG.nbchan]);
        allpowbase = zeros([ size(powbase) EEG.nbchan]);
        alltimes = zeros([ size(times) EEG.nbchan]);
        allfreqs = zeros([ size(freqs) EEG.nbchan]);
        allerspboot = zeros([ size(erspboot) EEG.nbchan]);
        allitcboot = zeros([ size(itcboot) EEG.nbchan]);
    end
    allersp (:,:,elec) = ersp;
    allitc (:,:,elec) = itc;
    allpowbase (:,:,elec) = powbase;
    alltimes (:,:,elec) = times;
    allfreqs (:,:,elec) = freqs;
    allerspboot (:,:,elec) = erspboot;
    allitcboot (:,:,elec) = itcboot;
end
%topoplot
figure;
tftopo(allersp,alltimes(:,:,1),allfreqs(:,:,1), ...
    'timefreqs', [58 36; 70 48; 70 38; 60 43], 'chanlocs', EEG.chanlocs, 'showchan', chani)

%display sanity check variables
check_done = 'OK'
